# mirai x parallel -------------------------------------------------------------

#' Make Mirai Cluster
#'
#' `make_cluster` creates a cluster of type 'miraiCluster', which may be used as
#' a cluster object for any function in the \pkg{parallel} base package such as
#' [parallel::clusterApply()] or [parallel::parLapply()].
#'
#' For R version 4.5 or newer, [parallel::makeCluster()] specifying
#' `type = "MIRAI"` is equivalent to this function.
#'
#' @param n integer number of nodes (automatically launched on the local machine
#'   unless `url` is supplied).
#' @param url \[default NULL\] (specify for remote nodes) the character URL on
#'   the host for remote nodes to dial into, including a port accepting incoming
#'   connections, e.g. 'tcp://10.75.37.40:5555'. Specify a URL with the scheme
#'   'tls+tcp://' to use secure TLS connections.
#' @param remote \[default NULL\] (specify to launch remote nodes) a remote
#'   launch configuration generated by [ssh_config()], [cluster_config()] or
#'   [remote_config()]. If not supplied, nodes may be deployed manually on
#'   remote resources.
#' @param ... additional arguments passed to [daemons()].
#'
#' @return For **make_cluster**: An object of class 'miraiCluster' and
#'   'cluster'. Each 'miraiCluster' has an automatically assigned ID and `n`
#'   nodes of class 'miraiNode'. If `url` is supplied but not `remote`, the
#'   shell commands for deployment of nodes on remote resources are printed to
#'   the console.
#'
#'   For **stop_cluster**: invisible NULL.
#'
#' @section Remote Nodes:
#'
#' Specify `url` and `n` to set up a host connection for remote nodes to dial
#' into. `n` defaults to one if not specified.
#'
#' Also specify `remote` to launch the nodes using a configuration generated by
#' [remote_config()] or [ssh_config()]. In this case, the number of nodes is
#' inferred from the configuration provided and `n` is disregarded.
#'
#' If `remote` is not supplied, the shell commands for deploying nodes manually
#' on remote resources are automatically printed to the console.
#'
#' [launch_remote()] may be called at any time on a 'miraiCluster' to return the
#' shell commands for deployment of all nodes, or on a 'miraiNode' to return the
#' command for a single node.
#'
#' @section Status:
#'
#' Call [status()] on a 'miraiCluster' to check the number of currently active
#' connections as well as the host URL.
#'
#' @section Errors:
#'
#' Errors are thrown by the \pkg{parallel} package mechanism if one or more
#' nodes failed (quit unexpectedly). The resulting 'errorValue' returned is 19
#' (Connection reset). Other types of error, e.g. in evaluation, result in the
#' usual 'miraiError' being returned.
#'
#' @note The default behaviour of clusters created by this function is designed
#'   to map as closely as possible to clusters created by the \pkg{parallel}
#'   package. However, `...` arguments are passed onto [daemons()] for
#'   additional customisation if desired, although resultant behaviour may not
#'   always be supported.
#'
#' @examplesIf interactive()
#' cl <- make_cluster(2)
#' cl
#' cl[[1L]]
#'
#' Sys.sleep(0.5)
#' status(cl)
#'
#' stop_cluster(cl)
#'
#' @export
#'
make_cluster <- function(n, url = NULL, remote = NULL, ...) {
  id <- sprintf("`%d`", length(..))
  cvs <- cv()

  if (is.character(url)) {
    daemons(n, url = url, remote = remote, dispatcher = FALSE, cleanup = FALSE, ..., .compute = id)

    if (is.null(remote)) {
      if (missing(n)) n <- 1L
      is.numeric(n) || stop(._[["numeric_n"]])
      cat("Shell commands for deployment on nodes:\n\n", file = stdout())
      print(launch_remote(n, ..., .compute = id))
    } else {
      args <- remote[["args"]]
      n <- if (is.list(args)) length(args) else 1L
    }
  } else {
    is.numeric(n) || stop(._[["numeric_n"]])
    n >= 1L || stop(._[["n_one"]])
    daemons(n, dispatcher = FALSE, cleanup = FALSE, ..., .compute = id)
  }

  `[[<-`(..[[id]], "cvs", cvs)

  cl <- lapply(seq_len(n), create_node, id = id)
  `attributes<-`(cl, list(class = c("miraiCluster", "cluster"), id = id))
}

#' Stop Mirai Cluster
#'
#' `stop_cluster` stops a cluster created by `make_cluster`.
#'
#' @param cl a 'miraiCluster'.
#'
#' @rdname make_cluster
#' @export
#'
stop_cluster <- function(cl) {
  daemons(0L, .compute = attr(cl, "id"))
  invisible()
}

#' @exportS3Method parallel::stopCluster
#'
stopCluster.miraiCluster <- stop_cluster

#' @exportS3Method parallel::sendData
#'
sendData.miraiNode <- function(node, data) {
  id <- attr(node, "id")
  envir <- ..[[id]]
  is.null(envir) && stop(._[["cluster_inactive"]])

  value <- data[["data"]]
  tagged <- !is.null(value[["tag"]])
  `[[<-`(envir, "cv", if (tagged) envir[["cvs"]])

  m <- mirai(
    do.call(node, data, quote = TRUE),
    node = value[["fun"]],
    data = value[["args"]],
    .compute = id
  )
  if (tagged) `[[<-`(m, "tag", value[["tag"]])
  `[[<-`(node, "mirai", m)
}

#' @exportS3Method parallel::recvData
#'
recvData.miraiNode <- function(node) call_aio(.subset2(node, "mirai"))

#' @exportS3Method parallel::recvOneData
#'
recvOneData.miraiCluster <- function(cl) {
  wait(..[[attr(cl, "id")]][["cv"]])
  node <- which.min(lapply(cl, node_unresolved))
  m <- .subset2(.subset2(cl, node), "mirai")
  list(node = node, value = `class<-`(m, NULL))
}

#' @export
#'
print.miraiCluster <- function(x, ...) {
  id <- attr(x, "id")
  cat(
    sprintf(
      "< miraiCluster | ID: %s nodes: %d active: %s >\n",
      id,
      length(x),
      !is.null(..[[id]])
    ),
    file = stdout()
  )
  invisible(x)
}

#' @export
#'
`[.miraiCluster` <- function(x, ...) .subset(x, ...)

#' @export
#'
print.miraiNode <- function(x, ...) {
  cat(
    sprintf(
      "< miraiNode | node: %d cluster ID: %s >\n",
      attr(x, "node"),
      attr(x, "id")
    ),
    file = stdout()
  )
  invisible(x)
}

# internals --------------------------------------------------------------------

create_node <- function(node, id) {
  `attributes<-`(
    new.env(hash = FALSE, parent = emptyenv()),
    list(class = "miraiNode", node = node, id = id)
  )
}

node_unresolved <- function(node) {
  m <- .subset2(node, "mirai")
  unresolved(m) || !is.object(m)
}
