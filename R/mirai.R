# mirai ------------------------------------------------------------------------

#' mirai (Evaluate Async)
#'
#' Evaluate an expression asynchronously in a new background R process or
#' persistent daemon (local or remote). This function will return immediately
#' with a 'mirai', which will resolve to the evaluated result once complete.
#'
#' The value of a mirai may be accessed at any time at `$data`, and if yet
#' to resolve, an 'unresolved' logical NA will be returned instead. Each mirai
#' has an attribute `id`, which is a monotonically increasing integer identifier
#' in each session.
#'
#' [unresolved()] may be used on a mirai, returning TRUE if a 'mirai' has yet to
#' resolve and FALSE otherwise. This is suitable for use in control flow
#' statements such as `while` or `if`.
#'
#' Alternatively, to call (and wait for) the result, use [call_mirai()] on the
#' returned 'mirai'. This will block until the result is returned.
#'
#' Specify `.compute` to send the mirai using a specific compute profile (if
#' previously created by [daemons()]), otherwise leave as `"default"`.
#'
#' @param .expr (expression) code to evaluate asynchronously, or a language
#'   object. Wrap multi-line expressions in `{}`.
#' @param ... (named arguments | environment) objects required by `.expr`,
#'   assigned to the daemon's global environment. See 'evaluation' section
#'   below.
#' @param .args (named list | environment) objects required by .expr, kept local
#'   to the evaluation environment (unlike `...`). See 'evaluation' section
#'   below.
#' @param .timeout (integer) timeout in milliseconds. The mirai resolves to an
#'   'errorValue' 5 (timed out) if evaluation exceeds this limit. `NULL`
#'   (default) for no timeout.
#' @param .compute (character) name of the compute profile. Each profile has its
#'   own independent set of daemons. `NULL` (default) uses the 'default'
#'   profile.
#'
#' @return A 'mirai' object.
#'
#' @section Evaluation:
#'
#' The expression `.expr` will be evaluated in a separate R process in a clean
#' environment (not the global environment), consisting only of the objects
#' supplied to `.args`, with the objects passed as `...` assigned to the global
#' environment of that process.
#'
#' As evaluation occurs in a clean environment, all undefined objects must be
#' supplied through `...` and/or `.args`, including self-defined functions.
#' Functions from a package should use namespaced calls such as
#' `mirai::mirai()`, or else the package should be loaded beforehand as part of
#' `.expr`.
#'
#' Supply objects to `...` rather than `.args` for evaluation to occur *as if*
#' in your global environment. This is needed for non-local variables or helper
#' functions required by other functions, which scoping rules may otherwise
#' prevent from being found.
#'
#' @section Timeouts:
#'
#' Specifying the `.timeout` argument ensures that the mirai always resolves.
#' When using dispatcher, the mirai will be cancelled after it times out (as if
#' [stop_mirai()] had been called). However, cancellation is not guaranteed --
#' for example, compiled code may not be interruptible. When not using
#' dispatcher, the mirai task continues to completion in the daemon process,
#' even if it times out in the host process.
#'
#' @section Errors:
#'
#' If an error occurs in evaluation, the error message is returned as a
#' character string of class 'miraiError' and 'errorValue'. [is_mirai_error()]
#' may be used to test for this. The elements of the original condition are
#' accessible via `$` on the error object. A stack trace comprising a list of
#' calls is also available at `$stack.trace`, and the original condition classes
#' at `$condition.class`.
#'
#' If a daemon crashes or terminates unexpectedly during evaluation, an
#' 'errorValue' 19 (Connection reset) is returned.
#'
#' [is_error_value()] tests for all error conditions including 'mirai' errors,
#' interrupts, and timeouts.
#'
#' @examplesIf interactive()
#' # specifying objects via '...'
#' n <- 3
#' m <- mirai(x + y + 2, x = 2, y = n)
#' m
#' m$data
#' Sys.sleep(0.2)
#' m$data
#'
#' # passing the calling environment to '...'
#' df1 <- data.frame(a = 1, b = 2)
#' df2 <- data.frame(a = 3, b = 1)
#' df_matrix <- function(x, y) {
#'   mirai(as.matrix(rbind(x, y)), environment(), .timeout = 1000)
#' }
#' m <- df_matrix(df1, df2)
#' m[]
#'
#' # using unresolved()
#' m <- mirai(
#'   {
#'     res <- rnorm(n)
#'     res / rev(res)
#'   },
#'   n = 1e6
#' )
#' while (unresolved(m)) {
#'   cat("unresolved\n")
#'   Sys.sleep(0.1)
#' }
#' str(m$data)
#'
#' # evaluating scripts using source() in '.expr'
#' n <- 10L
#' file <- tempfile()
#' cat("r <- rnorm(n)", file = file)
#' m <- mirai({source(file); r}, file = file, n = n)
#' call_mirai(m)$datado
#' unlink(file)
#'
#' # use source(local = TRUE) when passing in local variables via '.args'
#' n <- 10L
#' file <- tempfile()
#' cat("r <- rnorm(n)", file = file)
#' m <- mirai({source(file, local = TRUE); r}, .args = list(file = file, n = n))
#' call_mirai(m)$data
#' unlink(file)
#'
#' # passing a language object to '.expr' and a named list to '.args'
#' expr <- quote(a + b + 2)
#' args <- list(a = 2, b = 3)
#' m <- mirai(.expr = expr, .args = args)
#' collect_mirai(m)
#'
#' @export
#'
mirai <- function(.expr, ..., .args = list(), .timeout = NULL, .compute = NULL) {
  missing(.expr) && stop(._[["missing_expression"]])
  envir <- compute_env(.compute)

  expr <- substitute(.expr)
  globals <- list(...)
  length(globals) &&
    {
      gn <- names(globals)
      if (is.null(gn)) {
        is.environment(globals[[1L]]) || stop(._[["named_dots"]])
        globals <- as.list.environment(globals[[1L]], all.names = TRUE)
        globals[[".Random.seed"]] <- NULL
      }
      all(nzchar(gn)) || stop(._[["named_dots"]])
    }
  ctx_spn <- otel_mirai_span(envir)
  if (length(envir[["seed"]])) {
    globals[[".Random.seed"]] <- next_stream(envir)
  }
  data <- list(
    ._expr_. = if (
      is.symbol(expr) && exists(as.character(expr), envir = parent.frame()) && is.language(.expr)
    ) {
      .expr
    } else {
      expr
    },
    ._globals_. = globals,
    ._otel_. = ctx_spn[[1L]]
  )

  if (length(.args)) {
    if (is.environment(.args)) {
      .args <- as.list.environment(.args, all.names = TRUE)
    } else {
      length(names(.args)) && all(nzchar(names(.args))) || stop(._[["named_args"]])
    }
    data <- c(.args, data)
  }

  is.null(envir) && return(ephemeral_daemon(data, .timeout))

  req <- request(
    .context(envir[["sock"]]),
    data,
    send_mode = 1L,
    recv_mode = 1L,
    timeout = .timeout,
    cv = envir[["cv"]],
    id = envir[["dispatcher"]]
  )
  otel_set_span_id(ctx_spn[[2L]], attr(req, "id"))
  envir[["sync"]] && evaluate_sync(envir)
  invisible(req)
}

