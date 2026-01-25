# mirai ------------------------------------------------------------------------

#' Daemon Instance
#'
#' Starts up an execution daemon to receive [mirai()] requests. Awaits data,
#' evaluates an expression in an environment containing the supplied data,
#' and returns the value to the host caller. Daemon settings may be controlled
#' by [daemons()] and this function should not need to be invoked directly,
#' unless deploying manually on remote resources.
#'
#' The network topology is such that daemons dial into the host or dispatcher,
#' which listens at the `url` address. In this way, network resources may be
#' added or removed dynamically and the host or dispatcher automatically
#' distributes tasks to all available daemons.
#'
#' @param url (character) host or dispatcher URL to dial into, e.g.
#'   'tcp://hostname:5555' or 'tls+tcp://10.75.32.70:5555'.
#' @param dispatcher (logical) whether dialing into dispatcher or directly to
#'   host.
#' @param ... reserved for future use.
#' @param asyncdial (logical) whether to dial asynchronously. `FALSE` errors if
#'   connection fails immediately. `TRUE` retries indefinitely (more resilient
#'   but can mask connection issues).
#' @param autoexit (logical) whether to exit when the socket connection ends.
#'   `TRUE` exits immediately, `NA` completes current task first, `FALSE`
#'   persists indefinitely. See Persistence section.
#' @param cleanup (logical) whether to restore global environment, packages, and
#'   options to initial state after each evaluation.
#' @param output (logical) whether to output stdout/stderr. For local daemons
#'   via [daemons()] or [launch_local()], redirects output to host process.
#' @param idletime (integer) milliseconds to wait idle before exiting.
#' @param walltime (integer) milliseconds of real time before exiting (soft
#'   limit).
#' @param maxtasks (integer) maximum tasks to execute before exiting.
#' @param tlscert (character) for secure TLS connections. Either a file path to
#'   PEM-encoded certificate authority certificate chain (starting with the TLS
#'   certificate and ending with the CA certificate), or a length-2 vector of
#'   (certificate chain, empty string `""`).
#' @param rs (integer vector) initial `.Random.seed` value. Set automatically by
#'   host process; do not supply manually.
#'
#' @return Invisibly, an integer exit code: 0L for normal termination, and a
#'   positive value if a self-imposed limit was reached: 1L (idletime), 2L
#'   (walltime), 3L (maxtasks).
#'
#' @section Persistence:
#'
#' The `autoexit` argument governs persistence settings for the daemon. The
#' default `TRUE` ensures that it exits as soon as its socket connection with
#' the host process drops. A 200ms grace period allows the daemon process to
#' exit normally, after which it will be forcefully terminated.
#'
#' Supplying `NA` ensures that a daemon always exits cleanly after its socket
#' connection with the host drops. This means that it can temporarily outlive
#' this connection, but only to complete any task that is currently in progress.
#' This can be useful if the daemon is performing a side effect such as writing
#' files to disk, with the result not being required back in the host process.
#'
#' Setting to `FALSE` allows the daemon to persist indefinitely even when there
#' is no longer a socket connection. This allows a host session to end and a new
#' session to connect at the URL where the daemon is dialed in. Daemons must be
#' terminated with `daemons(NULL)` in this case instead of `daemons(0)`. This
#' sends explicit exit signals to all connected daemons.
#'
#' @export
#'
daemon <- function(
  url,
  dispatcher = TRUE,
  ...,
  asyncdial = FALSE,
  autoexit = TRUE,
  cleanup = TRUE,
  output = FALSE,
  idletime = Inf,
  walltime = Inf,
  maxtasks = Inf,
  tlscert = NULL,
  rs = NULL
) {
  cv <- cv()
  sock <- socket(if (dispatcher) "poly" else "rep")
  on.exit({
    reap(sock)
    `[[<-`(., "sock", NULL)
    `[[<-`(., "otel_span", NULL)
  })
  `[[<-`(., "sock", sock)
  pipe_notify(sock, cv, remove = TRUE, flag = flag_value(autoexit))
  if (length(tlscert)) {
    tlscert <- tls_config(client = tlscert)
  }
  dial_sync_socket(sock, url, autostart = asyncdial || NA, tls = tlscert)
  `[[<-`(., "otel_span", otel_span("daemon connect", url))

  if (!output) {
    devnull <- file(nullfile(), open = "w", blocking = FALSE)
    sink(file = devnull)
    sink(file = devnull, type = "message")
  }
  xc <- 0L
  task <- 1L
  timeout <- if (idletime > walltime) {
    walltime
  } else if (is.finite(idletime)) {
    idletime
  }
  maxtime <- if (is.finite(walltime)) mclock() + walltime else FALSE

  if (dispatcher) {
    aio <- recv_aio(sock, mode = 1L, cv = cv)
    if (wait(cv)) {
      bundle <- collect_aio(aio)
      `[[<-`(globalenv(), ".Random.seed", if (is.numeric(rs)) as.integer(rs) else bundle[[1L]])
      if (is.list(bundle[[2L]])) {
        `opt<-`(sock, "serial", bundle[[2L]])
      }
      snapshot()
      repeat {
        aio <- recv_aio(sock, mode = 1L, timeout = timeout, cv = cv)
        wait(cv) || break
        m <- collect_aio(aio)
        # handle cancellation received late: raw (if deserialization failed)
        is.raw(m) && next
        is.integer(m) &&
          {
            m == 5L || next
            xc <- 1L
            break
          }
        (task >= maxtasks || maxtime && mclock() >= maxtime) &&
          {
            marked(send(sock, eval_mirai(m, sock), mode = 1L, block = TRUE))
            aio <- recv_aio(sock, mode = 8L, cv = cv)
            xc <- 2L + (task >= maxtasks)
            wait(cv)
            break
          }
        send(sock, eval_mirai(m, sock), mode = 1L, block = TRUE)
        if (cleanup) {
          do_cleanup()
        }
        task <- task + 1L
      }
    }
  } else {
    if (is.numeric(rs)) {
      `[[<-`(globalenv(), ".Random.seed", as.integer(rs))
    }
    snapshot()
    repeat {
      ctx <- .context(sock)
      aio <- recv_aio(ctx, mode = 1L, timeout = timeout, cv = cv)
      wait(cv) || break
      m <- collect_aio(aio)
      is.integer(m) &&
        {
          xc <- 1L
          break
        }
      (task >= maxtasks || maxtime && mclock() >= maxtime) &&
        {
          marked(send(ctx, eval_mirai(m), mode = 1L, block = TRUE))
          xc <- 2L + (task >= maxtasks)
          wait(cv)
          break
        }
      send(ctx, eval_mirai(m), mode = 1L, block = TRUE)
      if (cleanup) {
        do_cleanup()
      }
      task <- task + 1L
    }
  }

  if (!output) {
    sink(type = "message")
    sink()
    close.connection(devnull)
  }
  otel_span("daemon disconnect", url, links = list(.[["otel_span"]]))
  invisible(xc)
}

