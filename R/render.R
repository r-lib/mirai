# mirai ------------------------------------------------------------------------

#' Evaluate Rendered Code Chunks on Daemons
#'
#' Registers mirai as the evaluation executor for chunk routing in \pkg{knitr}
#' and \pkg{litedown} documents (including R Markdown and Quarto). Chunks
#' tagged with a `compute` chunk option then evaluate on a mirai daemon
#' instead of in the host session. Use this to run selected chunks on parallel
#' or remote daemons.
#'
#' Before rendering, set up daemons for each compute profile with [daemons()].
#' Then call `register_render()` once, typically in a setup chunk. For each R
#' code chunk:
#'
#' - `#| compute: gpu` evaluates the chunk on the `"gpu"` compute profile.
#' - `#| compute: true` evaluates the chunk on the `"default"` profile.
#' - An untagged chunk evaluates in the host session, unchanged.
#'
#' Registration sets `options(compute.executor = ...)`. The renderers consult
#' this option at each tagged chunk. No renderer package is attached or
#' modified. To unregister, set `options(compute.executor = NULL)`.
#'
#' Use a **single daemon with `cleanup = FALSE`** for each routing profile,
#' for example `daemons(1, .compute = "gpu", cleanup = FALSE)`. This mirrors
#' the usual rendering session: `cleanup = FALSE` preserves the daemon's
#' global environment between chunks, so objects created in one chunk are
#' visible in later chunks on the same profile. A single daemon keeps those
#' chunks in the same process. Chunks on different profiles, and the host
#' session, remain isolated from one another. Inline R code always evaluates
#' in the host session.
#'
#' Each daemon of a routed profile needs the renderer package installed:
#' \pkg{knitr} for \pkg{knitr} documents, or \pkg{litedown} for \pkg{litedown}
#' documents. Use the same version as on the host. The executor checks for
#' the renderer package before it sends the
#' first chunk to a daemon, and fails with an informative error if it is
#' missing. For \pkg{knitr} chunks that plot, use the same R version on host
#' and daemon: recorded plots are not portable across R or graphics engine
#' versions.
#'
#' You can call `register_render()` more than once. It warns if a different
#' executor is already registered. Each call resets the per-profile daemon
#' checks, so they run again on the next routed chunk (for example after a
#' mid-session `daemons(0)`).
#'
#' @return Invisible NULL. Called for the side effect of registering the
#'   executor.
#'
#' @examples
#' \dontrun{
#' # in a setup chunk of a knitr / R Markdown / Quarto / litedown document:
#' library(mirai)
#' daemons(1, .compute = "gpu", cleanup = FALSE)
#' register_render()
#' }
#'
#' @export
#'
register_render <- function() {
  has_knitr <- requireNamespace("knitr", quietly = TRUE)
  has_litedown <- requireNamespace("litedown", quietly = TRUE)
  # Feature detection, not version numbers: a renderer that is too old
  # ignores the `compute` chunk option silently (unknown options are not
  # validated), so tagged chunks evaluate locally with no hint. Detecting the
  # worker half works against renderer dev installs, where no "first
  # supporting release" version exists yet. The marker names are
  # contract-adjacent internals. Confirm them against the merged renderers at
  # release time.
  ok_knitr <- has_knitr &&
    is.function(get0("eng_r_remote", envir = asNamespace("knitr"), inherits = FALSE))
  ok_litedown <- has_litedown &&
    is.function(get0("record_remote", envir = asNamespace("litedown"), inherits = FALSE))
  # A renderer that is too old warns rather than errors. Hard error only when
  # nothing qualifies.
  if (has_knitr && !ok_knitr)
    warning(
      "the installed knitr does not support chunk routing; tagged chunks will evaluate locally",
      call. = FALSE
    )
  if (has_litedown && !ok_litedown)
    warning(
      "the installed litedown does not support chunk routing; tagged chunks will evaluate locally",
      call. = FALSE
    )
  (ok_knitr || ok_litedown) ||
    stop("requires a knitr or litedown version that supports chunk routing", call. = FALSE)
  ex <- getOption("compute.executor")
  if (!is.null(ex) && !identical(ex, render_executor))
    warning("overwriting an existing 'compute.executor' registration", call. = FALSE)
  # a fresh registration re-runs the per-profile checks (multi-daemon warning,
  # namespace probe). Reset in place: the namespace bindings are locked, so
  # `checked <<- new.env()` errors.
  rm(list = names(checked), envir = checked)
  rm(list = names(probed), envir = probed)
  options(compute.executor = render_executor)
  invisible()
}