#' Evaluate Everywhere
#'
#' Evaluate an expression 'everywhere' on all connected daemons for the
#' specified compute profile. Daemons must be set prior to calling this
#' function. Performs operations across daemons such as loading packages or
#' exporting common data. Resultant changes to the global environment, loaded
#' packages and options are persisted regardless of a daemon's `cleanup`
#' setting.
#'
#' If using dispatcher, this function forces a synchronization point: the
#' [everywhere()] call must complete on all daemons before subsequent mirai
#' evaluations proceed.
#'
#' Calling [everywhere()] does not affect the RNG stream for mirai calls when
#' using a reproducible `seed` value at [daemons()]. This allows the seed
#' associated with each mirai call to be the same, regardless of the number of
#' daemons used. However, code evaluated in an [everywhere()] call is itself
#' non-reproducible if it involves random numbers.
#'
#' @inheritParams mirai
#' @param .min (integer) minimum daemons to evaluate on (dispatcher only).
#'   Creates a synchronization point, useful for remote daemons that take time
#'   to connect.
#'
#' @return A 'mirai_map' (list of 'mirai' objects).
#'
#' @inheritSection mirai Evaluation
#'
#' @examples
#' daemons(sync = TRUE)
#'
#' # export common data by a super-assignment expression:
#' everywhere(y <<- 3)
#' mirai(y)[]
#'
#' # '...' variables are assigned to the global environment
#' # '.expr' may be specified as an empty {} in such cases:
#' everywhere({}, a = 1, b = 2)
#' mirai(a + b - y == 0L)[]
#'
#' # everywhere() returns a mirai_map object:
#' mp <- everywhere("just a normal operation")
#' mp
#' mp[.flat]
#' mp <- everywhere(stop("everywhere"))
#' collect_mirai(mp)
#' daemons(0)
#'
#' # loading a package on all daemons
#' daemons(sync = TRUE)
#' everywhere(library(parallel))
#' m <- mirai("package:parallel" %in% search())
#' m[]
#' daemons(0)
#'
#' @export
#'
everywhere <- function(.expr, ..., .args = list(), .min = 1L, .compute = NULL) {
  require_daemons(.compute = .compute, call = environment())
  if (is.null(.compute)) {
    .compute <- .[["cp"]]
  }
  envir <- ..[[.compute]]

  expr <- substitute(.expr)
  .expr <- c(
    .snapshot,
    as.expression(
      if (
        is.symbol(expr) && exists(as.character(expr), envir = parent.frame()) && is.language(.expr)
      ) {
        .expr
      } else {
        expr
      }
    )
  )

  xlen <- if (is.null(envir[["dispatcher"]])) {
    max(stat(envir[["sock"]], "pipes"), envir[["n"]])
  } else {
    max(.min, info(.compute)[[1L]])
  }
  seed <- envir[["seed"]]
  on.exit(`[[<-`(envir, "seed", seed))
  `[[<-`(envir, "seed", NULL)
  vec <- lapply(seq_len(xlen), function(i) {
    if (i < xlen) {
      marked(mirai(.expr, ..., .args = .args, .compute = .compute))
    } else {
      mirai(.expr, ..., .args = .args, .compute = .compute)
    }
  })
  `[[<-`(envir, "everywhere", vec)
  invisible(`class<-`(vec, "mirai_map"))
}

