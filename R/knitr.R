# mirai ------------------------------------------------------------------------

#' Evaluate knitr Chunks on Daemons
#'
#' Registers a \pkg{knitr} `evaluate` hook so that R code chunks tagged with a
#' `compute` chunk option are evaluated on a mirai daemon rather than in the
#' host session. This provides a lightweight way to run selected chunks of a
#' \pkg{knitr}, R Markdown or Quarto document on parallel or remote daemons.
#'
#' Set up daemons for one or more compute profiles using [daemons()] before
#' rendering, then call `register_knitr()` once, typically in a setup chunk.
#' Thereafter, for each R code chunk:
#'
#' - `#| compute: gpu` evaluates the chunk on the `"gpu"` compute profile.
#' - `#| compute: true` evaluates the chunk on the `"default"` profile.
#' - An untagged chunk evaluates in the host session, unchanged.
#'
#' A profile used for chunk routing should consist of a **single daemon set
#' with `cleanup = FALSE`**, for example `daemons(1, .compute = "gpu", cleanup =
#' FALSE)`. This mirrors the usual knitr session: `cleanup = FALSE` preserves
#' the daemon's global environment between chunks so that objects created in one
#' chunk are visible in later chunks on the same profile, and a single daemon
#' ensures those chunks all evaluate in the same process. Chunks on different
#' profiles, and the host session, remain isolated from one another. Inline R
#' code always evaluates in the host session.
#'
#' \pkg{knitr} is loaded on the daemons of a profile the first time a chunk is
#' routed there, hence each such daemon requires \pkg{knitr} and \pkg{evaluate}
#' to be installed. Graphics produced on a daemon are recorded and replayed on
#' the host, so figures are written as usual.
#'
#' Calling `register_knitr()` more than once is safe: it does not re-wrap its
#' own hook, and each call resets the record of which profiles have been
#' prepared, so a fresh render re-loads \pkg{knitr} on the daemons as needed.
#'
#' @return Invisible NULL. Called for the side effect of installing the hook.
#'
#' @examples
#' \dontrun{
#' # in a setup chunk of a knitr / R Markdown / Quarto document:
#' library(mirai)
#' daemons(1, .compute = "gpu", cleanup = FALSE)
#' register_knitr()
#' }
#'
#' @export
#'
register_knitr <- function() {
  requireNamespace("knitr", quietly = TRUE) ||
    stop("package 'knitr' is required to register the knitr hook", call. = FALSE)

  # Profiles whose daemons have had knitr loaded. A fresh env per registration
  # means a new render re-prepares its profiles from scratch.
  prepared <- new.env()

  # Preserve, but do not re-wrap, any existing 'evaluate' hook.
  current <- knitr::knit_hooks$get("evaluate")
  orig <- attr(current, "mirai_orig", exact = TRUE)
  if (is.null(orig)) {
    orig <- current
  }

  hook <- function(code, envir, ...) {
    opt <- knitr::opts_current$get("compute")
    profile <- if (isTRUE(opt)) {
      "default"
    } else if (is.character(opt) && nzchar(opt)) {
      opt
    }
    # Untagged chunk: evaluate in the host session, unchanged.
    if (is.null(profile)) {
      return(orig(code, envir, ...))
    }
    daemons_set(.compute = profile) ||
      stop(
        sprintf(
          "no daemons set for compute profile '%s'; call daemons(.compute = \"%s\") first",
          profile,
          profile
        ),
        call. = FALSE
      )
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
    mirai(
      do.call(evaluate::evaluate, c(list(code, envir = globalenv()), extra)),
      code = code,
      extra = extra,
      .compute = profile
    )[]
  }
  attr(hook, "mirai_orig") <- orig

  knitr::knit_hooks$set(evaluate = hook)
  invisible()
}