# The executor: call `fun` with `args` on a daemon of `profile` and return the
# value, or raise. require_daemons() is load-bearing: mirai() on an unset
# profile launches an ephemeral daemon and silently defeats state persistence.
# `.args` (not `...`) so `fun` / `args` do not persist in the daemon's global
# env.
render_executor <- function(fun, args, profile) {
  require_daemons(.compute = profile)
  check_single_daemon(profile)
  # Probe for the renderer package on the daemon once per (profile,
  # namespace). Without it, the worker half fails with an opaque error
  # (`could not find function`, see check_daemon_namespace below). Skipped for
  # primitives and globalenv functions (test executors, ad-hoc closures).
  env <- environment(fun)
  ns <- if (is.null(env)) "" else environmentName(env)
  if (nzchar(ns) && ns != "R_GlobalEnv") check_daemon_namespace(ns, profile)
  res <- mirai(do.call(fun, args), .args = list(fun = fun, args = args), .compute = profile)[]
  if (is_mirai_error(res)) {
    # re-raise with the daemon-side condition class and call, so tryCatch
    # handlers and `error: false` semantics see the original condition
    stop(
      errorCondition(
        conditionMessage(res),
        class = setdiff(res$condition.class, c("error", "condition")),
        call = conditionCall(res)
      )
    )
  }
  if (is_mirai_interrupt(res)) {
    stop("chunk evaluation was cancelled (stop_mirai)", call. = FALSE)
  }
  if (is_error_value(res)) {
    # infrastructure failures arrive as integer errorValues (daemon died: 19).
    # as.character() on these yields just the bare code — use nng_error().
    stop(nng_error(res), call. = FALSE)
  }
  res
}

# Cross-chunk state on a profile requires a single daemon: with more than one,
# chunks silently alternate processes and state goes missing. cleanup = FALSE
# cannot be inspected remotely, so it stays a documented requirement.
# `checked` is a package-level env, reset in place by register_render(), so
# this warns once per profile per registration. Re-launching daemons
# mid-session re-warns.
checked <- new.env()

check_single_daemon <- function(profile) {
  # NULL means the current profile, as it does for require_daemons() and mirai()
  key <- if (is.null(profile)) .[["cp"]] else profile
  is.null(checked[[key]]) || return()
  # sync daemons evaluate in the host process: no connections, and the
  # single-daemon requirement is vacuous. This is the configuration the
  # renderer test suites use, so it must not warn.
  if (isTRUE(compute_env(profile)[["sync"]])) {
    checked[[key]] <- TRUE
    return()
  }
  n <- status(.compute = profile)[["connections"]]
  # daemons(url = ...) returns before remote daemons connect, so zero means
  # "not yet", not "misconfigured": leave the profile unchecked and look again
  # on the next routed chunk. mirai() itself blocks until a daemon connects.
  n == 0L && return()
  checked[[key]] <- TRUE
  if (!identical(n, 1L)) warning(sprintf(
    "compute profile '%s' has %d daemons; chunk routing requires a single daemon with cleanup = FALSE",
    key, n
  ), call. = FALSE)
}

# A daemon missing the renderer package does not error on unserialize: R
# silently substitutes `.GlobalEnv` for the absent namespace, so the worker
# half fails with an opaque error (`could not find function "reset_fig_alt"`).
# The namespace of the routed `fun` names the package the daemon needs: probe
# it once per (profile, namespace) per registration — one round-trip — and
# fail here with a clear message instead. Sync profiles probe the host
# process, where the renderer is present by construction. On a
# zero-connection `daemons(url = ...)` profile, the probe blocks until a
# daemon connects, as the chunk call itself does. `probed` is reset in place
# by register_render(), so re-launching daemons mid-session re-probes.
probed <- new.env()

check_daemon_namespace <- function(ns, profile) {
  key <- paste0(if (is.null(profile)) .[["cp"]] else profile, "\r", ns)
  is.null(probed[[key]]) || return()
  has <- mirai(
    requireNamespace(ns, quietly = TRUE),
    .args = list(ns = ns), .compute = profile
  )[]
  if (is_mirai_error(has)) stop(has)
  if (is_error_value(has)) stop(nng_error(has), call. = FALSE)
  isTRUE(has) || stop(sprintf(
    "compute profile '%s' daemon does not have the '%s' package installed; install it there to evaluate routed chunks",
    if (is.null(profile)) .[["cp"]] else profile, ns
  ), call. = FALSE)
  probed[[key]] <- TRUE
}