#' mirai (Call Value)
#'
#' Waits for the 'mirai' to resolve if still in progress (blocking but
#' user-interruptible), stores the value at `$data`, and returns the 'mirai'
#' object.
#'
#' Accepts a list of 'mirai' objects, such as those returned by [mirai_map()],
#' as well as individual 'mirai'.
#'
#' `x[]` may also be used to wait for and return the value of a mirai `x`, and
#' is the equivalent of `call_mirai(x)$data`.
#'
#' @param x (mirai | list) a 'mirai' object or list of 'mirai' objects.
#'
#' @return The passed object (invisibly). For a 'mirai', the retrieved value is
#'   stored at `$data`.
#'
#' @section Alternatively:
#'
#' The value of a 'mirai' may be accessed at any time at `$data`, and if yet to
#' resolve, an 'unresolved' logical NA will be returned instead.
#'
#' Using [unresolved()] on a 'mirai' returns TRUE only if it has yet to resolve
#' and FALSE otherwise. This is suitable for use in control flow statements such
#' as `while` or `if`.
#'
#' @inheritSection mirai Errors
#'
#' @seealso [race_mirai()]
#'
#' @examplesIf interactive()
#' # using call_mirai()
#' df1 <- data.frame(a = 1, b = 2)
#' df2 <- data.frame(a = 3, b = 1)
#' m <- mirai(as.matrix(rbind(df1, df2)), df1 = df1, df2 = df2, .timeout = 1000)
#' call_mirai(m)$data
#'
#' # using unresolved()
#' m <- mirai(
#'   {
#'     res <- rnorm(n)
#'     res / rev(res)
#'   },
#'   n = 1e6
#' )
#' while (unresolved(m)) {
#'   cat("unresolved\n")
#'   Sys.sleep(0.1)
#' }
#' str(m$data)
#'
#' @export
#'
call_mirai <- call_aio_

