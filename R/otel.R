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

otel_active_span <- function(
  name,
  cond = TRUE,
  attributes = list(),
  links = NULL,
  options = NULL,
  return_ctx = FALSE,
  scope = environment()
) {
  otel_is_tracing && cond || return()
  spn <- otel::start_local_active_span(
    name,
    attributes = otel::as_attributes(attributes),
    links = links,
    options = options,
    tracer = otel_tracer,
    activation_scope = scope
  )
  return_ctx && return(list(otel::pack_http_context(), spn))
  spn
}

otel_set_span_id <- function(span, id) {
  otel_is_tracing || return()
  span$set_attribute("mirai.id", id)
}

otel_set_span_error <- function(span, type) {
  otel_is_tracing && length(span) || return()
  span$set_status("error", type)
}

make_daemon_attrs <- function(url) {
  purl <- parse_url(url)
  list(
    server.address = if (nzchar(purl[["hostname"]])) purl[["hostname"]] else purl[["path"]],
    server.port = if (nzchar(purl[["port"]])) as.integer(purl[["port"]]) else integer(),
    network.transport = purl[["scheme"]]
  )
}

make_daemons_attrs <- function(envir) {
  purl <- parse_url(envir[["url"]])
  list(
    server.address = if (nzchar(purl[["hostname"]])) purl[["hostname"]] else purl[["path"]],
    server.port = if (nzchar(purl[["port"]])) as.integer(purl[["port"]]) else integer(),
    network.transport = purl[["scheme"]],
    mirai.n = envir[["n"]],
    mirai.dispatcher = !is.null(envir[["dispatcher"]]),
    mirai.compute = envir[["compute"]]
  )
}
