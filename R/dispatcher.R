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
#' @param host (character) URL to dial into, typically an IPC address.
#' @param url (character) URL to listen at for daemon connections, e.g.
#'   'tcp://hostname:5555'. Use 'tls+tcp://' for secure TLS.
#' @param n (integer) number of local daemons launched by host.
#'
#' @return Invisibly, an integer exit code: 0L for normal termination.
#'
#' @export
#'
dispatcher <- function(host, url = NULL, n = 0L) {
  cv <- cv()
  sock <- socket("rep")
  on.exit(reap(sock))
  pipe_notify(sock, cv, remove = TRUE, flag = tools::SIGTERM)

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

  envir <- new.env(hash = FALSE, parent = emptyenv())
  `[[<-`(envir, "stream", res)

  if (n) {
    for (i in seq_len(n)) {
      while (!until(cv, .limit_long)) {
        cv_signal(cv) || wait(cv) || return()
      }
    }
  } else {
    listen(psock, url = url, tls = tls, fail = 2L)
    url <- sub_real_port(psock, url)
  }
  send(sock, url, mode = 2L, block = TRUE)

  invisible(suspendInterrupts(.dispatcher(sock, psock, m, .connReset, serial, envir, next_stream)))
}
