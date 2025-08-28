#' mirai: Minimalist Async Evaluation Framework for R
#'
#' *moving already* \cr \cr
#' Designed for simplicity, a 'mirai' evaluates an R expression asynchronously,
#' locally or distributed over the network. Built on 'nanonext' and 'NNG' for
#' modern networking and concurrency, scales efficiently to millions of tasks
#' over thousands of parallel processes. Provides optimal scheduling over fast
#' 'IPC', TCP, and TLS connections, integrating with SSH or cluster managers.
#' Implements event-driven promises for reactive programming, and supports
#' custom serialization for cross-language data types.
#'
#' @section Notes:
#'
#'  For local mirai requests, the default transport for inter-process
#'  communications is platform-dependent: abstract Unix domain sockets on Linux,
#'  Unix domain sockets on MacOS, Solaris and other POSIX platforms, and named
#'  pipes on Windows.
#'
#'  This may be overriden, if desired, by specifying 'url' in the [daemons()]
#'  interface and launching daemons using [launch_local()].
#'
#' @section OpenTelemetry:
#'
#' mirai provides comprehensive OpenTelemetry tracing support for observing
#' asynchronous operations and distributed computation. Please refer to the
#' OpenTelemetry vignette for further details:
#' `vignette("v05-opentelemetry", package = "mirai")`
#'
#' @section Reference Manual:
#'
#' `vignette("mirai", package = "mirai")`
#'
#' @importFrom nanonext .advance call_aio call_aio_ collect_aio collect_aio_
#'   .context cv cv_reset cv_signal cv_value dial .dispatcher ip_addr
#'   is_error_value .keep listen .mark mclock monitor msleep nng_error opt opt<-
#'   parse_url pipe_id pipe_notify race_aio random reap recv recv_aio request
#'   send serial_config socket stat stop_aio stop_request tls_config unresolved
#'   .unresolved until wait wait_ write_cert
#'
"_PACKAGE"

# nocov start
# tested implicitly

.onLoad <- function(libname, pkgname) {
  otel_cache_tracer()
  cli_enabled <<- requireNamespace("cli", quietly = TRUE)
  switch(
    Sys.info()[["sysname"]],
    Linux = {
      .command <<- file.path(R.home("bin"), "Rscript")
      .urlscheme <<- "abstract://"
    },
    Windows = {
      .command <<- file.path(R.home("bin"), "Rscript.exe")
      .urlscheme <<- "ipc://"
    },
    {
      .command <<- file.path(R.home("bin"), "Rscript")
      .urlscheme <<- "ipc:///tmp/"
    }
  )
}

# nocov end

cli_enabled <- FALSE
.command <- NULL
.urlscheme <- NULL

. <- `[[<-`(new.env(), "cp", "default")
.. <- new.env()
.opts <- list2env(list(.flat = .flat, .progress = .progress, .stop = .stop))
.limit_long <- 10000L
.limit_long_secs <- as.integer(.limit_long * 0.001)
.limit_short <- 5000L
.sleep_daemons <- 200L
.sleep_signal <- 10L

._ <- list2env(
  list(
    arglen = "`n` must equal the length of `args`, or either must be 1",
    cluster_inactive = "cluster is no longer active",
    daemons_unset = "daemons must be set to use this function",
    dot_required = "`.` must be an element of the character vector(s) supplied to `args`",
    function_required = "`.f` must be of type function, not %s",
    localhost = "SSH tunnelling requires daemons `url` hostname to be `127.0.0.1`",
    missing_expression = "missing expression, perhaps wrap in {}?",
    named_args = "all items in `.args` must be named, unless supplying an environment",
    named_dots = "all `...` arguments must be named, unless supplying an environment",
    n_one = "`n` must be 1 or greater",
    n_zero = "the number of daemons must be zero or greater",
    numeric_n = "`n` must be numeric, did you mean to provide `url`?",
    posit_api = "requires Posit Workbench (Rstudio Pro session)",
    sync_daemons = "mirai: initial sync with daemon(s) [%d secs elapsed]",
    sync_dispatcher = "mirai: initial sync with dispatcher [%d secs elapsed]",
    synchronous = "daemons cannot be launched for synchronous compute profiles",
    within_map = "cannot create local daemons from within mirai map"
  ),
  hash = TRUE
)
