otel_tracer_name <- "org.r-lib.mirai"

# generic otel helpers ---------------------------------------------------------

otel_cache_tracer <- function() {
  requireNamespace("otel", quietly = TRUE) || return()
  tracer <- otel::get_tracer(otel_tracer_name)
  list2env(
    list(otel_tracer = tracer, otel_is_tracing = tracer_enabled(tracer)),
    envir = environment(otel_active_span)
  )
}

tracer_enabled <- function(tracer) {
  .subset2(tracer, "is_enabled")()
}

with_otel_record <- function(expr) {
  on.exit(otel_cache_tracer())
  otelsdk::with_otel_record({
    otel_cache_tracer()
    expr
  })
}

# mirai-specific helpers -------------------------------------------------------

otel_set_span_id <- NULL
otel_set_span_error <- NULL

otel_active_span <- local({
  otel_is_tracing <- FALSE
  otel_tracer <- NULL

  otel_set_span_id <<- function(span, id) {
    otel_is_tracing && return(span$set_attribute("mirai.id", id))
  }

  otel_set_span_error <<- function(span, type) {
    otel_is_tracing && inherits(span, "otel_span") && return(span$set_status("error", type))
  }

  function(
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
})

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
