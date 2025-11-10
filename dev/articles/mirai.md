# mirai - Minimalist Async Evaluation Framework for R

This is a reference vignette of the package’s core functionality. Other
package vignettes cover additional features.

### 1. Introduction

mirai (Japanese for ‘future’) implements the concept of *futures* in R.

Futures are an abstraction that represent the result of code evaluation
that will be available at some point in the future. The actual code
evaluation is sent to and performed in a separate R process (*daemon*),
and the result is sent back to the main (*host*) process when it
completes.

#### mirai

The package has one main function:
[`mirai()`](https://mirai.r-lib.org/dev/reference/mirai.md) to create a
mirai object from an expression.

This function returns immediately, and is never blocking. This is the
essence of async: whilst the mirai expression is evaluated on a daemon,
the host process is free to move on.

As the expression is evaluated in another process, it must be
self-contained:

- Package functions must be namespaced using `::`, or
  [`library()`](https://rdrr.io/r/base/library.html) calls be made
  within the expression.
- Other functions/data/objects required by the expression should be
  passed explicitly via `...` or `.args`.

> This is a 100% reliable evaluation model that corresponds to the
> underlying reality - any attempt to abstract away from it is
> inherently imperfect, and we do not compromise on this point.

The following mimics an expensive calculation that eventually returns a
random value.

``` r
library(mirai)

m <- mirai(
  {
    Sys.sleep(time)
    rnorm(5L, mean)
  },
  time = 2L,
  mean = 4.5
)

m
#> < mirai [] >
m$data
#> 'unresolved' logi NA
unresolved(m)
#> [1] TRUE

# Do work whilst unresolved

m[]
#> [1] 4.337259 2.585658 4.784084 3.409787 3.983382
m$data
#> [1] 4.337259 2.585658 4.784084 3.409787 3.983382
```

A mirai is either *unresolved* if the result has yet to be received, or
*resolved* if it has.
[`unresolved()`](https://mirai.r-lib.org/dev/reference/unresolved.md) is
a helper function to check the state of a mirai.

The result of a mirai `m` is available at `m$data` once it has resolved.
Normally this will be the return value of the evaluated expression. If
the expression errored, crashed, or timed out then this will be an
‘errorValue’ instead. See the section [Error Handling](#error-handling)
below.

Rather than repeatedly checking `unresolved(m)`, it is more efficient to
wait for and collect its value by using `m[]`.

You may also wait efficiently for mirai (or lists of mirai) to resolve
using:

- [`call_mirai()`](https://mirai.r-lib.org/dev/reference/call_mirai.md)
  returns when all the mirai passed to it have resolved.
- [`race_mirai()`](https://mirai.r-lib.org/dev/reference/race_mirai.md)
  returns when the first mirai passed to it has resolved.

#### mirai (advanced)

For easy programmatic use of
[`mirai()`](https://mirai.r-lib.org/dev/reference/mirai.md), ‘.expr’
accepts a pre-constructed language object, and also a list of named
arguments passed via ‘.args’. So, the following would be equivalent to
the above example:

``` r
expr <- quote({Sys.sleep(time); rnorm(5L, mean)})
args <- list(time = 2L, mean = 4)

m1 <- mirai(.expr = expr, .args = args)
m1[]
#> [1] 5.184685 3.728154 4.757521 3.215431 1.165492
```

The example below uses
[`mirai()`](https://mirai.r-lib.org/dev/reference/mirai.md) to perform a
long-running write operation asynchronously from a separate process.
Here [`environment()`](https://rdrr.io/r/base/environment.html), which
is the calling environment, is passed directly to ‘.args’. This is a
convenient method for passing in objects existing in the environment,
such as the `x` and `file` provided to the `write.csv.async()` function.

``` r
write.csv.async <- function(x, file) {
  mirai(write.csv(x, file), .args = environment())
}

m <- write.csv.async(x = rnorm(1e6), file = tempfile())

while (unresolved(m)) {
  cat("Writing file...\n")
  Sys.sleep(0.5) # or do other work
}
#> Writing file...
#> Writing file...
cat("Write complete:", is.null(m$data))
#> Write complete: TRUE
```

#### daemons

When writing a
[`mirai()`](https://mirai.r-lib.org/dev/reference/mirai.md) call, you
should not be concerned about where or how execution of that code
actually happens.

It is for the end-user running the code to declare the resources
available for evaluating mirai calls. This is done using the package’s
other main function:
[`daemons()`](https://mirai.r-lib.org/dev/reference/daemons.md).

If daemons have not been set, each
[`mirai()`](https://mirai.r-lib.org/dev/reference/mirai.md) call will by
default create a new local background process (*ephemeral daemon*) on
which to perform its evaluation.

Instead, [`daemons()`](https://mirai.r-lib.org/dev/reference/daemons.md)
sets up persistent daemons on which to evaluate mirai expressions.

- Using persistent daemons eliminates the time and overhead of starting
  new processes for each evaluation, and limits the number of processes
  used at any one time.
- Even re-using the same daemon, cleanup steps performed between
  evaluations ensure that each mirai continues to be self-contained and
  unaffected by past evaluations.

How to set up and launch daemons is covered in sections below, starting
with [local daemons](#local-daemons).

### 2. Error Handling

If execution in a mirai fails, the error message is returned as a
character string of class ‘miraiError’ and ‘errorValue’ to facilitate
debugging.

[`is_mirai_error()`](https://mirai.r-lib.org/dev/reference/is_mirai_error.md)
may be used to test for mirai execution errors.

``` r
m1 <- mirai(stop("occurred with a custom message", call. = FALSE))
m1[]
#> 'miraiError' chr Error: occurred with a custom message

m2 <- mirai(mirai::mirai())
m2[]
#> 'miraiError' chr Error in mirai::mirai(): missing expression, perhaps wrap in {}?

is_mirai_error(m2$data)
#> [1] TRUE
is_error_value(m2$data)
#> [1] TRUE
```

- A full stack trace of evaluation within the mirai is recorded and
  accessible at `$stack.trace` on the error object
- The original condition classes are also preserved at
  `$condition.class`

``` r
f <- function(x) if (x > 0) stop("positive")

m3 <- mirai({f(-1); f(1)}, f = f)
m3[]
#> 'miraiError' chr Error in f(1): positive

m3$data$stack.trace
#> [[1]]
#> stop("positive")
#> 
#> [[2]]
#> f(1)
m3$data$condition.class
#> [1] "simpleError" "error"       "condition"
```

- The elements of the original error condition are also accessible via
  `$` on the error object
- Additional metadata recorded by
  [`rlang::abort()`](https://rlang.r-lib.org/reference/abort.html) is
  preserved

``` r
f <- function(x) if (x > 0) stop("positive")

m4 <- mirai(rlang::abort("aborted", meta_uid = "UID001"))
m4[]
#> 'miraiError' chr Error: aborted

m4$data$meta_uid
#> [1] "UID001"
```

If a daemon instance is sent a user interrupt, the mirai will resolve to
an object of class ‘miraiInterrupt’ and ‘errorValue’.

[`is_mirai_interrupt()`](https://mirai.r-lib.org/dev/reference/is_mirai_error.md)
may be used to test for such interrupts.

``` r
m4 <- mirai(rlang::interrupt()) # simulates a user interrupt
is_mirai_interrupt(m4[])
#> [1] TRUE
```

If execution of a mirai surpasses the timeout set via the ‘.timeout’
argument, the mirai will resolve to an ‘errorValue’ of 5L (timed out).
This can, amongst other things, guard against mirai processes that have
the potential to hang and never return.

``` r
m5 <- mirai(nanonext::msleep(1000), .timeout = 500)
m5[]
#> 'errorValue' int 5 | Timed out

is_mirai_error(m5$data)
#> [1] FALSE
is_mirai_interrupt(m5$data)
#> [1] FALSE
is_error_value(m5$data)
#> [1] TRUE
```

[`is_error_value()`](https://mirai.r-lib.org/dev/reference/is_mirai_error.md)
tests for all mirai execution errors, user interrupts and timeouts.

### 3. Random Number Generation

mirai employs L’Ecuyer-CMRG streams for random number generation in the
same way as base R’s own parallel package. This is a widely-adopted,
statistically-sound method, suitable for parallel computation.

Streams essentially cut into the RNG’s period (a very long sequence of
pseudo-random numbers) at intervals that are far apart from each other
that they do not in practice overlap. This ensures that statistical
results obtained from parallel computations remain correct and valid.
The method of generating streams is recursive.

**By default, when the `seed` argument to
[`daemons()`](https://mirai.r-lib.org/dev/reference/daemons.md) is
`NULL`**: mirai initiates a new stream for each daemon launched, in the
same manner as base R.

- Guarantees that the results are statistically-sound, although does not
  guarantee numerical reproducibility between parallel runs
- Using different numbers of daemons would cause mirai tasks to be sent
  to different daemons
- With dispatcher, mirai tasks are sent dynamically to the next
  available daemon, and this is not guaranteed to be the same on each
  run

**Supply an explicit integer `seed` to
[`daemons()`](https://mirai.r-lib.org/dev/reference/daemons.md) for
reproducible RNG**: instead of initiating a new stream for each daemon,
now a stream is initiated for each
[`mirai()`](https://mirai.r-lib.org/dev/reference/mirai.md) call.

- Guarantees the same deterministic, reproducible results across runs
- This is regardless of the number of daemons used
- This does require additional computation, although with a negligible
  impact on performance

### 4. Local Daemons

Daemons, or persistent background processes, may be set to receive
[`mirai()`](https://mirai.r-lib.org/dev/reference/mirai.md) requests.

> Daemons inherit the default system configuration and read in the
> relevant ‘.Renviron’ and ‘.Rprofile’ etc. on startup. They also load
> the default packages. To instead only load the `base` package (which
> cuts out more than half of R’s startup time), the environment variable
> `R_SCRIPT_DEFAULT_PACKAGES=NULL` may be set prior to launching
> daemons.

Call [`daemons()`](https://mirai.r-lib.org/dev/reference/daemons.md)
specifying the number of daemons to launch.

``` r
daemons(6)
```

Setting `n` to one less than the number of available cores is a good
rule of thumb for optimal performance. You should determine what the
‘available’ cores are, as you may be setting aside cores for other
purposes and want this to be less than the total number of cores in the
system.

#### With Dispatcher (default)

The default `dispatcher = TRUE` creates a
[`dispatcher()`](https://mirai.r-lib.org/dev/reference/dispatcher.md)
background process that connects to individual daemon processes on the
local machine. This ensures that tasks are dispatched efficiently on a
first-in first-out (FIFO) basis to daemons for processing. Tasks are
queued at dispatcher and sent to a daemon as soon as it can accept the
task for immediate execution. Dispatcher employs an event-driven
approach that is efficient both in terms of consuming no resources while
waiting, whilst also being fully synchronized with events.

To view current statistics,
[`info()`](https://mirai.r-lib.org/dev/reference/info.md) provides these
succinctly in a single integer vector:

- `connections` number of currently active daemon connections
- `cumulative` total number of daemons to have ever connected
- `awaiting` number of mirai tasks queued at dispatcher
- `executing` number of mirai tasks currently being evaluated on a
  daemon
- `completed` number of mirai tasks for which have been either completed
  or cancelled

``` r
info()
#> connections  cumulative    awaiting   executing   completed 
#>           6           6           0           0           0
```

The [`status()`](https://mirai.r-lib.org/dev/reference/status.md)
function provides a slightly more verbose output:

1.  `connections`: the number of active connections.
2.  `daemons`: the URL daemons connect to.
3.  `mirai`: a task summary of `awaiting`, `assigned` and `completed`.

``` r
status()
#> $connections
#> [1] 6
#> 
#> $daemons
#> [1] "abstract://35e31d13eb5a325f25bc0cb6"
#> 
#> $mirai
#>  awaiting executing completed 
#>         0         0         0
```

``` r
daemons(0)
```

Set the number of daemons to zero to reset. This reverts to the default
of creating a new background process for each ‘mirai’ request.

#### Without Dispatcher

Alternatively, specifying `dispatcher = FALSE`, the background daemons
connect directly to the host process.

``` r
daemons(6, dispatcher = FALSE)
```

This means that tasks are sent immediately in a round-robin fashion,
which ensures that they are evenly-distributed amongst daemons. This
does not however guarantee optimal scheduling, as the duration of tasks
cannot be known *a priori*. As an example, tasks could be queued at a
daemon behind a long-running task, whilst other daemons are idle having
already completed their tasks.

The advantage of this approach is that it is resource-light and does not
require an additional dispatcher process. It is suited to working with
similar-length tasks, or where concurrent tasks typically do not exceed
available daemons.

Requesting the status now shows 6 connections, along with the host URL:

``` r
status()
#> $connections
#> [1] 6
#> 
#> $daemons
#> [1] "abstract://f67df9d8a22f0a5681435ca3"
```

#### everywhere()

[`everywhere()`](https://mirai.r-lib.org/dev/reference/everywhere.md)
may be used to evaluate an expression on all connected daemons and
persist the resultant state, regardless of a daemon’s ‘cleanup’ setting.

``` r
everywhere(library(DBI))
```

The above keeps the [`DBI`](https://dbi.r-dbi.org/) package loaded for
all evaluations. Other types of setup task may also be performed,
including making a common resource available, such as a database
connection:

``` r
everywhere(con <<- dbConnect(RSQLite::SQLite(), file), file = tempfile())
```

By super-assignment, the conenction ‘con’ will be available in the
global environment of all daemon instances. Subsequent mirai calls may
then make use of ‘con’.

``` r
mirai(exists("con"))[]
#> [1] TRUE
```

Disconnect from the database everywhere:

``` r
everywhere(dbDisconnect(con))
```

> Sometimes it may be necessary to evaluate an expression in the global
> environment of each daemon. As mirai evaluation does not occur in the
> global environment itself, but one inheriting from it, an explicit
> call to `evalq(envir = globalenv())` achieves this. An example use
> case is `box::use()` to import a module or package:

``` r
everywhere(
  evalq(
    box::use(dplyr[select], mirai[...]),
    envir = globalenv()
  )
)

daemons(0)
```

### 5. Remote Daemons

The daemons interface may also be used to send tasks for computation to
remote daemon processes on the network.

Call [`daemons()`](https://mirai.r-lib.org/dev/reference/daemons.md)
specifying ‘url’ as a character string such as: ‘tcp://10.75.32.70:5555’
at which daemon processes should connect. Alternatively, use
[`host_url()`](https://mirai.r-lib.org/dev/reference/host_url.md) to
automatically construct a valid URL. This acts like a ‘base station’,
utilizing a single port to listen out for all daemons that dial in to
the address. For launching the daemons (executing them on the machine of
your choice), please see the next section.

> IPv6 addresses are also supported and must be enclosed in square
> brackets `[]` to avoid confusion with the final colon separating the
> port. For example, port 5555 on the IPv6 address `::ffff:a6f:50d`
> would be specified as `tcp://[::ffff:a6f:50d]:5555`.

Below, calling
[`host_url()`](https://mirai.r-lib.org/dev/reference/host_url.md)
without a port value uses the default of ‘0’. This is a wildcard value
that will automatically assigns a free ephemeral port:

``` r
daemons(url = host_url())
```

The actual assigned port may be queried at any time via
[`status()`](https://mirai.r-lib.org/dev/reference/status.md):

``` r
status()
#> $connections
#> [1] 0
#> 
#> $daemons
#> [1] "tcp://192.168.1.71:33271"
#> 
#> $mirai
#>  awaiting executing completed 
#>         0         0         0
```

The number of daemons connected at any time may be dynamically scaled up
or down, according to requirements.

To reset all connections and revert to default behaviour:

``` r
daemons(0)
```

Closing the connection causes all connected daemons to exit
automatically. If using dispatcher, it will cause dispatcher to exit,
and in turn all connected daemons when their respective connections with
the dispatcher are terminated.

### 6. Launching Remote Daemons

> The launcher analogy is appropriate, as these are ways of deploying a
> daemon on the machine of your choice, very much like launching a
> satellite. Once deployed, the daemon connects back to your host
> process through its own communications (TCP or TLS over TCP).

The local launcher simply runs an `Rscript` instance via a local shell.
The remote launcher uses a method to run this `Rscript` command on a
remote machine.

To launch remote daemons, supply a remote launch configuration to the
‘remote’ argument of
[`daemons()`](https://mirai.r-lib.org/dev/reference/daemons.md), or
[`launch_remote()`](https://mirai.r-lib.org/dev/reference/launch_local.md)
at any time thereafter.

There are currently 3 options for generating remote launch
configurations:

1.  [`ssh_config()`](https://mirai.r-lib.org/dev/reference/ssh_config.md)
    where there is SSH access to the remote machine.
2.  [`cluster_config()`](https://mirai.r-lib.org/dev/reference/cluster_config.md)
    to use HPC cluster resource managers such as Slurm, SGE, Torque/PBS
    and LSF.
3.  [`remote_config()`](https://mirai.r-lib.org/dev/reference/remote_config.md)
    for a generic, flexible method that caters for other custom
    launchers.

The return value of all of these functions is a simple list. This means
that they may be pre-constructed, saved and re-used whenever the same
configuration is required.

#### SSH Direct Connection

This method is appropriate for internal networks and in trusted,
properly-configured environments where it is safe for your machine to
accept incoming connections on certain ports. In the examples below, the
remote daemons connect back directly to port 5555 on the local machine.

In these cases, using TLS is often desirable to provide additional
security to the connections.

The first example below launches 4 daemons on the machine 10.75.32.90
(using the default SSH port of 22 as this was not specified), connecting
back to the host URL:

``` r
daemons(
  n = 4,
  url = host_url(tls = TRUE, port = 5555),
  remote = ssh_config("ssh://10.75.32.90")
)
```

The second example below launches one daemon on each of 10.75.32.90 and
10.75.32.91 using the custom SSH port of 222:

``` r
daemons(
  n = 1,
  url = host_url(tls = TRUE, port = 5555),
  remote = ssh_config(c("ssh://10.75.32.90:222", "ssh://10.75.32.91:222"))
)
```

#### SSH Tunnelling

Use SSH tunnelling to launch daemons on any machine you are able to
access via SSH, whether on the local network or the cloud. SSH key-based
authentication must already be in place, but no other configuration is
required.

This provides a convenient way to launch remote daemons without them
needing to directly access the host. Firewall configurations or security
policies often prevent opening a port to accept outside connections. In
these cases, SSH tunnelling creates a tunnel once the initial SSH
connection is made. For simplicity, the implementation in mirai uses the
same tunnel port on both the host and daemon.

To use tunnelling, supply a URL with hostname of ‘127.0.0.1’ to ‘url’
for the [`daemons()`](https://mirai.r-lib.org/dev/reference/daemons.md)
call.

- `local_url(tcp = TRUE)` does this for you.
- The default uses the wildcard port of ‘0’, which assigns a free
  ephemeral port.
- Whilst convenient, there is a small possibility that this port may not
  be available on all daemons.
- It is hence preferable to specify a specific port that has been
  whitelisted for use, where possible.

For example, if `local_url(tcp = TRUE, port = 5555)` is specified, the
tunnel is created using port 5555 on each machine. The host listens to
`127.0.0.1:5555` on its side, and the daemons each dial into
`127.0.0.1:5555` on their own respective machines.

The below example launches 2 daemons on the remote machine 10.75.32.90
using SSH tunnelling:

``` r
daemons(
  n = 2,
  url = local_url(tcp = TRUE),
  remote = ssh_config("ssh://10.75.32.90", tunnel = TRUE)
)
```

#### HPC Cluster Resource Managers

[`cluster_config()`](https://mirai.r-lib.org/dev/reference/cluster_config.md)
may be used to deploy daemons using a cluster resource manager /
scheduler.

1.  The first argument is `command`. This should be:

- `"sbatch"` if using Slurm
- `"qsub"` if using SGE / Torque / PBS
- `"bsub"` if using LSF.

2.  The second argument `options` are any options that you would
    normally supply in a shell script to pass to the scheduler. These
    are script lines typically preceded by a `#`.

&nbsp;

      Slurm: "#SBATCH --job-name=mirai
              #SBATCH --mem=10G
              #SBATCH --output=job.out"
      SGE: "#$ -N mirai
            #$ -l mem_free=10G
            #$ -o job.out"
      Torque/PBS: "#PBS -N mirai
                   #PBS -l mem=10gb
                   #PBS -o job.out"
      LSF: "#BSUB -J mirai
            #BSUB -M 10000
            #BSUB -o job.out"

- As per the above, it is fine to pass this as a character string with
  the options each on a new line (whitespace is automatically handled),
  or else by explicitly using `\n` to denote a newline.
- Other shell commands, for example to change working directory, may
  also be included.
- For the avoidance of doubt, the initial shebang line of a script such
  as `#!/bin/bash` should be omitted.
- For certain HPC setups, a final line which loads environment modules
  may be needed. This would usually be of the form:

&nbsp;

    module load R

or for a specific R version:

    module load R/4.5.0

3.  The third argument `rscript` defaults to `"Rscript"`, which assumes
    that R is on the file search path. This may be substituted for the
    full path to a specific R executable, such as that returned by
    `file.path(R.home("bin"), "Rscript")`.

##### Job Arrays

If launching large numbers of daemons, it is often more appropriate to
submit a single job to the cluster scheduler that launches daemons via a
job array, rather than sending multiple individual jobs to the cluster.

So instead of:

``` r
daemons(n = 100, url = host_url(), remote = cluster_config())
```

rather use:

``` r
daemons(
  n = 1,
  url = host_url(),
  remote = cluster_config(options = "#SBATCH --array=1-100")
)
```

#### Generic Remote Configuration

[`remote_config()`](https://mirai.r-lib.org/dev/reference/remote_config.md)
provides a generic, flexible framework for running any shell command
that may be used to deploy daemons.

Conceptually, this function takes an `args` argument, which must contain
“.”. The correctly-configured call to
[`daemon()`](https://mirai.r-lib.org/dev/reference/daemon.md) is
substituted in for this “.”, so that `command` is run with this as one
of its arguments.

This can provide an alternative for cluster resource managers in certain
cases, although
[`cluster_config()`](https://mirai.r-lib.org/dev/reference/cluster_config.md)
provides an easier and more complete interface. Using Slurm as an
example, the following uses `sbatch` to launch a daemon on the cluster,
with some additional Slurm options passed via command line arguments to
`sbatch`:

``` r
daemons(
  n = 2,
  url = host_url(),
  remote = remote_config(
    command = "sbatch",
    args = c("--mem 512", "-n 1", "--wrap", "."),
    rscript = file.path(R.home("bin"), "Rscript"),
    quote = TRUE
  )
)
```

#### Manual Deployment

As an alternative to automated launches, calling
[`launch_remote()`](https://mirai.r-lib.org/dev/reference/launch_local.md)
without specifying ‘remote’ may be used to return the shell commands for
deploying daemons manually.

The printed return values may then be copy / pasted directly to a remote
machine e.g. via a terminal session.

``` r
daemons(url = host_url())
launch_remote()
#> [1]
#> Rscript -e 'mirai::daemon("tcp://192.168.1.71:32913")'
daemons(0)
```

### 7. TLS Secure Connections

TLS provides a robust solution for securing communications from the
local machine to remote daemons.

#### Automatic Zero-configuration Default

Simply specify a secure URL using the scheme `tls+tcp://` when setting
daemons, or use `host_url(tls = TRUE)`, for example:

``` r
daemons(url = host_url(tls = TRUE))
```

Single-use keys and certificates are automatically generated and
configured, without requiring any further intervention. The private key
is always retained on the host machine and never transmitted.

The generated self-signed certificate is available via
[`launch_remote()`](https://mirai.r-lib.org/dev/reference/launch_local.md),
where it is included as part of the shell command for manually launching
a daemon on a remote machine.

``` r
launch_remote(1)
#> [1]
#> Rscript -e 'mirai::daemon("tls+tcp://192.168.1.71:35195",tlscert=c("-----BEGIN CERTIFICATE-----
#> MIIFPzCCAyegAwIBAgIBATANBgkqhkiG9w0BAQsFADA3MRUwEwYDVQQDDAwxOTIu
#> MTY4LjEuNzExETAPBgNVBAoMCE5hbm9uZXh0MQswCQYDVQQGEwJKUDAeFw0wMTAx
#> MDEwMDAwMDBaFw0zMDEyMzEyMzU5NTlaMDcxFTATBgNVBAMMDDE5Mi4xNjguMS43
#> MTERMA8GA1UECgwITmFub25leHQxCzAJBgNVBAYTAkpQMIICIjANBgkqhkiG9w0B
#> AQEFAAOCAg8AMIICCgKCAgEA57RHHeW3t3PaAhcV/OPHB6qisQbsrz509SS4pRkB
#> XMlFAaTisdC9XTjg4GVSpTr1E+tO0N4ecf4P9r0ErfxsrnTh/7lIHgyW1I/3NYra
#> DPKlrGtAZyNTxoBFKtuN6YOLltXMC5UNPAUnmEh6FZ464Qypr0Yi4e1bov7/P01F
#> ibZLMPnxO+GZxJLcfXHit6lnDSTzGDIN9odhTTlIuSOM/vjy6f05Dbhg3+ImMbAL
#> gC8XmpUTsjO+RQvGkZwwaRV+kImUmSfTibwXv82eI5KE0vt+SpSJ+RptC7Raelt7
#> lP9+72Rg+bk2wfStbgWqtHn8n+5s33RUZVV8rH3wCdFUqnGbzV0RRoFW4iHKVhrg
#> bL6JinV6NZRy9i+eP78oD7QMJJeEzrIfMPPvoqpCo5vJufIHkuRYhhq86TaVc9hy
#> pRfRLmpdKOHctXS4DmSBMea8u4ou+EhCU1NqKMM7DOlCc79NaKKkE+E7Oshco1tf
#> ALjsebDAphjZEtk5XfbDYeEunno0Nn39PK64WTVo005v6CNs2joWL772PycJ2nJA
#> lrZg7S7nVkTaYKYHVOsui32LxCqrwqUirhg2/iik5TCjGO9gcfJJEVWwHZElZVbM
#> n/s5XRYLzhU8tb+FZT20UfURQ2TviAPk7bwUl13Fb1Td9+ft50KxOCPdmUPdRUw6
#> u2sCAwEAAaNWMFQwEgYDVR0TAQH/BAgwBgEB/wIBADAdBgNVHQ4EFgQUXW/eNoRp
#> aiGLZnEvMFtDXrdbTNkwHwYDVR0jBBgwFoAUXW/eNoRpaiGLZnEvMFtDXrdbTNkw
#> DQYJKoZIhvcNAQELBQADggIBAH+7tu2zOf0uHnwX9STGg5O5ElHk5xtUTIpQrMBf
#> GRvAkCq5XSxzWkfpu30P0rO1+mlDJ/F3Jnww0oRePssbCJqYdaH/lAjs6nwpjSav
#> cGW558THAH+jrYWMhdF9CkwypHGmN3MOkgQJBECSYQIvGXYX8+t5h8GVrBE6KPol
#> 1uof3HAYpRws2F6f9pghFsL+LFixJd+LNe1a9dwXcwz5ooKBXu+M90xY2BBVmK3j
#> eWYUGucshPhP1F7AjhuVTfW5nHd1bkkH0CSGyMpjasiwDPjQeG+NzeBZsMuPQjV1
#> 50vR5YiLLRZrk0yO30+Se54iaVJ+7PJfZVxdrmWpf9Lq+P27nXsSueeSVQCUej4Z
#> M5nhdLCug6mF7vcMUnNiS6iyvOh83XSsKBBC1qFX8zkSp37brDt0PDud9JWvOjYo
#> SxZ2okH2RmyfT66MxE8uiB1pNpCbw8DsRy2klW8vAqGiOXf9dz6vOaINR77yXMqQ
#> 64s5649BgPtHe+FC4oi49KTeYrEvLJyU5hjismj5iMQz6GPUOB8OKySGDf+73KzA
#> pWxlzLGPLJQJuXtk2od6Y7GIJjnRy2397riA0IU7hqCLjc3JIxnY6z9ACaLGbv02
#> GqcsyWTrvsJh4tBS+e7jM5fHX3w9R5RtcdHPTvz7F2bdrr83MQeld9RQ7Cwzv73n
#> Us0K
#> -----END CERTIFICATE-----
#> ",""))'
```

``` r
daemons(0)
```

#### CA Signed Certificates

As an alternative to the zero-configuration default, a certificate may
also be generated via a Certificate Signing Request (CSR) to a
Certificate Authority (CA). The CA may be a public CA or internal to an
organisation.

1.  Generate a private key and CSR. The following resources describe how
    to do so:

- using Mbed TLS:
  <https://mbed-tls.readthedocs.io/en/latest/kb/how-to/generate-a-certificate-request-csr/>
- using OpenSSL:
  <https://www.feistyduck.com/library/openssl-cookbook/online/> (Chapter
  1.2 Key and Certificate Management)

2.  Provide the generated CSR to the CA for it to sign a new TLS
    certificate.

- The common name (CN) of the certificate must be identical to the
  hostname or IP address actually used for the connection. As this is
  verified, it will fail if not the same.
- The received certificate should comprise a block of cipher text
  between the markers `-----BEGIN CERTIFICATE-----` and
  `-----END CERTIFICATE-----`. Make sure to request the certificate in
  the PEM format. If only available in other formats, the TLS library
  used should usually provide conversion utilities.
- Check also that the private key is a block of cipher text between the
  markers `-----BEGIN PRIVATE KEY-----` and `-----END PRIVATE KEY-----`.

3.  When setting daemons, the TLS certificate and private key should be
    provided to the ‘tls’ argument of
    [`daemons()`](https://mirai.r-lib.org/dev/reference/daemons.md).

- If the certificate and private key have been imported as character
  strings `cert` and `key` respectively, then the ‘tls’ argument may be
  specified as the character vector `c(cert, key)`.
- Alternatively, the certificate may be copied to a new text file, with
  the private key appended, in which case the path/filename of this file
  may be provided to the ‘tls’ argument.

4.  The certificate chain to the CA should be supplied to the ‘tlscert’
    argument of
    [`daemons()`](https://mirai.r-lib.org/dev/reference/daemons.md).

- The certificate chain should comprise multiple certificates, each
  between `-----BEGIN CERTIFICATE-----` and `-----END CERTIFICATE-----`
  markers. The first one should be the newly-generated TLS certificate,
  the same supplied to
  [`daemons()`](https://mirai.r-lib.org/dev/reference/daemons.md), and
  the final one should be a CA root certificate.
- These are the only certificates required if the certificate was signed
  directly by a CA. If not, then the intermediate certificates should be
  included in a certificate chain that starts with the TLS certificate
  and ends with the certificate of the CA.
- If these are concatenated together as a single character string
  `certchain`, then the character vector comprising this and an empty
  character string `c(certchain, "")` may be supplied to ‘tlscert’.
- Alternatively, if these are written to a file (and the file replicated
  on the remote machines), then the ‘tlscert’ argument may also be
  specified as a path/filename (assuming these are the same on each
  machine).

### 8. Compute Profiles

[`daemons()`](https://mirai.r-lib.org/dev/reference/daemons.md) has a
`.compute` argument to specify separate sets of daemons (*compute
profiles*) that operate totally independently. This is useful for
managing tasks with heterogeneous compute requirements:

- send tasks to different daemons or clusters of daemons with the
  appropriate specifications (in terms of CPUs / memory / GPU /
  accelerators etc.)
- split tasks between local and remote computation

Simply pass a character string to `.compute` to use as the profile name
(which, if `NULL`, is ‘default’). The daemons settings are saved under
the named profile.

To create a ‘mirai’ task using a specific compute profile, specify the
`.compute` argument to
[`mirai()`](https://mirai.r-lib.org/dev/reference/mirai.md), which uses
the ‘default’ compute profile if this is `NULL`.

Similarly, functions such as
[`status()`](https://mirai.r-lib.org/dev/reference/status.md),
[`launch_local()`](https://mirai.r-lib.org/dev/reference/launch_local.md)
or
[`launch_remote()`](https://mirai.r-lib.org/dev/reference/launch_local.md)
should be specified with the desired `.compute` argument.

#### `with_daemons()` and `local_daemons()`

Supplying a character compute profile to
[`with_daemons()`](https://mirai.r-lib.org/dev/reference/with_daemons.md)
or
[`local_daemons()`](https://mirai.r-lib.org/dev/reference/with_daemons.md)
automatically sets the default compute profile for all package functions
within the relevant scope.

``` r
daemons(1, .compute = "cpu")
daemons(1, .compute = "gpu")

with_daemons("cpu", {
  s1 <- status()
  m1 <- mirai(Sys.getpid())
})

with_daemons("gpu", {
  s2 <- status()
  m2 <- mirai(Sys.getpid())
  m3 <- mirai(Sys.getpid(), .compute = "cpu")
  local_daemons("cpu")
  m4 <- mirai(Sys.getpid())
})

s1$daemons
#> [1] "abstract://2e74c4d66f68a08bb316d38c"
m1[]
#> [1] 64123

s2$daemons
#> [1] "abstract://d6f72911a8e7626734a9ea87"
m2[] # different to m1
#> [1] 64209

m3[] # same as m1
#> [1] 64123
m4[] # same as m1
#> [1] 64123

with_daemons("cpu", daemons(0))
with_daemons("gpu", daemons(0))
```

#### With Method

[`daemons()`](https://mirai.r-lib.org/dev/reference/daemons.md) also has
a [`with()`](https://rdrr.io/r/base/with.html) method, which evaluates
an expression with daemons created for the duration of the expression
and automatically reset upon completion. All package functions within
the [`with()`](https://rdrr.io/r/base/with.html) scope default to using
the compute profile of the daemons created.

It was originally designed for running a Shiny app with the desired
number of daemons, as in the example below:

``` r
with(daemons(4), shiny::runApp(app))
# Or:
with(daemons(4, .compute = "shiny"), shiny::runApp(app))
```

> Note: it is assumed the app is already created. Wrapping a call to
> `shiny::shinyApp()` would not work as `runApp()` is implicitly called
> when the app is printed, however printing occurs only after
> [`with()`](https://rdrr.io/r/base/with.html) has returned, hence the
> app would run outside of the scope of the
> [`with()`](https://rdrr.io/r/base/with.html) statement.

In the case of a Shiny app, all mirai calls will be executed before the
app returns as the app itself is blocking. In the case of other
expressions, be sure to call or collect the values of all mirai within
the expression to ensure that they all complete before the daemons are
reset.

### 9. Synchronous Mode

`daemons(sync = TRUE)` turns on synchronous mode for the default compute
profile. This causes mirai to be evaluated immediately after creation,
and before they return, with no asynchronous operation. This can be
useful for testing and debugging purposes. In particular, it allows you
to drop into an interactive browser session from a
[`browser()`](https://rdrr.io/r/base/browser.html) statement inside your
mirai expression.

To restrict synchronous behaviour to a specific compute profile,
additionally specify `.compute`. A value of `seed` may be supplied for
reproducible parallel RNG, but all other arguments have no effect when
specifying `sync = TRUE`.

Example usage:

``` r
# run everything in sync:
daemons(sync = TRUE)
mp <- mirai_map(1:2, \(x) Sys.getpid())
daemons(0)
mp[]
#> [[1]]
#> [1] 62512
#> 
#> [[2]]
#> [1] 62512


# Use sync with the 'sync' compute profile:
daemons(sync = TRUE, .compute = "sync")
with_daemons("sync", {
  mp <- mirai_map(1:2, \(x) Sys.getpid())
})
daemons(0, .compute = "sync")
mp[]
#> [[1]]
#> [1] 62512
#> 
#> [[2]]
#> [1] 62512
```