#' dot Daemon
#'
#' Ephemeral executor for the remote process. User code must not call this.
#' Consider `daemon(maxtasks = 1L)` instead.
#'
#' @inheritParams daemon
#'
#' @return Logical TRUE or FALSE.
#'
#' @noRd
#'
.daemon <- function(url) {
  cv <- cv()
  sock <- socket("rep")
  on.exit(reap(sock))
  pipe_notify(sock, cv, remove = TRUE, flag = tools::SIGTERM)
  dial(sock, url = url, autostart = NA, fail = 2L)
  `[[<-`(., "sock", sock)
  m <- recv(sock, mode = 1L, block = TRUE)
  marked(send(sock, eval_mirai(m), mode = 1L, block = TRUE)) || wait(cv)
}

# internals --------------------------------------------------------------------

eval_mirai <- function(._mirai_., sock = NULL) {
  if (length(sock)) {
    cancel <- recv_aio(sock, mode = 8L, cv = substitute())
    on.exit(stop_aio(cancel))
  }
  tryCatch(
    withCallingHandlers(
      {
        list2env(._mirai_.[["._globals_."]], envir = globalenv())
        sock <- otel_eval_span(._mirai_.[["._otel_."]])
        eval(._mirai_.[["._expr_."]], envir = ._mirai_., enclos = globalenv())
      },
      error = function(cnd) {
        `[[<-`(., "syscalls", sys.calls())
      }
    ),
    error = function(cnd) {
      otel_set_span_error(sock, "miraiError")
      mk_mirai_error(cnd, .[["syscalls"]])
    },
    interrupt = function(cnd) {
      otel_set_span_error(sock, "miraiInterrupt")
      .miraiInterrupt
    }
  )
}

dial_sync_socket <- function(sock, url, autostart = NA, tls = NULL) {
  cv <- cv()
  pipe_notify(sock, cv, add = TRUE)
  dial(sock, url = url, autostart = autostart, tls = tls, fail = 2L)
  wait(cv)
  pipe_notify(sock, NULL, add = TRUE)
}

do_cleanup <- function() {
  vars <- names(globalenv())
  rm(list = vars[!vars %in% .[["vars"]]], envir = globalenv())
  new <- search()
  lapply(new[!new %in% .[["se"]]], detach, character.only = TRUE)
  options(.[["op"]])
}

snapshot <- function() {
  `[[<-`(`[[<-`(`[[<-`(., "op", .Options), "se", search()), "vars", names(globalenv()))
}

flag_value <- function(autoexit) {
  is.na(autoexit) && return(TRUE)
  autoexit && return(tools::SIGTERM)
}

marked <- function(expr) {
  .mark()
  on.exit(.mark(FALSE))
  expr
}
