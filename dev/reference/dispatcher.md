# Dispatcher

Dispatches tasks from a host to daemons for processing, using FIFO
scheduling, queuing tasks as required. Daemon / dispatcher settings are
controlled by
[`daemons()`](https://mirai.r-lib.org/dev/reference/daemons.md) and this
function should not need to be called directly.

## Usage

``` r
dispatcher(host, url = NULL, n = 0L, ...)
```

## Arguments

- host:

  the character URL dispatcher should dial in to, typically an IPC
  address.

- url:

  the character URL dispatcher should listen at (and daemons should dial
  in to), including the port to connect to e.g. tcp://hostname:5555' or
  'tcp://10.75.32.70:5555'. Specify 'tls+tcp://' to use secure TLS
  connections.

- n:

  if specified, the integer number of daemons to be launched locally by
  the host process.

- ...:

  (optional) additional arguments passed through to
  [`daemon()`](https://mirai.r-lib.org/dev/reference/daemon.md) if
  launching daemons. These include `asyncdial`, `autoexit`, `cleanup`,
  `output`, `maxtasks`, `idletime`, `walltime` and `tlscert`.

## Value

Invisible NULL.

## Details

The network topology is such that a dispatcher acts as a gateway between
the host and daemons, ensuring that tasks received from the host are
dispatched on a FIFO basis for processing. Tasks are queued at the
dispatcher to ensure tasks are only sent to daemons that can begin
immediate execution of the task.