#' mirai (Race)
#'
#' Accepts a list of 'mirai' objects, such as those returned by [mirai_map()].
#' Returns the index of the first resolved 'mirai'. If any mirai is already
#' resolved, returns immediately. Otherwise waits for at least one to resolve,
#' blocking but user-interruptible.
#'
#' All of the 'mirai' objects supplied must belong to the same compute profile.
#'
#' @param x (list) of 'mirai' objects.
#' @inheritParams mirai
#'
#' @return Integer index of the first resolved 'mirai' (invisibly), or
#'   \code{0L} if the list is empty.
#'
#' @details When called on a list where some mirais are already resolved,
#'   returns the index of the first resolved mirai immediately without waiting.
#'   When all mirais are unresolved, blocks until at least one resolves. If
#'   multiple mirais resolve during the same wait iteration, returns the
#'   index of the first resolved in list order.
#'
#'   This enables an efficient "process as completed" pattern:
#'   \preformatted{
#'   remaining <- list(m1, m2, m3)
#'   while (length(remaining) > 0) {
#'     idx <- race_mirai(remaining)
#'     process(remaining[[idx]]$data)
#'     remaining <- remaining[-idx]
#'   }
#'   }
#'
#' @seealso [call_mirai()]
#'
#' @examplesIf interactive()
#' daemons(2)
#' m1 <- mirai({ Sys.sleep(0.2); "one" })
#' m2 <- mirai({ Sys.sleep(0.1); "two" })
#' m3 <- mirai({ Sys.sleep(0.3); "three" })
#' remaining <- list(m1, m2, m3)
#' while (length(remaining) > 0) {
#'   idx <- race_mirai(remaining)
#'   print(remaining[[idx]]$data)
#'   remaining <- remaining[-idx]
#' }
#' daemons(0)
#'
#' @export
#'
race_mirai <- function(x, .compute = NULL) {
  envir <- compute_env(.compute)
  is.null(envir) && stop(._[["daemons_unset"]])
  invisible(race_aio(x, envir[["cv"]]))
}

#' mirai (Collect Value)
#'
#' Waits for the 'mirai' to resolve if still in progress (blocking but
#' interruptible) and returns its value directly. Equivalent to
#' `call_mirai(x)$data`.
#'
#' `x[]` is an equivalent way to wait for and return the value of a mirai `x`.
#'
#' @inheritParams call_mirai
#' @param options (character) collection options for list input, e.g. `".flat"`
#'   or `c(".progress", ".stop")`. See Options section.
#'
#' @return An object (the return value of the 'mirai'), or a list of such
#'   objects (the same length as `x`, preserving names).
#'
#' @section Options:
#'
#' A named list may also be supplied instead of a character vector, where the
#' names are the collection options. The value for `.progress` is passed to the
#' cli progress bar: a character value sets the bar name, and a list is passed
#' as named parameters to `cli::cli_progress_bar`. Examples:
#' `c(.stop = TRUE, .progress = "bar name")` or
#' `list(.stop = TRUE, .progress = list(name = "bar", type = "tasks"))`
#'
#' @inheritSection call_mirai Alternatively
#' @inheritSection mirai Errors
#'
#' @examplesIf interactive()
#' # using collect_mirai()
#' df1 <- data.frame(a = 1, b = 2)
#' df2 <- data.frame(a = 3, b = 1)
#' m <- mirai(as.matrix(rbind(df1, df2)), df1 = df1, df2 = df2, .timeout = 1000)
#' collect_mirai(m)
#'
#' # using x[]
#' m[]
#'
#' # mirai_map with collection options
#' daemons(1, dispatcher = FALSE)
#' m <- mirai_map(1:3, rnorm)
#' collect_mirai(m, c(".flat", ".progress"))
#' daemons(0)
#'
#' @export
#'
collect_mirai <- function(x, options = NULL) {
  is.list(x) && length(options) || return(collect_aio_(x))

  if (length(names(options))) {
    `[[<-`(., "progress", options[[".progress"]])
    options <- names(options)
  }
  dots <- mget(options, envir = .opts)
  mmap(x, dots)
}

