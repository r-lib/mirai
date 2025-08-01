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
#' @param url the character host or dispatcher URL to dial into, including the
#'   port to connect to, e.g. 'tcp://hostname:5555' or
#'   'tls+tcp://10.75.32.70:5555'.
#' @param dispatcher \[default TRUE\] logical value, which should be set to
#'   TRUE if using dispatcher and FALSE otherwise.
#' @param ... reserved, but not currently used.
#' @param asyncdial \[default FALSE\] whether to perform dials asynchronously.
#'   The default FALSE will error if a connection is not immediately possible
#'   (for instance if [daemons()] has yet to be called on the host, or the
#'   specified port is not open etc.). Specifying TRUE continues retrying
#'   (indefinitely) if not immediately successful, which is more resilient but
#'   can mask potential connection issues.
#' @param autoexit \[default TRUE\] logical value, whether the daemon should
#'   exit automatically when its socket connection ends. By default, the process
#'   ends immediately when the host process ends. Supply `NA` to have a daemon
#'   complete any tasks in progress before exiting (see 'Persistence' section
#'   below).
#' @param cleanup \[default TRUE\] logical value, whether to perform cleanup of
#'   the global environment and restore attached packages and options to an
#'   initial state after each evaluation.
#' @param output \[default FALSE\] logical value, to output generated stdout /
#'   stderr if TRUE, or else discard if FALSE. Specify as TRUE in the `...`
#'   argument to [daemons()] or [launch_local()] to provide redirection of
#'   output to the host process (applicable only for local daemons).
#' @param idletime \[default Inf\] integer milliseconds maximum time to wait for
#'   a task (idle time) before exiting.
#' @param walltime \[default Inf\] integer milliseconds soft walltime (time
#'   limit) i.e. the minimum amount of real time elapsed before exiting.
#' @param maxtasks \[default Inf\] integer maximum number of tasks to execute
#'   (task limit) before exiting.
#' @param tlscert \[default NULL\] required for secure TLS connections over
#'   'tls+tcp://'. **Either** the character path to a file containing X.509
#'   certificate(s) in PEM format, comprising the certificate authority
#'   certificate chain starting with the TLS certificate and ending with the CA
#'   certificate, **or** a length 2 character vector comprising \[i\] the
#'   certificate authority certificate chain and \[ii\] the empty string `""`.
#' @param tls deprecated, please use `tlscert` instead.
#' @param id \[default NULL\] (optional) integer daemon ID provided to
#'   dispatcher to track connection status. Causes [status()] to report this ID
#'   under `$events` when the daemon connects and disconnects.
#' @param rs \[default NULL\] the initial value of .Random.seed. This is set
#'   automatically using L'Ecuyer-CMRG RNG streams generated by the host process
#'   if applicable, and should not be independently supplied.
#'
#' @return Invisibly, an integer exit code: 0L for normal termination, and a
#'   positive value if a self-imposed limit was reached: 1L (idletime), 2L
#'   (walltime), 3L (maxtasks).
#'
#' @section Persistence:
#'
#' The `autoexit` argument governs persistence settings for the daemon. The
#' default TRUE ensures that it will exit as soon as its socket connection
#' with the host process drops.
#'
#' Supplying `NA` will allow a daemon to exit cleanly once its socket connection
#' with the host process drops, as soon as it has finished any task that is
#' currently in progress. This may be useful if the daemon is performing some
#' side effect such as writing files to disk, and the result is not required in
#' the host process.
#'
#' Setting to FALSE allows the daemon to persist indefinitely even when there is
#' no longer a socket connection. This allows a host session to end and a new
#' session to connect at the URL where the daemon is dialled in. Daemons must be
#' terminated with `daemons(NULL)` in this case, which sends explicit exit
#' signals to all connected daemons.
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
  tls = tlscert,
  id = NULL,
  rs = NULL
) {
  cv <- cv()
  sock <- socket(if (dispatcher) "poly" else "rep")
  on.exit(reap(sock))
  pipe_notify(sock, cv, remove = TRUE, flag = flag_value_auto(autoexit))
  if (length(tls)) tls <- tls_config(client = tls)
  dial_sync_socket(sock, url, autostart = asyncdial || NA, tls = tls)

  `[[<-`(., "sock", sock)
  on.exit(`[[<-`(., "sock", NULL), add = TRUE)
  if (!output) {
    devnull <- file(nullfile(), open = "w", blocking = FALSE)
    sink(file = devnull)
    sink(file = devnull, type = "message")
    on.exit(
      {
        sink(type = "message")
        sink()
        close(devnull)
      },
      add = TRUE
    )
  }
  xc <- 0L
  task <- 1L
  timeout <- if (idletime > walltime) walltime else if (is.finite(idletime)) idletime
  maxtime <- if (is.finite(walltime)) mclock() + walltime else FALSE

  if (dispatcher) {
    aio <- recv_aio(sock, mode = 1L, cv = cv)
    is.numeric(id) && send(sock, c(0L, as.integer(id)), mode = 2L, block = TRUE)
    wait(cv) || return(invisible(xc))
    bundle <- collect_aio(aio)
    `[[<-`(.GlobalEnv, ".Random.seed", if (is.numeric(rs)) as.integer(rs) else bundle[[1L]])
    if (is.list(bundle[[2L]])) `opt<-`(sock, "serial", bundle[[2L]])
    snapshot()
    repeat {
      aio <- recv_aio(sock, mode = 1L, timeout = timeout, cv = cv)
      wait(cv) || break
      m <- collect_aio(aio)
      is.integer(m) && {
        m == 5L || next
        xc <- 1L
        break
      }
      cancel <- recv_aio(sock, mode = 8L, cv = substitute())
      data <- eval_mirai(m)
      stop_aio(cancel)
      (task >= maxtasks || maxtime && mclock() >= maxtime) && {
        .mark()
        send(sock, data, mode = 1L, block = TRUE)
        aio <- recv_aio(sock, mode = 8L, cv = cv)
        xc <- 2L + (task >= maxtasks)
        wait(cv)
        break
      }
      send(sock, data, mode = 1L, block = TRUE)
      if (cleanup) do_cleanup()
      task <- task + 1L
    }
  } else {
    if (is.numeric(rs)) `[[<-`(.GlobalEnv, ".Random.seed", as.integer(rs))
    snapshot()
    repeat {
      ctx <- .context(sock)
      aio <- recv_aio(ctx, mode = 1L, timeout = timeout, cv = cv)
      wait(cv) || break
      m <- collect_aio(aio)
      is.integer(m) && {
        xc <- 1L
        break
      }
      data <- eval_mirai(m)
      send(ctx, data, mode = 1L, block = TRUE)
      if (cleanup) do_cleanup()
      (task >= maxtasks || maxtime && mclock() >= maxtime) && {
        xc <- 2L + (task >= maxtasks)
        break
      }
      task <- task + 1L
    }
  }

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
  pipe_notify(sock, cv, remove = TRUE, flag = flag_value())
  dial(sock, url = url, autostart = NA, fail = 2L)
  `[[<-`(., "sock", sock)
  data <- eval_mirai(recv(sock, mode = 1L, block = TRUE))
  send(sock, data, mode = 1L, block = TRUE) || until(cv, .limit_short)
}

