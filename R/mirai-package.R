#' mirai: Minimalist Async Evaluation Framework for R
#'
#' Designed for simplicity, a 'mirai' evaluates an R expression asynchronously
#' in a parallel process, locally or distributed over the network. Modern
#' networking and concurrency, built on 'nanonext' and 'NNG', ensures reliable
#' scheduling over fast inter-process communications or TCP/IP secured by TLS.
#' Launch remote resources via SSH or cluster managers for distributed
#' computing. The queued architecture scales efficiently to millions of tasks
#' over thousands of connections, requiring no storage on the file system.
#' Innovative features include event-driven promises, asynchronous parallel map,
#' and seamless serialization of otherwise non-exportable reference objects.
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
#' @section Reference Manual:
#'
#' `vignette("mirai", package = "mirai")`
#'
#' @importFrom nanonext .advance call_aio call_aio_ collect_aio collect_aio_
#'   .context cv cv_signal cv_value dial .interrupt ip_addr
#'   is_error_value .keep listen .mark mclock monitor msleep nng_error opt opt<-
#'   parse_url pipe_id pipe_notify random .read_header .read_marker read_monitor
#'   reap recv recv_aio request send serial_config socket stat stop_aio
#'   tls_config unresolved .unresolved until wait write_cert
#'
"_PACKAGE"

# nocov start
# tested implicitly

.onLoad <- function(libname, pkgname) {
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

. <- `[[<-`(new.env(), "cp", "default")
.. <- new.env()
.command <- NULL
.urlscheme <- NULL
.limit_long <- 10000L
.limit_long_secs <- 10L
.limit_short <- 5000L

._ <- list2env(
  list(
    arglen = "`n` must equal the length of `args`, or either must be 1",
    cluster_inactive = "cluster is no longer active",
    daemons_set = "daemons already set for `%s` compute profile",
    daemons_unset = "daemons must be set to use launchers",
    dispatcher_args = "`dispatcher` should be either TRUE or FALSE",
    dot_required = "`.` must be an element of the character vector(s) supplied to `args`",
    function_required = "`.f` must be of type function, not %s",
    localhost = "SSH tunnelling requires daemons `url` hostname to be `127.0.0.1`",
    missing_expression = "missing expression, perhaps wrap in {}?",
    missing_url = "`n` must be 1 or greater, or else `url` must be supplied",
    named_args = "all items in `.args` must be named, unless supplying an environment",
    named_dots = "all `...` arguments must be named, unless supplying an environment",
    n_one = "`n` must be 1 or greater",
    n_zero = "the number of daemons must be zero or greater",
    not_found = "compute profile `%s` not found",
    numeric_n = "`n` must be numeric, did you mean to provide `url`?",
    rstudio_api = "workbench launcher requires the `rstudioapi` package",
    rstudio_unavailable = "workbench launcher requires a compatible environment",
    sync_daemons = "mirai: initial sync with daemon(s) [%d secs elapsed]",
    sync_dispatcher = "mirai: initial sync with dispatcher [%d secs elapsed]",
    within_map = "cannot create local daemons from within mirai map"
  ),
  hash = TRUE
)
