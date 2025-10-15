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
#' @param url the character URL dispatcher should listen at (and daemons should
#'   dial in to), including the port to connect to e.g. tcp://hostname:5555' or
#'   'tcp://10.75.32.70:5555'. Specify 'tls+tcp://' to use secure TLS
#'   connections.
#' @param n if specified, the integer number of daemons to be launched locally
#'   by the host process.
#'
#' @return Invisible NULL.
#'
#' @export
#'
dispatcher <- function(host, url = NULL, n = 0L, ...) {
  cv <- cv()
  sock <- socket("rep")
  on.exit(reap(sock))
  pipe_notify(sock, cv, remove = TRUE, flag = flag_value())

  psock <- socket("poly")
  on.exit(reap(psock), add = TRUE, after = TRUE)
  m <- monitor(psock, cv)
  n && listen(psock, url = url, fail = 2L)

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
  if (!n) {
    if (is.character(res[[2L]])) {
      tls <- res[[2L]]
      pass <- res[[3L]]
    }
    if (length(tls)) tls <- tls_config(server = tls, pass = pass)
  }
  pass <- NULL
  serial <- res[[4L]]
  res <- res[[5L]]

  inq <- outq <- list()
  connections <- count <- 0L
  envir <- new.env(hash = FALSE, parent = emptyenv())
  `[[<-`(envir, "stream", res)

  if (n) {
    for (i in seq_len(n))
      while (!until(cv, .limit_long))
        cv_signal(cv) || wait(cv) || return()

    changes <- read_monitor(m)
    for (item in changes) {
      item > 0 && {
        connections <- connections + 1L
        outq[[as.character(item)]] <- `[[<-`(`[[<-`(`[[<-`(`[[<-`(new.env(parent = emptyenv()), "pipe", item), "msgid", 0L), "ctx", NULL), "sync", FALSE)
        send(psock, list(next_stream(envir), serial), mode = 1L, block = TRUE, pipe = item)
      }
    }
  } else {
    listen(psock, url = url, tls = tls, fail = 2L)
    url <- sub_real_port(psock, url)
  }
  send(sock, url, mode = 2L, block = TRUE)

  ctx <- .context(sock)
  req <- recv_aio(ctx, mode = 8L, cv = cv)
  res <- recv_aio(psock, mode = 8L, cv = cv)

  suspendInterrupts(
    while (wait(cv)) {

      changes <- read_monitor(m)
      is.null(changes) || {
        for (item in changes) {
          if (item > 0) {
            connections <- connections + 1L
            outq[[as.character(item)]] <- `[[<-`(`[[<-`(`[[<-`(`[[<-`(new.env(parent = emptyenv()), "pipe", item), "msgid", 0L), "ctx", NULL), "sync", FALSE)
            send(psock, list(next_stream(envir), serial), mode = 1L, block = TRUE, pipe = item)
            cv_signal(cv)
          } else {
            id <- as.character(-item)
            if (length(outq[[id]])) {
              outq[[id]][["msgid"]] && send(outq[[id]][["ctx"]], .connectionReset, mode = 1L, block = TRUE)
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
            awaiting <- length(inq)
            executing <- sum(as.logical(unlist(lapply(outq, .subset2, "msgid"), use.names = FALSE)))
            found <- c(
              length(outq),
              connections,
              awaiting,
              executing,
              count - awaiting - executing
            )
          } else {
            found <- FALSE
            for (item in outq) {
              item[["msgid"]] == id && {
                send(psock, 0L, mode = 1L, pipe = item[["pipe"]], block = TRUE)
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
        .read_marker(value) && {
          send(outq[[id]][["ctx"]], value, mode = 2L, block = TRUE)
          send(psock, 0L, mode = 2L, pipe = outq[[id]][["pipe"]], block = TRUE)
          outq[[id]] <- NULL
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
