# Launch Daemon

Launching a daemon is very much akin to launching a satellite. They are
a way to deploy a daemon (in our case) on the desired machine. Once it
executes, it connects back to the host process using its own
communications.  
  
`launch_local` deploys a daemon on the local machine in a new background
`Rscript` process.

`launch_remote` returns the shell command for deploying daemons as a
character vector. If an
[`ssh_config()`](https://mirai.r-lib.org/dev/reference/ssh_config.md),
[`cluster_config()`](https://mirai.r-lib.org/dev/reference/cluster_config.md)
or
[`remote_config()`](https://mirai.r-lib.org/dev/reference/remote_config.md)
configuration is supplied then this is used to launch the daemon on the
remote machine.

## Usage

``` r
launch_local(n = 1L, ..., .compute = NULL)

launch_remote(n = 1L, remote = remote_config(), ..., .compute = NULL)
```

## Arguments

- n:

  integer number of daemons.

  **or** for `launch_remote` only, a 'miraiCluster' or 'miraiNode'.

- ...:

  (optional) arguments passed through to
  [`daemon()`](https://mirai.r-lib.org/dev/reference/daemon.md). These
  include `asycdial`, `autoexit`, `cleanup`, `output`, `maxtasks`,
  `idletime`, and `walltime`. Only supply to override arguments
  originally provided to
  [`daemons()`](https://mirai.r-lib.org/dev/reference/daemons.md),
  otherwise those will be used instead.

- .compute:

  character value for the compute profile to use (each has its own
  independent set of daemons), or NULL to use the 'default' profile.

- remote:

  required only for launching remote daemons, a configuration generated
  by
  [`ssh_config()`](https://mirai.r-lib.org/dev/reference/ssh_config.md),
  [`cluster_config()`](https://mirai.r-lib.org/dev/reference/cluster_config.md),
  or
  [`remote_config()`](https://mirai.r-lib.org/dev/reference/remote_config.md).
  An empty
  [`remote_config()`](https://mirai.r-lib.org/dev/reference/remote_config.md)
  does not perform any launches but returns the shell commands for
  deploying manually on remote machines.

## Value

For **launch_local**: Integer number of daemons launched.

For **launch_remote**: A character vector of daemon launch commands,
classed as 'miraiLaunchCmd'. The printed output may be copy / pasted
directly to the remote machine.

## Details

Daemons must already be set for launchers to work.

These functions may be used to re-launch daemons that have exited after
reaching time or task limits.

For non-dispatcher daemons using the default seed strategy, the
generated command contains the argument `rs` specifying the length 7
L'Ecuyer-CMRG random seed supplied to the daemon. The values will be
different each time the function is called.

## Examples

``` r
if (FALSE) { # interactive()
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
}
```