#' mirai (Stop)
#'
#' Stops a 'mirai' if still in progress, causing it to resolve immediately to an
#' 'errorValue' 20 (Operation canceled).
#'
#' Cancellation requires dispatcher. If the 'mirai' is awaiting execution, it
#' is discarded from the queue and never evaluated. If already executing, an
#' interrupt is sent.
#'
#' A cancellation request does not guarantee the task stops: it may have already
#' completed before the interrupt is received, and compiled code is not always
#' interruptible. Take care if the code performs side effects such as writing to
#' files.
#'
#' @inheritParams call_mirai
#'
#' @return Logical TRUE if the cancellation request was successful (was awaiting
#'   execution or in execution), or else FALSE (if already completed or
#'   previously cancelled). Will always return FALSE if not using dispatcher.
#'
#'   **Or** a vector of logical values if supplying a list of 'mirai', such as
#'   those returned by [mirai_map()].
#'
#' @examplesIf interactive()
#' m <- mirai(Sys.sleep(n), n = 5)
#' stop_mirai(m)
#' m$data
#'
#' @export
#'
stop_mirai <- stop_request

#' Query if a mirai is Unresolved
#'
#' Query whether a 'mirai', 'mirai' value or list of 'mirai' remains unresolved.
#' Unlike [call_mirai()], this function does not wait for completion.
#'
#' Suitable for use in control flow statements such as `while` or `if`.
#'
#' @param x (mirai | list | mirai value) a 'mirai', list of 'mirai' objects, or
#'   value from `$data`.
#'
#' @return Logical TRUE if `x` is an unresolved 'mirai' or 'mirai' value or the
#'   list contains at least one unresolved 'mirai', or FALSE otherwise.
#'
#' @examplesIf interactive()
#' m <- mirai(Sys.sleep(0.1))
#' unresolved(m)
#' Sys.sleep(0.3)
#' unresolved(m)
#'
#' @export
#'
unresolved <- unresolved

#' Is mirai / mirai_map
#'
#' Is the object a 'mirai' or 'mirai_map'.
#'
#' @param x (object) to test.
#'
#' @return Logical TRUE if `x` is of class 'mirai' or 'mirai_map' respectively,
#'   FALSE otherwise.
#'
#' @examplesIf interactive()
#' daemons(1, dispatcher = FALSE)
#' df <- data.frame()
#' m <- mirai(as.matrix(df), df = df)
#' is_mirai(m)
#' is_mirai(df)
#'
#' mp <- mirai_map(1:3, runif)
#' is_mirai_map(mp)
#' is_mirai_map(mp[])
#' daemons(0)
#'
#' @export
#'
is_mirai <- function(x) inherits(x, "mirai")

#' @rdname is_mirai
#' @export
#'
is_mirai_map <- function(x) inherits(x, "mirai_map")

#' Error Validators
#'
#' Validator functions for error value types created by \pkg{mirai}.
#'
#' Is the object a 'miraiError'. When execution in a 'mirai' process fails, the
#' error message is returned as a character string of class 'miraiError' and
#' 'errorValue'. The elements of the original condition are accessible via `$`
#' on the error object. A stack trace is also available at `$stack.trace`.
#'
#' Is the object a 'miraiInterrupt'. When an ongoing 'mirai' is sent a user
#' interrupt, it will resolve to an empty character string classed as
#' 'miraiInterrupt' and 'errorValue'.
#'
#' Is the object an 'errorValue', such as a 'mirai' timeout, a 'miraiError' or a
#' 'miraiInterrupt'. This is a catch-all condition that includes all returned
#' error values.
#'
#' @param x (object) to test.
#'
#' @return Logical value TRUE or FALSE.
#'
#' @examplesIf interactive()
#' m <- mirai(stop())
#' call_mirai(m)
#' is_mirai_error(m$data)
#' is_mirai_interrupt(m$data)
#' is_error_value(m$data)
#' m$data$stack.trace
#'
#' m2 <- mirai(Sys.sleep(1L), .timeout = 100)
#' call_mirai(m2)
#' is_mirai_error(m2$data)
#' is_mirai_interrupt(m2$data)
#' is_error_value(m2$data)
#'
#' @export
#'
is_mirai_error <- function(x) inherits(x, "miraiError")

#' @rdname is_mirai_error
#' @export
#'
is_mirai_interrupt <- function(x) inherits(x, "miraiInterrupt")

#' @rdname is_mirai_error
#' @export
#'
is_error_value <- is_error_value

