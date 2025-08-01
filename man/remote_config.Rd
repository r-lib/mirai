% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/launchers.R
\name{remote_config}
\alias{remote_config}
\title{Generic Remote Launch Configuration}
\usage{
remote_config(
  command = NULL,
  args = c("", "."),
  rscript = "Rscript",
  quote = FALSE
)
}
\arguments{
\item{command}{the command used to effect the daemon launch on the remote
machine as a character string (e.g. \code{"ssh"}). Defaults to \code{"ssh"} for
\code{ssh_config}, although may be substituted for the full path to a specific
SSH application. The default NULL for \code{remote_config} does not carry out
any launches, but causes \code{\link[=launch_remote]{launch_remote()}} to return the shell commands for
manual deployment on remote machines.}

\item{args}{(optional) arguments passed to \code{command}, as a character vector
that must include \code{"."} as an element, which will be substituted for the
daemon launch command. Alternatively, a list of such character vectors to
effect multiple launches (one for each list element).}

\item{rscript}{[default "Rscript"] assumes the R executable is on the
search path. Replace with the full path of the Rscript executable on the
remote machine if necessary. If launching on Windows, \code{"Rscript"} should be
replaced with \code{"Rscript.exe"}.}

\item{quote}{[default FALSE] logical value whether or not to quote the
daemon launch command (not required for Slurm \code{"srun"} for example, but
required for Slurm \code{"sbatch"} or \code{"ssh"}).}
}
\value{
A list in the required format to be supplied to the \code{remote} argument
of \code{\link[=daemons]{daemons()}} or \code{\link[=launch_remote]{launch_remote()}}.
}
\description{
Provides a flexible generic framework for generating the shell commands to
deploy daemons remotely.
}
\examples{
# Slurm srun example
remote_config(
  command = "srun",
  args = c("--mem 512", "-n 1", "."),
  rscript = file.path(R.home("bin"), "Rscript")
)

# SSH requires 'quote = TRUE'
remote_config(
  command = "/usr/bin/ssh",
  args = c("-fTp 22 10.75.32.90", "."),
  quote = TRUE
)

# can be used to start local dameons with special configurations
remote_config(
  command = "Rscript",
  rscript = "--default-packages=NULL --vanilla"
)

}
\seealso{
\code{\link[=ssh_config]{ssh_config()}} for SSH launch configurations, or \code{\link[=cluster_config]{cluster_config()}}
for cluster resource manager launch configurations.
}
