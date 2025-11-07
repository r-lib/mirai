otel_tracer_name <- "org.r-lib.mirai"
otel_is_tracing <- FALSE
otel_tracer <- NULL

# generic otel helpers ---------------------------------------------------------

# nocov start
# tested implicitly on package load

otel_cache_tracer <- function() {
  requireNamespace("otel", quietly = TRUE) || return()
  otel_tracer <<- otel::get_tracer(otel_tracer_name)
  otel_is_tracing <<- tracer_enabled(otel_tracer)
}

# nocov end

tracer_enabled <- function(tracer) {
  .subset2(tracer, "is_enabled")()
}

otel_refresh_tracer <- function() {
  requireNamespace("otel", quietly = TRUE) || return()
  tracer <- otel::get_tracer()
  modify_binding(
    topenv(),
    list(otel_tracer = tracer, otel_is_tracing = tracer_enabled(tracer))
  )
}

modify_binding <- function(env, lst) {
  lapply(names(lst), unlockBinding, env)
  list2env(lst, envir = env)
  lapply(names(lst), lockBinding, env)
}

# mirai-specific helpers -------------------------------------------------------

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
  otel_is_tracing && return(span$set_attribute("mirai.id", id))
}

otel_set_span_error <- function(span, type) {
  otel_is_tracing && inherits(span, "otel_span") && return(span$set_status("error", type))
}

otel_daemon_attrs <- function(url) {
  purl <- parse_url(url)
  list(
    server.address = if (nzchar(purl[["hostname"]])) purl[["hostname"]] else purl[["path"]],
    server.port = if (nzchar(purl[["port"]])) as.integer(purl[["port"]]) else integer(),
    network.transport = purl[["scheme"]]
  )
}

otel_daemons_attrs <- function(envir) {
  c(
    otel_daemon_attrs(envir[["url"]]),
    list(
      mirai.dispatcher = !is.null(envir[["dispatcher"]]),
      mirai.compute = envir[["compute"]]
    )
  )
}