# internals --------------------------------------------------------------------

handle_mirai_error <- function(cnd) invokeRestart("mirai_error", cnd, sys.calls())

handle_mirai_interrupt <- function(cnd) invokeRestart("mirai_interrupt")

eval_mirai <- function(._mirai_.) {
  withRestarts(
    withCallingHandlers(
      {
        list2env(._mirai_.[["._mirai_globals_."]], envir = .GlobalEnv)
        eval(._mirai_.[[".expr"]], envir = ._mirai_., enclos = .GlobalEnv)
      },
      error = handle_mirai_error,
      interrupt = handle_mirai_interrupt
    ),
    mirai_error = mk_mirai_error,
    mirai_interrupt = mk_interrupt_error
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
  vars <- names(.GlobalEnv)
  rm(list = vars[!vars %in% .[["vars"]]], envir = .GlobalEnv)
  new <- search()
  lapply(new[!new %in% .[["se"]]], detach, character.only = TRUE)
  options(.[["op"]])
}

snapshot <- function() `[[<-`(`[[<-`(`[[<-`(., "op", .Options), "se", search()), "vars", names(.GlobalEnv))

flag_value_auto <- function(autoexit) {
  (isFALSE(autoexit) || isNamespace(topenv(parent.frame(), NULL))) && return(autoexit) ||
    is.na(autoexit) || isNamespaceLoaded("covr") || return(tools::SIGTERM)
}

flag_value <- function() isNamespaceLoaded("covr") || return(tools::SIGTERM)
