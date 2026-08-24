# mirai ------------------------------------------------------------------------

#' Evaluate Rendered Code Chunks on Daemons
#'
#' Registers a hook with \pkg{knitr} and/or \pkg{litedown} so that R code chunks
#' tagged with a `compute` chunk option are evaluated on a mirai daemon rather
#' than in the host session. This provides a lightweight way to run selected
#' chunks of a \pkg{knitr}, R Markdown, Quarto or \pkg{litedown} document on
#' parallel or remote daemons. The same interface serves both renderers: each
#' delegates chunk evaluation to [daemon_call()].
#'
#' Set up daemons for one or more compute profiles using [daemons()] before
#' rendering, then call `register_render()` once, typically in a setup chunk.
#' Thereafter, for each R code chunk:
#'
#' - `#| compute: gpu` evaluates the chunk on the `"gpu"` compute profile.
#' - `#| compute: true` evaluates the chunk on the `"default"` profile.
#' - An untagged chunk evaluates in the host session, unchanged.
#'
#' A profile used for chunk routing should consist of a **single daemon set
#' with `cleanup = FALSE`**, for example `daemons(1, .compute = "gpu", cleanup =
#' FALSE)`. This mirrors the usual rendering session: `cleanup = FALSE`
#' preserves the daemon's global environment between chunks so that objects
#' created in one chunk are visible in later chunks on the same profile, and a
#' single daemon ensures those chunks all evaluate in the same process. Chunks
#' on different profiles, and the host session, remain isolated from one
#' another. Inline R code always evaluates in the host session.
#'
#' Each daemon of a routed profile requires the relevant rendering packages
#' installed: \pkg{knitr} and \pkg{evaluate} for \pkg{knitr} documents, or
#' \pkg{xfun} for \pkg{litedown} documents. \pkg{knitr} is loaded on the
#' daemons of a profile the first time a chunk is routed there.
#'
#' Calling `register_render()` more than once is safe: it does not re-wrap its
#' own hooks, and each call resets the record of which profiles have been
#' prepared, so a fresh render re-loads packages on the daemons as needed. If
#' daemons are reset with `daemons(0)` mid-render, call `register_render()`
#' again so the replacement daemons are re-prepared.
#'
#' @section Figures:
#'
#' Under \pkg{knitr}, graphics produced on a daemon are recorded and replayed on
#' the host device, so figures are written as usual regardless of daemon
#' location. Under \pkg{litedown}, figures are written to files by the daemon;
#' this requires a daemon sharing the host filesystem (i.e. **local** daemons),
#' since the files are placed directly in the document's figure directory.
#' Chunks that only produce console output are unaffected.
#'
#' @return Invisible NULL. Called for the side effect of installing the hooks.
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
  has_knitr ||
    has_litedown ||
    stop(
      "either package 'knitr' or 'litedown' is required to register a rendering hook",
      call. = FALSE
    )

  # Profiles whose daemons have been prepared (knitr namespace loaded). A fresh
  # env per registration means a new render re-prepares its profiles.
  prepared <- new.env()

  if (has_knitr) {
    register_knitr_hook(prepared)
  }
  if (has_litedown) {
    register_litedown_engine()
  }

  invisible()
}

# internals --------------------------------------------------------------------

# Resolve a `compute` chunk option to a compute profile name, or NULL when the
# chunk is untagged (and should evaluate in the host session).
route_compute <- function(opt) {
  if (isTRUE(opt)) {
    "default"
  } else if (is.character(opt) && length(opt) == 1L && nzchar(opt)) {
    opt
  }
}

# Fetch a hook/engine's preserved original, so re-registration does not re-wrap.
mirai_orig <- function(current) {
  orig <- attr(current, "mirai_orig", exact = TRUE)
  if (is.null(orig)) current else orig
}

register_knitr_hook <- function(prepared) {
  orig <- mirai_orig(knitr::knit_hooks$get("evaluate"))

  hook <- function(code, envir, ...) {
    profile <- route_compute(knitr::opts_current$get("compute"))
    # Untagged chunk: evaluate in the host session, unchanged.
    if (is.null(profile)) {
      return(orig(code, envir, ...))
    }
    if (is.null(prepared[[profile]])) {
      # Load knitr's namespace on the daemon(s) so the output handler forwarded
      # with each chunk (a set of knitr closures) resolves there.
      everywhere(loadNamespace("knitr"), .compute = profile)
      prepared[[profile]] <- TRUE
    }
    # new_device = TRUE so the daemon opens its own graphics device and records
    # plots; the recordedplot objects returned are replayed on the host device.
    extra <- list(...)
    extra[["new_device"]] <- TRUE
    do.call(daemon_call, c(list(evaluate::evaluate, code), extra, list(.compute = profile)))
  }
  attr(hook, "mirai_orig") <- orig

  knitr::knit_hooks$set(evaluate = hook)
}

register_litedown_engine <- function() {
  orig <- mirai_orig(litedown::engines("r"))

  engine <- function(x, inline = FALSE, ...) {
    profile <- route_compute(litedown::reactor("compute"))
    # Inline code and untagged chunks evaluate in the host session, unchanged.
    if (inline || is.null(profile)) {
      return(orig(x, inline = inline, ...))
    }
    # Record the chunk on the daemon via xfun::record(), forwarding the chunk
    # options that affect evaluation and plot recording. Figures are written to
    # an absolute path so a local daemon places them in the document's figure
    # directory; the returned records are formatted by litedown on the host.
    fig <- litedown::reactor("fig.path")
    args <- drop_null(list(
      code = x$source,
      dev = litedown::reactor("dev"),
      dev.path = if (is.character(fig)) {
        normalizePath(paste0(fig, litedown::reactor("label")), mustWork = FALSE)
      },
      dev.ext = litedown::reactor("fig.ext"),
      dev.keep = litedown::reactor("fig.keep"),
      dev.args = litedown_dev_args(),
      error = litedown::reactor("error"),
      warning = litedown::reactor("warning"),
      message = litedown::reactor("message")
    ))
    do.call(daemon_call, c(list(xfun::record), args, list(.compute = profile)))
  }
  attr(engine, "mirai_orig") <- orig

  litedown::engines(r = engine)
}

# Assemble the `dev.args` for xfun::record() from litedown chunk options,
# merging figure dimensions (user-supplied dev.args take precedence).
litedown_dev_args <- function() {
  dm <- litedown::reactor("fig.dim")
  size <- if (length(dm) == 2L) {
    list(width = dm[[1L]], height = dm[[2L]])
  } else {
    list(width = litedown::reactor("fig.width"), height = litedown::reactor("fig.height"))
  }
  dev.args <- litedown::reactor("dev.args")
  size <- drop_null(size[setdiff(names(size), names(dev.args))])
  args <- c(dev.args, size)
  if (length(args)) args
}

drop_null <- function(x) x[!vapply(x, is.null, logical(1L))]
