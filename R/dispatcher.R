# mirai ------------------------------------------------------------------------

#' Dispatcher
#'
#' Dispatches tasks from a host to daemons for processing, using FIFO
#' scheduling, queuing tasks as required. Daemon / dispatcher settings are
#' controlled by [daemons()] and this function should not need to be called
#' directly.
#'
#' The network topology is such that a dispatcher acts as a gateway between the
#' host and daemons, ensuring that tasks received from the host are dispatched
#' on a FIFO basis for processing. Tasks are queued at the dispatcher to ensure
#' tasks are only sent to daemons that can begin immediate execution of the
#' task.
#'
#' @inheritParams daemons
#' @param host the character URL dispatcher should dial in to, typically an IPC
#'   address.
#' @param url (optional) the character URL dispatcher should listen at (and
#'   daemons should dial in to), including the port to connect to e.g.
#'   'tcp://hostname:5555' or 'tcp://10.75.32.70:5555'. Specify 'tls+tcp://' to
#'   use secure TLS connections.
#' @param n (optional) if specified, the integer number of daemons to launch. In
#'   this case, a local url is automatically generated.
#'
#' @return Invisible NULL.
#'
#' @export
#'
dispatcher <- function(host, url = NULL, n = NULL, ...) {
  n <- if (is.numeric(n)) as.integer(n) else length(url)
  n > 0L || stop(._[["missing_url"]])

  cv <- cv()
  sock <- socket("rep")
  on.exit(reap(sock))
  pipe_notify(sock, cv, remove = TRUE, flag = flag_value())
  dial_sync_socket(sock, host)

  raio <- recv_aio(sock, mode = 1L, cv = cv)
  wait(cv) || return()
  res <- collect_aio(raio)
  if (nzchar(res[[1L]])) {
    Sys.setenv(R_DEFAULT_PACKAGES = res[[1L]])
  } else {
    Sys.unsetenv("R_DEFAULT_PACKAGES")
  }

  tls <- NULL
  auto <- is.null(url)
  if (auto) {
    url <- local_url()
  } else {
    if (is.character(res[[2L]])) {
      tls <- res[[2L]]
      pass <- res[[3L]]
    }
    if (length(tls)) tls <- tls_config(server = tls, pass = pass)
  }
  pass <- NULL
  serial <- res[[4L]]
  res <- res[[5L]]

  psock <- socket("poly")
  on.exit(reap(psock), add = TRUE, after = TRUE)
  m <- monitor(psock, cv)
  listen(psock, url = url, tls = tls, fail = 2L)

  inq <- outq <- list()
  events <- integer()
  count <- 0L
  envir <- new.env(hash = FALSE, parent = emptyenv())
  `[[<-`(envir, "stream", res)
  if (auto) {
    dots <- parse_dots(...)
    for (i in seq_len(n)) {
      launch_daemon(args_daemon_disp(url, dots))
    }
    for (i in seq_len(n))
      while(!until(cv, .limit_long))
        cv_signal(cv) || wait(cv) || return()

    changes <- read_monitor(m)
    for (item in changes) {
      item > 0 && {
        outq[[as.character(item)]] <- `[[<-`(`[[<-`(`[[<-`(`[[<-`(new.env(parent = emptyenv()), "pipe", item), "msgid", 0L), "ctx", NULL), "sync", FALSE)
        send(psock, list(next_stream(envir), serial), mode = 1L, block = TRUE, pipe = item)
      }
    }
  } else {
    listener <- attr(psock, "listener")[[1L]]
    url <- opt(listener, "url")
    if (parse_url(url)[["port"]] == "0") {
      url <- sub_real_port(opt(listener, "tcp-bound-port"), url)
    }
  }

  send(sock, c(Sys.getpid(), url), mode = 2L, block = TRUE)

  ctx <- .context(sock)
  req <- recv_aio(ctx, mode = 8L, cv = cv)
  res <- recv_aio(psock, mode = 8L, cv = cv)

  suspendInterrupts(
    while (wait(cv)) {

      changes <- read_monitor(m)
      is.null(changes) || {
        for (item in changes) {
          if (item > 0) {
            outq[[as.character(item)]] <- `[[<-`(`[[<-`(`[[<-`(`[[<-`(new.env(parent = emptyenv()), "pipe", item), "msgid", 0L), "ctx", NULL), "sync", FALSE)
            send(psock, list(next_stream(envir), serial), mode = 1L, block = TRUE, pipe = item)
            cv_signal(cv)
          } else {
            id <- as.character(-item)
            if (length(outq[[id]])) {
              outq[[id]][["msgid"]] && send(outq[[id]][["ctx"]], .connectionReset, mode = 1L, block = TRUE)
              if (length(outq[[id]][["dmnid"]])) {
                events <- c(events, outq[[id]][["dmnid"]])
              }
              outq[[id]] <- NULL
            }
          }
        }
        next
      }

      if (!unresolved(req)) {
        value <- .subset2(req, "value")

        if (value[1L] == 0L) {
          id <- readBin(value, integer(), n = 2L)[2L]
          if (id == 0L) {
            found <- c(
              length(outq),
              length(inq),
              sum(as.logical(unlist(lapply(outq, .subset2, "msgid"), use.names = FALSE))),
              count,
              events
            )
            events <- integer()
          } else {
            found <- FALSE
            for (item in outq) {
              item[["msgid"]] == id && {
                send(psock, 0L, mode = 1L, pipe = item[["pipe"]], block = TRUE)
                `[[<-`(item, "msgid", -1L)
                found <- TRUE
                break
              }
            }
            if (!found) {
              for (i in seq_along(inq)) {
                inq[[i]][["msgid"]] == id && {
                  inq[[i]] <- NULL
                  found <- TRUE
                  break
                }
              }
            }
          }
          send(ctx, found, mode = 2L, block = TRUE)
        } else {
          count <- count + 1L
          msgid <- .read_header(value)
          inq[[length(inq) + 1L]] <- list(ctx = ctx, req = value, msgid = msgid)
        }
        ctx <- .context(sock)
        req <- recv_aio(ctx, mode = 8L, cv = cv)

      } else if (!unresolved(res)) {
        value <- .subset2(res, "value")
        id <- as.character(pipe_id(res))
        res <- recv_aio(psock, mode = 8L, cv = cv)
        outq[[id]][["msgid"]] < 0 && {
          `[[<-`(outq[[id]], "msgid", 0L)
          cv_signal(cv)
          next
        }
        .read_marker(value) && {
            send(outq[[id]][["ctx"]], value, mode = 2L, block = TRUE)
            send(psock, 0L, mode = 2L, pipe = outq[[id]][["pipe"]], block = TRUE)
            if (length(outq[[id]][["dmnid"]])) {
              events <- c(events, outq[[id]][["dmnid"]])
            }
            outq[[id]] <- NULL
          next
        }
        as.logical(value[1L]) || {
          dmnid <- readBin(value, integer(), n = 2L)[2L]
          events <- c(events, dmnid)
          `[[<-`(outq[[id]], "dmnid", -dmnid)
          next
        }
        send(outq[[id]][["ctx"]], value, mode = 2L, block = TRUE)
        `[[<-`(outq[[id]], "msgid", 0L)
      }

      if (length(inq)) {
        for (item in outq) {
          item[["msgid"]] || {
            if (.read_marker(inq[[1L]][["req"]])) {
              item[["sync"]] && next
              `[[<-`(item, "sync", TRUE)
            } else if (item[["sync"]]) {
              lapply(outq, `[[<-`, "sync", FALSE)
            }
            send(psock, inq[[1L]][["req"]], mode = 2L, pipe = item[["pipe"]], block = TRUE)
            `[[<-`(item, "ctx", inq[[1L]][["ctx"]])
            `[[<-`(item, "msgid", inq[[1L]][["msgid"]])
            inq[[1L]] <- NULL
            break
          }
        }
      }
    }
  )
}
