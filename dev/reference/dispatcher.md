# Dispatcher

Dispatches tasks from a host to daemons for processing, using FIFO
scheduling, queuing tasks as required. Daemon / dispatcher settings are
controlled by
[`daemons()`](https://mirai.r-lib.org/dev/reference/daemons.md) and this
function should not need to be called directly.

## Usage

``` r
dispatcher(host, url = NULL, n = 0L)
```

## Arguments

- host:

  (character) URL to dial into, typically an IPC address.

- url:

  (character) URL to listen at for daemon connections, e.g.
  'tcp://hostname:5555'. Use 'tls+tcp://' for secure TLS.

- n:

  (integer) number of local daemons launched by host.

## Value

Invisibly, an integer exit code: 0L for normal termination.

## Details

Dispatcher acts as a gateway between the host and daemons, dispatching
tasks on a FIFO basis. Tasks are queued until a daemon is available for
immediate execution.
