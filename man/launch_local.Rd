% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/launchers.R
\name{launch_local}
\alias{launch_local}
\alias{launch_remote}
\title{Launch Daemon}
\usage{
launch_local(n = 1L, ..., tls = NULL, .compute = NULL)

launch_remote(
  n = 1L,
  remote = remote_config(),
  ...,
  tls = NULL,
  .compute = NULL
)
}
\arguments{
\item{n}{integer number of daemons.

\strong{or} for \code{launch_remote} only, a 'miraiCluster' or 'miraiNode'.}

\item{...}{(optional) arguments passed through to \code{\link[=daemon]{daemon()}}. These include
\code{asycdial}, \code{autoexit}, \code{cleanup}, \code{output}, \code{maxtasks}, \code{idletime},
\code{walltime} and \code{tlscert}. Only supply to override arguments originally
provided to \code{\link[=daemons]{daemons()}}, otherwise those will be used instead.}

\item{tls}{[default NULL] deprecated. Specify \code{tlscert} as a \code{...} argument
to \code{\link[=daemons]{daemons()}} when setting up daemons instead.}

\item{.compute}{[default NULL] character value for the compute profile
to use (each has its own independent set of daemons), or NULL to use the
'default' profile.}

\item{remote}{required only for launching remote daemons, a configuration
generated by \code{\link[=ssh_config]{ssh_config()}}, \code{\link[=cluster_config]{cluster_config()}}, or \code{\link[=remote_config]{remote_config()}}. An
empty \code{\link[=remote_config]{remote_config()}} does not perform any launches but returns the shell
commands for deploying manually on remote machines.}
}
\value{
For \strong{launch_local}: Integer number of daemons launched.

For \strong{launch_remote}: A character vector of daemon launch commands,
classed as 'miraiLaunchCmd'. The printed output may be copy / pasted
directly to the remote machine.
}
\description{
Launching a daemon is very much akin to launching a satellite. They are a way
to deploy a daemon (in our case) on the desired machine. Once it executes, it
connects back to the host process using its own communications.
\cr\cr \code{launch_local} deploys a daemon on the local machine in a new
background \code{Rscript} process.

\code{launch_remote} returns the shell command for deploying daemons as a
character vector. If an \code{\link[=ssh_config]{ssh_config()}}, \code{\link[=cluster_config]{cluster_config()}} or
\code{\link[=remote_config]{remote_config()}} configuration is supplied then this is used to launch the
daemon on the remote machine.
}
\details{
Daemons must already be set for launchers to work.

These functions may be used to re-launch daemons that have exited after
reaching time or task limits.

For non-dispatcher daemons using the default seed strategy, the generated
command contains the argument \code{rs} specifying the length 7 L'Ecuyer-CMRG
random seed supplied to the daemon. The values will be different each time
the function is called.
}
\examples{
\dontshow{if (interactive()) withAutoprint(\{ # examplesIf}
daemons(url = host_url(), dispatcher = FALSE)
status()
launch_local(1L, cleanup = FALSE)
launch_remote(1L, cleanup = FALSE)
Sys.sleep(1)
status()
daemons(0)

daemons(url = host_url(tls = TRUE))
status()
launch_local(2L, output = TRUE)
Sys.sleep(1)
status()
daemons(0)
\dontshow{\}) # examplesIf}
}
