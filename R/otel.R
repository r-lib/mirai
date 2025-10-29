otel_tracer_name <- "org.r-lib.mirai"
otel_is_tracing <- FALSE
otel_tracer <- NULL

otel_cache_tracer = function() {
  requireNamespace("otel", quietly = TRUE) || return()
  otel_tracer <<- otel::get_tracer(otel_tracer_name)
  otel_is_tracing <<- tracer_enabled(otel_tracer)
}

otel_refresh_tracer <- function(pkgname) {
  requireNamespace("otel", quietly = TRUE) || return()
  ns <- getNamespace(pkgname)
  do.call(unlockBinding, list("otel_is_tracing", ns))
  do.call(unlockBinding, list("otel_tracer", ns))
  otel_tracer <- otel::get_tracer()
  `[[<-`(ns, "otel_is_tracing", tracer_enabled(otel_tracer))
  `[[<-`(ns, "otel_tracer", otel_tracer)
  lockBinding("otel_is_tracing", ns)
  lockBinding("otel_tracer", ns)
}

tracer_enabled <- function(tracer) {
  .subset2(tracer, "is_enabled")()
}

otel_local_map_span <- function(span, scope = parent.frame()) {
  otel_is_tracing || return()
  otel::start_local_active_span(
    "mirai_map",
    links = list(daemons = span),
    tracer = otel_tracer,
    activation_scope = scope
  )
}

otel_local_mirai_ctx_span <- function(envir, scope = parent.frame()) {
  otel_is_tracing && length(envir) || return()
  spn <- otel::start_local_active_span(
    "mirai",
    links = list(daemons = envir[["otel_span"]]),
    options = list(kind = "client"),
    tracer = otel_tracer,
    activation_scope = scope
  )
  ctx <- otel::pack_http_context()
  list(ctx, spn)
}

otel_set_span_id <- function(span, id) {
  otel_is_tracing && length(span) || return()
  span$set_attribute("mirai.id", id)
}

otel_local_eval_span <- function(ctx, span, scope = parent.frame()) {
  otel_is_tracing && length(ctx) || return()
  otel::start_local_active_span(
    "daemon eval",
    links = list(daemon = span),
    options = list(kind = "server", parent = otel::extract_http_context(ctx)),
    tracer = otel_tracer,
    activation_scope = scope
  )
}

otel_set_span_error <- function(span, type) {
  otel_is_tracing && length(span) || return()
  span$set_status("error", type)
}

otel_daemon_span <- function(url, span = NULL) {
  otel_is_tracing || return()
  purl <- parse_url(url)
  otel::start_local_active_span(
    sprintf("daemon %s %s", if (is.null(span)) "connect" else "disconnect", url),
    attributes = otel::as_attributes(list(
      server.address = if (nzchar(purl[["hostname"]])) purl[["hostname"]] else purl[["path"]],
      server.port = purl[["port"]],
      network.transport = purl[["scheme"]]
    )),
    links = if (length(span)) list(daemon = span),
    tracer = otel_tracer
  )
}

otel_daemons_span <- function(envir, reset = FALSE) {
  otel_is_tracing || return()
  url <- envir[["url"]]
  purl <- parse_url(url)
  otel::start_local_active_span(
    sprintf("daemons %s %s",if (reset) "reset" else "set", url),
    attributes = list(
      server.address = if (nzchar(purl[["hostname"]])) purl[["hostname"]] else purl[["path"]],
      server.port = purl[["port"]],
      network.transport = purl[["scheme"]],
      mirai.n = envir[["n"]],
      mirai.dispatcher = !is.null(envir[["dispatcher"]]),
      mirai.compute = envir[["compute"]]
    ),
    links = if (reset) list(daemons = envir[["otel_span"]]),
    tracer = otel_tracer
  )
}