#' On Daemon
#'
#' Returns a logical value, whether or not evaluation is taking place within a
#' mirai call on a daemon.
#'
#' @return Logical `TRUE` or `FALSE`.
#'
#' @examplesIf interactive()
#' on_daemon()
#' mirai(mirai::on_daemon())[]
#'
#' @export
#'
on_daemon <- function() !is.null(.[["sock"]])

# methods ----------------------------------------------------------------------

#' @export
#'
`[.mirai` <- function(x, i) collect_aio_(x)

#' @export
#'
print.mirai <- function(x, ...) {
  cat(if (.unresolved(x)) "< mirai [] >\n" else "< mirai [$data] >\n", file = stdout())
  invisible(x)
}

#' @export
#'
print.miraiError <- function(x, ...) {
  cat(sprintf("'miraiError' chr %s\n", x), file = stdout())
  invisible(x)
}

#' @export
#'
print.miraiInterrupt <- function(x, ...) {
  cat("'miraiInterrupt' chr \"\"\n", file = stdout())
  invisible(x)
}

#' @export
#'
`$.miraiError` <- function(x, name) attr(x, name, exact = TRUE)

#' @exportS3Method utils::.DollarNames
#'
.DollarNames.miraiError <- function(x, pattern = "") {
  grep(pattern, names(attributes(x)), value = TRUE, fixed = TRUE)
}

#' @export
#'
conditionCall.miraiError <- function(c) attr(c, "call")

#' @export
#'
conditionMessage.miraiError <- function(c) attr(c, "message")

# internals --------------------------------------------------------------------

ephemeral_daemon <- function(data, timeout) {
  url <- local_url()
  sock <- req_socket(url)
  system2(
    .command,
    args = c("-e", shQuote(sprintf("mirai:::.daemon(\"%s\")", url))),
    stdout = FALSE,
    stderr = FALSE,
    wait = FALSE
  )
  req <- request(.context(sock), data, send_mode = 1L, recv_mode = 1L, timeout = timeout)
  `attr<-`(.subset2(req, "aio"), "sock", sock)
  invisible(req)
}

evaluate_sync <- function(envir) {
  ge <- as.list.environment(globalenv(), all.names = TRUE)
  rm(list = names(globalenv()), envir = globalenv())
  if (!is.null(envir[["ge"]])) {
    list2env(envir[["ge"]], envir = globalenv())
  }
  on.exit({
    do_cleanup()
    `[[<-`(envir, "ge", as.list.environment(globalenv(), all.names = TRUE))
    rm(list = names(globalenv()), envir = globalenv())
    list2env(ge, envir = globalenv())
  })
  daemon(url = envir[["url"]], autoexit = FALSE, dispatcher = FALSE, output = TRUE, maxtasks = 1L)
}

deparse_safe <- function(x) {
  length(x) || return()
  deparse(x, width.cutoff = 500L, backtick = TRUE, control = NULL, nlines = 1L)
}

mk_mirai_interrupt <- function() `class<-`("", c("miraiInterrupt", "errorValue", "try-error"))

mk_mirai_error <- function(cnd) {
  sc <- .[["syscalls"]]
  `[[<-`(., "syscalls", NULL)
  eval_call <- "eval(._mirai_.[[\"._expr_.\"]], envir = ._mirai_., enclos = globalenv())"
  cnd[["condition.class"]] <- class(cnd)
  cnd[["call"]] <- `attributes<-`(.subset2(cnd, "call"), NULL)
  call <- deparse_safe(.subset2(cnd, "call"))
  msg <- if (is.null(call) || call == eval_call) {
    sprintf("Error: %s", .subset2(cnd, "message"))
  } else {
    sprintf("Error in %s: %s", call, .subset2(cnd, "message"))
  }
  idx <- max(which(as.logical(lapply(sc, `==`, eval_call))))
  sc <- sc[(length(sc) - 1L):(idx + 1L)]
  if (sc[[1L]][[1L]] == ".handleSimpleError") {
    sc <- sc[-1L]
  }
  cnd[["stack.trace"]] <- lapply(sc, `attributes<-`, NULL)
  `class<-`(`attributes<-`(msg, cnd), c("miraiError", "errorValue", "try-error"))
}

.connReset <- serialize(`class<-`(19L, c("errorValue", "try-error")), NULL)
.snapshot <- expression(on.exit(mirai:::snapshot(), add = TRUE))
