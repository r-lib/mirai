# Daemon Instance

Starts up an execution daemon to receive
[`mirai()`](https://mirai.r-lib.org/dev/reference/mirai.md) requests.
Awaits data, evaluates an expression in an environment containing the
supplied data, and returns the value to the host caller. Daemon settings
may be controlled by
[`daemons()`](https://mirai.r-lib.org/dev/reference/daemons.md) and this
function should not need to be invoked directly, unless deploying
manually on remote resources.

## Usage

``` r
daemon(
  url,
  dispatcher = TRUE,
  ...,
  asyncdial = FALSE,
  autoexit = TRUE,
  cleanup = TRUE,
  output = FALSE,
  idletime = Inf,
  walltime = Inf,
  maxtasks = Inf,
  tlscert = NULL,
  rs = NULL
)
```

## Arguments

- url:

  (character) host or dispatcher URL to dial into, e.g.
  'tcp://hostname:5555' or 'tls+tcp://10.75.32.70:5555'.

- dispatcher:

  (logical) whether dialing into dispatcher or directly to host.

- ...:

  reserved for future use.

- asyncdial:

  (logical) whether to dial asynchronously. `FALSE` errors if connection
  fails immediately. `TRUE` retries indefinitely (more resilient but can
  mask connection issues).

- autoexit:

  (logical) whether to exit when the socket connection ends. `TRUE`
  exits immediately, `NA` completes current task first, `FALSE` persists
  indefinitely. See Persistence section.

- cleanup:

  (logical) whether to restore global environment, packages, and options
  to initial state after each evaluation.

- output:

  (logical) whether to output stdout/stderr. For local daemons via
  [`daemons()`](https://mirai.r-lib.org/dev/reference/daemons.md) or
  [`launch_local()`](https://mirai.r-lib.org/dev/reference/launch_local.md),
  redirects output to host process.

- idletime:

  (integer) milliseconds to wait idle before exiting.

- walltime:

  (integer) milliseconds of real time before exiting (soft limit).

- maxtasks:

  (integer) maximum tasks to execute before exiting.

- tlscert:

  (character) for secure TLS connections. Either a file path to
  PEM-encoded certificate authority certificate chain (starting with the
  TLS certificate and ending with the CA certificate), or a length-2
  vector of (certificate chain, empty string `""`).

- rs:

  (integer vector) initial `.Random.seed` value. Set automatically by
  host process; do not supply manually.

## Value

Invisibly, an integer exit code: 0L for normal termination, and a
positive value if a self-imposed limit was reached: 1L (idletime), 2L
(walltime), 3L (maxtasks).

## Details

The network topology is such that daemons dial into the host or
dispatcher, which listens at the `url` address. In this way, network
resources may be added or removed dynamically and the host or dispatcher
automatically distributes tasks to all available daemons.

## Persistence

The `autoexit` argument governs persistence settings for the daemon. The
default `TRUE` ensures that it exits as soon as its socket connection
with the host process drops. A 200ms grace period allows the daemon
process to exit normally, after which it will be forcefully terminated.

Supplying `NA` ensures that a daemon always exits cleanly after its
socket connection with the host drops. This means that it can
temporarily outlive this connection, but only to complete any task that
is currently in progress. This can be useful if the daemon is performing
a side effect such as writing files to disk, with the result not being
required back in the host process.

Setting to `FALSE` allows the daemon to persist indefinitely even when
there is no longer a socket connection. This allows a host session to
end and a new session to connect at the URL where the daemon is dialed
in. Daemons must be terminated with `daemons(NULL)` in this case instead
of `daemons(0)`. This sends explicit exit signals to all connected
daemons.
