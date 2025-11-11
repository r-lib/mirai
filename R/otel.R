otel_tracer_name <- "org.r-lib.mirai"

# otel helpers -----------------------------------------------------------------

otel_cache_tracer <- NULL
otel_mirai_span <- NULL
otel_eval_span <- NULL
otel_map_span <- NULL
otel_span <- NULL
otel_set_span_id <- NULL
otel_set_span_error <- NULL

local({
  otel_is_tracing <- FALSE
  otel_tracer <- NULL

  otel_cache_tracer <<- function() {
    requireNamespace("otel", quietly = TRUE) || return()
    otel_tracer <<- otel::get_tracer(otel_tracer_name)
    otel_is_tracing <<- tracer_enabled(otel_tracer)
  }

  otel_mirai_span <<- function(envir) {
    otel_is_tracing && length(envir) || return()
    spn <- otel::start_local_active_span(
      "mirai",
      links = list(envir[["otel_span"]]),
      options = list(kind = "client"),
      tracer = otel_tracer,
      activation_scope = parent.frame()
    )
    list(otel::pack_http_context(), spn)
  }

  otel_eval_span <<- function(ctx) {
    otel_is_tracing && length(ctx) || return()
    otel::start_local_active_span(
      "daemon eval",
      links = list(.[["otel_span"]]),
      options = list(kind = "server", parent = otel::extract_http_context(ctx)),
      tracer = otel_tracer,
      activation_scope = parent.frame()
    )
  }

  otel_map_span <<- function(.compute) {
    otel_is_tracing || return()
    otel::start_local_active_span(
      "mirai_map",
      links = list(..[[.compute]][["otel_span"]]),
      tracer = otel_tracer,
      activation_scope = parent.frame()
    )
  }

  otel_span <<- function(name, obj, links = NULL) {
    otel_is_tracing || return()
    if (is.environment(obj)) {
      attributes <- otel_env_attrs(obj)
      obj <- obj[["url"]]
    } else {
      attributes <- NULL
    }
    otel::start_local_active_span(
      sprintf("%s %s", name, obj),
      attributes = c(otel_url_attrs(obj), attributes),
      links = links,
      tracer = otel_tracer
    )
  }

  otel_set_span_id <<- function(span, id) {
    otel_is_tracing && is.environment(span) && return(
      .subset2(span, "set_attribute")("mirai.id", id)
    )
  }

  otel_set_span_error <<- function(span, type) {
    otel_is_tracing && is.environment(span) && return(
      .subset2(span, "set_status")("error", type)
    )
  }
})

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

otel_env_attrs <- function(env) {
  list(
    mirai.dispatcher = !is.null(env[["dispatcher"]]),
    mirai.compute = env[["compute"]]
  )
}

otel_url_attrs <- function(url) {
  purl <- parse_url(url)
  list(
    server.address = if (nzchar(purl[["hostname"]])) purl[["hostname"]] else purl[["path"]],
    server.port = if (nzchar(purl[["port"]])) as.integer(purl[["port"]]) else integer(),
    network.transport = purl[["scheme"]]
  )
}
