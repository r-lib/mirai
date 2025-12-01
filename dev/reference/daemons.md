# Daemons (Set Persistent Processes)

Set daemons, or persistent background processes, to receive
[`mirai()`](https://mirai.r-lib.org/dev/reference/mirai.md) requests.
Specify `n` to create daemons on the local machine. Specify `url` to
receive connections from remote daemons (for distributed computing
across the network). Specify `remote` to optionally launch remote
daemons via a remote configuration. Dispatcher (enabled by default)
ensures optimal scheduling.

## Usage

``` r
daemons(
  n,
  url = NULL,
  remote = NULL,
  dispatcher = TRUE,
  ...,
  sync = FALSE,
  seed = NULL,
  serial = NULL,
  tls = NULL,
  pass = NULL,
  .compute = NULL
)
```

## Arguments

- n:

  integer number of daemons to launch.

- url:

  if specified, a character string comprising a URL at which to listen
  for remote daemons, including a port accepting incoming connections,
  e.g. 'tcp://hostname:5555' or 'tcp://10.75.32.70:5555'. Specify a URL
  with scheme 'tls+tcp://' to use secure TLS connections (for details
  see Distributed Computing section below). Auxiliary function
  [`host_url()`](https://mirai.r-lib.org/dev/reference/host_url.md) may
  be used to construct a valid host URL.

- remote:

  (required only for launching remote daemons) a configuration generated
  by
  [`ssh_config()`](https://mirai.r-lib.org/dev/reference/ssh_config.md),
  [`cluster_config()`](https://mirai.r-lib.org/dev/reference/cluster_config.md),
  or
  [`remote_config()`](https://mirai.r-lib.org/dev/reference/remote_config.md).

- dispatcher:

  logical value, whether to use dispatcher. Dispatcher runs in a
  separate process to ensure optimal scheduling, and should normally be
  kept on (for details see Dispatcher section below).

- ...:

  (optional) additional arguments passed through to
  [`daemon()`](https://mirai.r-lib.org/dev/reference/daemon.md) if
  launching daemons. These include `asyncdial`, `autoexit`, `cleanup`,
  `output`, `maxtasks`, `idletime`, `walltime` and `tlscert`.

- sync:

  logical value, whether to evaluate mirai synchronously in the current
  process. Setting to TRUE substantially changes the behaviour of mirai
  by causing them to be evaluated immediately after creation. This
  facilitates testing and debugging, e.g. via an interactive
  [`browser()`](https://rdrr.io/r/base/browser.html). In this case,
  arguments other than `seed` and `.compute` are disregarded.

- seed:

  (optional) The default of NULL initializes L'Ecuyer-CMRG RNG streams
  for each daemon, the same as base R's parallel package. Results are
  statistically-sound, although generally non-reproducible, as which
  tasks are sent to which daemons may be non-deterministic, and also
  depends on the number of daemons.  
  (experimental) supply an integer value to instead initialize a
  L'Ecuyer-CMRG RNG stream for the compute profile. This is advanced for
  each mirai evaluation, hence allowing for reproducible results, as the
  random seed is always associated with a given mirai, independently of
  where it is evaluated.

- serial:

  (optional, requires dispatcher) a configuration created by
  [`serial_config()`](https://mirai.r-lib.org/dev/reference/serial_config.md)
  to register serialization and unserialization functions for normally
  non-exportable reference objects, such as Arrow Tables or torch
  tensors. If NULL, configurations registered with
  [`register_serial()`](https://mirai.r-lib.org/dev/reference/register_serial.md)
  are automatically applied.

- tls:

  (optional for secure TLS connections) if not supplied,
  zero-configuration single-use keys and certificates are automatically
  generated when required. If supplied, **either** the character path to
  a file containing the PEM-encoded TLS certificate and associated
  private key (may contain additional certificates leading to a
  validation chain, with the TLS certificate first), **or** a length 2
  character vector comprising (i) the TLS certificate (optionally
  certificate chain) and (ii) the associated private key.

- pass:

  (required only if the private key supplied to `tls` is encrypted with
  a password) For security, should be provided through a function that
  returns this value, rather than directly.

- .compute:

  character value for the compute profile to use (each has its own
  independent set of daemons), or NULL to use the 'default' profile.

## Value

Invisibly, logical `TRUE` when creating daemons and `FALSE` when
resetting.

## Details

Use `daemons(0)` to reset daemon connections:

- All connected daemons and/or dispatchers exit automatically.

- Any as yet unresolved 'mirai' will return an 'errorValue' 19
  (Connection reset).

- [`mirai()`](https://mirai.r-lib.org/dev/reference/mirai.md) reverts to
  the default behaviour of creating a new background process for each
  request.

If the host session ends, all connected dispatcher and daemon processes
automatically exit as soon as their connections are dropped.

Calling `daemons()` implicitly resets any existing daemons for the
compute profile with `daemons(0)`. Instead,
[`launch_local()`](https://mirai.r-lib.org/dev/reference/launch_local.md)
or
[`launch_remote()`](https://mirai.r-lib.org/dev/reference/launch_local.md)
may be used to add daemons at any time without resetting daemons.

## Local Daemons

Setting daemons, or persistent background processes, is typically more
efficient as it removes the need for, and overhead of, creating new
processes for each mirai evaluation. It also provides control over the
total number of processes at any one time.

Supply the argument `n` to set the number of daemons. New background
[`daemon()`](https://mirai.r-lib.org/dev/reference/daemon.md) processes
are automatically launched on the local machine connecting back to the
host process, either directly or via dispatcher.

## Dispatcher

By default `dispatcher = TRUE` launches a background process running
[`dispatcher()`](https://mirai.r-lib.org/dev/reference/dispatcher.md).
Dispatcher connects to daemons on behalf of the host, queues tasks, and
ensures optimal FIFO scheduling. Dispatcher also enables (i) mirai
cancellation using
[`stop_mirai()`](https://mirai.r-lib.org/dev/reference/stop_mirai.md) or
when using a `.timeout` argument to
[`mirai()`](https://mirai.r-lib.org/dev/reference/mirai.md), and (ii)
the use of custom serialization configurations.

Specifying `dispatcher = FALSE`, daemons connect directly to the host
and tasks are distributed in a round-robin fashion, with tasks queued at
each daemon. Optimal scheduling is not guaranteed as, depending on the
duration of tasks, they can be queued at one daemon while others remain
idle. However, this solution is the most resource-light, and suited to
similar-length tasks, or where concurrent tasks typically do not exceed
available daemons.

## Distributed Computing

Specify `url` as a character string to allow tasks to be distributed
across the network (`n` is only required in this case if also providing
a launch configuration to `remote`).

The host / dispatcher listens at this URL, utilising a single port, and
[`daemon()`](https://mirai.r-lib.org/dev/reference/daemon.md) processes
dial in to this URL. Host / dispatcher automatically adjusts to the
number of daemons actually connected, allowing dynamic upscaling /
downscaling.

The URL should have a 'tcp://' scheme, such as 'tcp://10.75.32.70:5555'.
Switching the URL scheme to 'tls+tcp://' automatically upgrades the
connection to use TLS. The auxiliary function
[`host_url()`](https://mirai.r-lib.org/dev/reference/host_url.md) may be
used to construct a valid host URL based on the computer's IP address.

IPv6 addresses are also supported and must be enclosed in square
brackets `[]` to avoid confusion with the final colon separating the
port. For example, port 5555 on the IPv6 loopback address ::1 would be
specified as 'tcp://\[::1\]:5555'.

Specifying the wildcard value zero for the port number e.g.
'tcp://\[::1\]:0' will automatically assign a free ephemeral port. Use
[`status()`](https://mirai.r-lib.org/dev/reference/status.md) to inspect
the actual assigned port at any time.

Specify `remote` with a call to
[`ssh_config()`](https://mirai.r-lib.org/dev/reference/ssh_config.md),
[`cluster_config()`](https://mirai.r-lib.org/dev/reference/cluster_config.md)
or
[`remote_config()`](https://mirai.r-lib.org/dev/reference/remote_config.md)
to launch (programatically deploy) daemons on remote machines, from
where they dial back to `url`. If not launching daemons,
[`launch_remote()`](https://mirai.r-lib.org/dev/reference/launch_local.md)
may be used to generate the shell commands for manual deployment.

## Compute Profiles

If `NULL`, the `"default"` compute profile is used. Providing a
character value for `.compute` creates a new compute profile with the
name specified. Each compute profile retains its own daemons settings,
and may be operated independently of each other. Some usage examples
follow:

**local / remote** daemons may be set with a host URL and specifying
`.compute` as `"remote"`, which creates a new compute profile.
Subsequent [`mirai()`](https://mirai.r-lib.org/dev/reference/mirai.md)
calls may then be sent for local computation by not specifying the
`.compute` argument, or for remote computation to connected daemons by
specifying the `.compute` argument as `"remote"`.

**cpu / gpu** some tasks may require access to different types of
daemon, such as those with GPUs. In this case, `daemons()` may be called
to set up host URLs for CPU-only daemons and for those with GPUs,
specifying the `.compute` argument as `"cpu"` and `"gpu"` respectively.
By supplying the `.compute` argument to subsequent
[`mirai()`](https://mirai.r-lib.org/dev/reference/mirai.md) calls, tasks
may be sent to either `cpu` or `gpu` daemons as appropriate.

Note: further actions such as resetting daemons via `daemons(0)` should
be carried out with the desired `.compute` argument specified.

## See also

[`with_daemons()`](https://mirai.r-lib.org/dev/reference/with_daemons.md)
and
[`local_daemons()`](https://mirai.r-lib.org/dev/reference/with_daemons.md)
for managing the compute profile used locally.

## Examples

``` r
if (FALSE) { # interactive()
# Create 2 local daemons (using dispatcher)
daemons(2)
status()
# Reset to zero
daemons(0)

# Create 2 local daemons (not using dispatcher)
daemons(2, dispatcher = FALSE)
status()
# Reset to zero
daemons(0)

# Set up dispatcher accepting TLS over TCP connections
daemons(url = host_url(tls = TRUE))
status()
# Reset to zero
daemons(0)

# Set host URL for remote daemons to dial into
daemons(url = host_url(), dispatcher = FALSE)
status()
# Reset to zero
daemons(0)

# Use with() to evaluate with daemons for the duration of the expression
with(
  daemons(2),
  {
    m1 <- mirai(Sys.getpid())
    m2 <- mirai(Sys.getpid())
    cat(m1[], m2[], "\n")
  }
)

if (FALSE) { # \dontrun{

# Launch daemons on remotes 'nodeone' and 'nodetwo' using SSH
# connecting back directly to the host URL over a TLS connection:
daemons(
  url = host_url(tls = TRUE),
  remote = ssh_config(c('ssh://nodeone', 'ssh://nodetwo'))
)

# Launch 4 daemons on the remote machine 10.75.32.90 using SSH tunnelling:
daemons(
  n = 4,
  url = local_url(tcp = TRUE),
  remote = ssh_config('ssh://10.75.32.90', tunnel = TRUE)
)

} # }
}
# Synchronous mode
# mirai are run in the current process - useful for testing and debugging
daemons(sync = TRUE)
m <- mirai(Sys.getpid())
daemons(0)
m[]
#> [1] 6371

# Synchronous mode restricted to a specific compute profile
daemons(sync = TRUE, .compute = "sync")
with_daemons("sync", {
  m <- mirai(Sys.getpid())
})
daemons(0, .compute = "sync")
m[]
#> [1] 6371
```
