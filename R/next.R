# mirai ------------------------------------------------------------------------

#' Next >> Developer Interface
#'
#' `nextstream` retrieves the currently stored L'Ecuyer-CMRG random number
#' generator (RNG) stream for the specified compute profile and advances it to
#' the next stream.
#'
#' These functions are exported for use by packages extending \pkg{mirai} with
#' alternative launchers of [daemon()] processes.
#'
#' For `nextstream`: Calling this function advances the stream stored within
#' the compute profile. This ensures that the next recursive stream is returned
#' on subsequent calls.
#'
#' @inheritParams mirai
#'
#' @return For `nextstream`: a length 7 integer vector, as given by
#'   `.Random.seed` when the L'Ecuyer-CMRG RNG is in use (may be passed directly
#'   to the `rs` argument of [daemon()]), or else NULL if a stream has not yet
#'   been created.
#'
#' @examples
#' daemons(sync = TRUE)
#' nextstream()
#' nextstream()
#'
#' nextget("url")
#'
#' daemons(0)
#'
#' @keywords internal
#' @export
#'
nextstream <- function(.compute = "default") next_stream(..[[.compute]])

#' Next >> Developer Interface
#'
#' `nextget` retrieves the specified item from the specified compute profile.
#'
#' @param x (character) item to retrieve: `"n"` (daemon count), `"dispatcher"`
#'   (dispatcher-to-host URL), `"url"` (daemon connection URL), or `"tls"`
#'   (client TLS configuration).
#'
#' @return For `nextget`: the requested item, or else NULL if not present.
#'
#' @keywords internal
#' @rdname nextstream
#' @export
#'
nextget <- function(x, .compute = "default") ..[[.compute]][[x]]

#' Next >> Developer Interface
#'
#' `nextcode` translates integer exit codes returned by [daemon()].
#'
#' @param xc (integer) return value from [daemon()].
#'
#' @return For `nextcode`: character string.
#'
#' @examples
#' nextcode(0L)
#' nextcode(1L)
#'
#' @keywords internal
#' @rdname nextstream
#' @export
#'
nextcode <- function(xc) {
  sprintf(
    "%d | Daemon %s",
    xc,
    switch(
      xc + 1L,
      "connection terminated",
      "idletime limit reached",
      "walltime limit reached",
      "task limit reached"
    )
  )
}

#' Evaluate a Function Call on a Daemon
#'
#' Evaluates a function call synchronously on a daemon of the specified compute
#' profile, returning its value. This is a developer interface for packages
#' integrating \pkg{mirai} as an evaluation backend, for example the rendering
#' hooks installed by [register_render()].
#'
#' The call is dispatched as a single [mirai()] and blocks until it resolves. If
#' `.f` accepts an `envir` argument and none is supplied in `...`, it is called
#' with `envir` set to the daemon's global environment, so that objects created
#' by successive calls to a `cleanup = FALSE` profile persist and are visible to
#' one another (mirroring an interactive session). Arguments in `...` are
#' evaluated in the caller and passed by value to the daemon.
#'
#' @param .f a function to call on the daemon.
#' @param ... arguments passed to `.f`.
#' @inheritParams mirai
#'
#' @return The value of `.f` called with the supplied arguments, evaluated on a
#'   daemon of the compute profile.
#'
#' @examples
#' daemons(sync = TRUE)
#' daemon_call(sum, 1:10)
#' daemons(0)
#'
#' @export
#'
daemon_call <- function(.f, ..., .compute = NULL) {
  require_daemons(.compute = .compute)
  args <- list(...)
  add_envir <- is.null(args[["envir"]]) && "envir" %in% names(formals(.f))
  # Build the call with `.f` and its arguments inlined; `globalenv()` is left
  # unevaluated so it resolves to the daemon's global environment.
  expr <- if (add_envir) {
    bquote(do.call(.(.f), c(.(args), list(envir = globalenv()))))
  } else {
    bquote(do.call(.(.f), .(args)))
  }
  mirai(expr, .compute = .compute)[]
}

# internals --------------------------------------------------------------------

next_stream <- function(envir) {
  stream <- envir[["stream"]]
  if (is.integer(stream)) {
    `[[<-`(envir, "stream", parallel::nextRNGStream(stream))
  }
  stream
}

maybe_next_stream <- function(envir) {
  is.null(envir[["seed"]]) || return()
  next_stream(envir)
}
