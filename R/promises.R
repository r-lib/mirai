# mirai.promises ---------------------------------------------------------------

# Joe Cheng (3 Apr 2024):
#
# We are going through some effort here to ensure that any error we raise here
# has "deep stacks" preserved while run in a Shiny app. For this to happen, we
# either need to raise the error while the `as.promise.mirai` call is still on
# the call stack, or, we are within an `onFulfilled` or `onRejected` callback
# from a `promises::then` call (assuming that `then()` was called while
# `as.promise.mirai` was still on the call stack).
#
# The only way we would violate those rules is by raising the error from
# within a `later::later` callback. So this code is factored to isolate that
# `later::later` code

#' Make mirai Promise
#'
#' Creates a 'promise' from a 'mirai'. S3 method for `promises::as.promise()`.
#'
#' Allows a 'mirai' to be used with the promise pipe `%...>%`, scheduling a
#' function to run upon resolution.
#'
#' Requires the \pkg{promises} package.
#'
#' @param x (mirai) object to convert to promise.
#'
#' @return A 'promise' object.
#'
#' @examplesIf interactive() && requireNamespace("promises", quietly = TRUE)
#' library(promises)
#'
#' p <- as.promise(mirai("example"))
#' print(p)
#' is.promise(p)
#'
#' p2 <- mirai("completed") %...>% identity()
#' p2$then(cat)
#' is.promise(p2)
#'
#' @exportS3Method promises::as.promise
#'
as.promise.mirai <- function(x) {
  promise <- .subset2(x, "promise")

  if (is.null(promise)) {
    promise <- promises::promise(function(resolve, reject) {
      if (unresolved(x)) .keep(x, environment()) else resolve(.subset2(x, "value"))
    })$then(onFulfilled = handle_fulfilled)
    `[[<-`(x, "promise", promise)
  }

  promise
}

handle_fulfilled <- function(value, .visible) {
  is_error_value(value) &&
    !is_mirai_interrupt(value) &&
    stop(if (is_mirai_error(value)) value else nng_error(value))
  value
}

#' Make mirai_map Promise
#'
#' Creates a 'promise' from a 'mirai_map'. S3 method for
#' `promises::as.promise()`.
#'
#' Allows a 'mirai_map' to be used with the promise pipe `%...>%`, scheduling a
#' function to run upon resolution of all mirai.
#'
#' Uses `promises::promise_all()` internally: resolves to a list of values if
#' all succeed, or rejects with the first error encountered.
#'
#' Requires the \pkg{promises} package.
#'
#' @param x (mirai_map) object to convert to promise.
#'
#' @return A 'promise' object.
#'
#' @examplesIf interactive() && requireNamespace("promises", quietly = TRUE)
#' library(promises)
#'
#' with(daemons(1), {
#'   mp <- mirai_map(1:3, function(x) { Sys.sleep(1); x })
#'   p <- as.promise(mp)
#'   print(p)
#'   p %...>% print
#'   mp[.flat]
#' })
#'
#' @exportS3Method promises::as.promise
#'
as.promise.mirai_map <- function(x) {
  promise <- attr(x, "promise")

  if (is.null(promise)) {
    attr(x, "promise") <- promises::promise_all(.list = x) -> promise
  }

  promise
}

#' @exportS3Method promises::is.promising
#'
is.promising.mirai <- function(x) TRUE

#' @exportS3Method promises::is.promising
#'
is.promising.mirai_map <- function(x) TRUE
