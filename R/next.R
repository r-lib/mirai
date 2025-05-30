# mirai ------------------------------------------------------------------------

#' Next >> Developer Interface
#'
#' `nextstream` retrieves the currently stored L'Ecuyer-CMRG RNG stream
#' for the specified compute profile and advances it to the next stream.
#'
#' These functions are exported for use by packages extending \pkg{mirai} with
#' alternative launchers of [daemon()] processes.
#'
#' For `nextstream`: This function should be called for its return value
#' when required. The function also has the side effect of automatically
#' advancing the stream stored within the compute profile. This ensures that the
#' next recursive stream is returned when the function is called again.
#'
#' @inheritParams mirai
#'
#' @return For `nextstream`: a length 7 integer vector, as given by
#'   `.Random.seed` when the L'Ecuyer-CMRG RNG is in use (may be passed directly
#'   to the `rs` argument of [daemon()]), or else NULL if a stream has not yet
#'   been created.
#'
#' @examplesIf interactive()
#' daemons(1L)
#' nextstream()
#' nextstream()
#'
#' nextget("pid")
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
#' @param x character value of item to retrieve. One of `"n"` (number of
#'   dispatcher daemons), `"pid"` (dispatcher process ID), `"dispatcher"` (the
#'   URL to connect to dispatcher from the host) `"url"` (the URL to connect to
#'   dispatcher from daemons) or `"tls"` (the stored client TLS configuration
#'   for use by daemons).
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
#' @param xc integer return value of [daemon()].
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
nextcode <- function(xc)
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

# internals --------------------------------------------------------------------

next_stream <- function(envir) {
  stream <- envir[["stream"]]
  if (is.integer(stream)) `[[<-`(envir, "stream", parallel::nextRNGStream(stream))
  stream
}
