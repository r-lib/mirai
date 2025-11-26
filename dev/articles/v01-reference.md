# mirai - Reference Manual

This is a reference vignette of the package’s core functionality. Other
package vignettes cover additional features.

### 1. Introduction

mirai (Japanese for ‘future’) implements the concept of *futures* in R.

Futures represent results from code that will complete later. Code
executes in a separate R process (*daemon*) and returns results to the
main process (*host*).

#### mirai

[`mirai()`](https://mirai.r-lib.org/dev/reference/mirai.md) creates a
mirai object from an expression.

It returns immediately without blocking. While the expression evaluates
on a daemon, the host process continues working.

Expressions must be self-contained:

- Package functions must be namespaced with `::` or loaded via
  [`library()`](https://rdrr.io/r/base/library.html) within the
  expression.
- Pass required functions, data, or objects explicitly via `...` or
  `.args`.

> This explicit design perfectly matches message-passing parallelism -
> attempting to infer global variables introduces unreliability, which
> we do not compromise on.

This example mimics an expensive calculation:

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
#> [1] 6.218842 3.650785 3.958701 4.108253 4.619849
m$data
#> [1] 6.218842 3.650785 3.958701 4.108253 4.619849
```

A mirai is *unresolved* until its result is received, then *resolved*.
Use
[`unresolved()`](https://mirai.r-lib.org/dev/reference/unresolved.md) to
check its state.

Access results via `m$data` once resolved. This will be the return
value, or an ‘errorValue’ if the expression errored, crashed, or timed
out (see [Error Handling](#error-handling)).

Use `m[]` to efficiently wait for and collect the value instead of
repeatedly checking `unresolved(m)`.

You may also wait efficiently for mirai (or lists of mirai) to resolve
using:

- [`call_mirai()`](https://mirai.r-lib.org/dev/reference/call_mirai.md)
  returns when all the mirai passed to it have resolved.
- [`race_mirai()`](https://mirai.r-lib.org/dev/reference/race_mirai.md)
  returns when the first mirai passed to it has resolved.

#### mirai (advanced)

For programmatic use, ‘.expr’ accepts a pre-constructed language object
and ‘.args’ accepts a named list of arguments. The following is
equivalent:

``` r
expr <- quote({Sys.sleep(time); rnorm(5L, mean)})
args <- list(time = 2L, mean = 4)

m1 <- mirai(.expr = expr, .args = args)
m1[]
#> [1] 3.901930 3.121547 3.593815 2.947067 4.729572
```

This example performs an asynchronous write operation. Passing
[`environment()`](https://rdrr.io/r/base/environment.html) to ‘.args’
conveniently provides all objects from the calling environment (like `x`
and `file`):

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
[`mirai()`](https://mirai.r-lib.org/dev/reference/mirai.md) call, don’t
worry about where or how it executes. End-users declare available
resources using
[`daemons()`](https://mirai.r-lib.org/dev/reference/daemons.md).

Without daemons configured, each
[`mirai()`](https://mirai.r-lib.org/dev/reference/mirai.md) call creates
a new local background process (*ephemeral daemon*).

[`daemons()`](https://mirai.r-lib.org/dev/reference/daemons.md) sets up
persistent daemons to evaluate mirai expressions:

- Eliminates process startup overhead and limits concurrent processes.
- Cleanup between evaluations ensures each mirai remains self-contained.

See [local daemons](#local-daemons) for setup instructions.

### 2. Error Handling

Errors return as a character string with classes ‘miraiError’ and
‘errorValue’.

Use
[`is_mirai_error()`](https://mirai.r-lib.org/dev/reference/is_mirai_error.md)
to test for errors:

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

Error objects include `$stack.trace` for full stack traces and
`$condition.class` for original condition classes:

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

Original error condition elements and
[`rlang::abort()`](https://rlang.r-lib.org/reference/abort.html)
metadata are preserved:

``` r
f <- function(x) if (x > 0) stop("positive")

m4 <- mirai(rlang::abort("aborted", meta_uid = "UID001"))
m4[]
#> 'miraiError' chr Error: aborted

m4$data$meta_uid
#> [1] "UID001"
```

User interrupts resolve to class ‘miraiInterrupt’ and ‘errorValue’. Use
[`is_mirai_interrupt()`](https://mirai.r-lib.org/dev/reference/is_mirai_error.md)
to test for interrupts:

``` r
m4 <- mirai(rlang::interrupt()) # simulates a user interrupt
is_mirai_interrupt(m4[])
#> [1] TRUE
```

Timeouts (via ‘.timeout’) resolve to ‘errorValue’ of 5L, guarding
against hanging processes:

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

### 3. Local Daemons

Daemons are persistent background processes that receive
[`mirai()`](https://mirai.r-lib.org/dev/reference/mirai.md) requests.

> Daemons inherit system configuration (‘.Renviron’, ‘.Rprofile’) and
> load default packages. To load only the base package (cutting startup
> time in half), set `R_SCRIPT_DEFAULT_PACKAGES=NULL` before launching.

Specify the number of daemons to launch:

``` r
daemons(6)
```

Set `n` to one less than available cores for optimal performance.
Consider cores reserved for other purposes.

#### With Dispatcher (default)

The default `dispatcher = TRUE` creates a background dispatcher process
that manages daemon connections. Tasks dispatch efficiently in FIFO
order, queueing at the dispatcher and sending to daemons as they become
available. The event-driven approach consumes no resources while waiting
and stays synchronized with events.

[`info()`](https://mirai.r-lib.org/dev/reference/info.md) provides
current statistics as an integer vector:

- `connections`: currently active daemons
- `cumulative`: total daemons ever connected
- `awaiting`: tasks queued at dispatcher
- `executing`: tasks currently evaluating
- `completed`: tasks completed or cancelled

``` r
info()
#> connections  cumulative    awaiting   executing   completed 
#>           6           6           0           0           0
```

[`status()`](https://mirai.r-lib.org/dev/reference/status.md) provides
more detail:

1.  `connections`: active connections
2.  `daemons`: connection URL
3.  `mirai`: task summary

``` r
status()
#> $connections
#> [1] 6
#> 
#> $daemons
#> [1] "ipc:///tmp/43df2d10f7016fe4c9bdc344"
#> 
#> $mirai
#>  awaiting executing completed 
#>         0         0         0
```

Set daemons to zero to reset. This reverts to creating a new background
process per request.

``` r
daemons(0)
```

#### Without Dispatcher

With `dispatcher = FALSE`, daemons connect directly to the host process:

``` r
daemons(6, dispatcher = FALSE)
```

Tasks send immediately in round-robin fashion, ensuring even
distribution. However, scheduling isn’t optimal since task duration is
unknown beforehand. Tasks may queue behind long-running tasks while
other daemons sit idle.

This resource-light approach suits similar-length tasks or when
concurrent tasks don’t exceed available daemons.

Status now shows 6 connections and the host URL:

``` r
status()
#> $connections
#> [1] 6
#> 
#> $daemons
#> [1] "ipc:///tmp/f7d6e9c065c1e179c922f75a"
```

#### everywhere()

[`everywhere()`](https://mirai.r-lib.org/dev/reference/everywhere.md)
evaluates expressions on all daemons and persists state regardless of
cleanup settings:

``` r
everywhere(library(DBI))
```

This keeps the [`DBI`](https://dbi.r-dbi.org/) package loaded. You can
also set up common resources like database connections:

``` r
everywhere(con <<- dbConnect(RSQLite::SQLite(), file), file = tempfile())
```

Super-assignment makes ‘con’ available globally in all daemons:

``` r
mirai(exists("con"))[]
#> [1] TRUE
```

Disconnect everywhere:

``` r
everywhere(dbDisconnect(con))
```

> To evaluate in the global environment of each daemon (since mirai
> evaluations occur in an environment inheriting from global), use
> `evalq(envir = globalenv())`. Example with `box::use()`:

``` r
everywhere(
  evalq(
    box::use(dplyr[select], mirai[...]),
    envir = globalenv()
  )
)

daemons(0)
```

### 4. mirai_map

[`mirai_map()`](https://mirai.r-lib.org/dev/reference/mirai_map.md)
performs asynchronous parallel mapping over lists or vectors.

> Requires
> [`daemons()`](https://mirai.r-lib.org/dev/reference/daemons.md) to be
> set (avoids launching too many ephemeral daemons).

#### Basic Usage

Returns immediately. Collect results with `x[]`:

``` r
with(daemons(3, seed = 1234L), mirai_map(1:3, rnorm, .args = list(mean = 20, sd = 2))[])
#> [[1]]
#> [1] 19.86409
#> 
#> [[2]]
#> [1] 19.55834 22.30159
#> 
#> [[3]]
#> [1] 20.62193 23.06144 19.61896
```

Use `.args` for constant arguments to `.f`, and `...` for objects
referenced in `.f`:

``` r
daemons(4, seed = 2345L)
fn <- function(x, range) runif(x, x, x + range)
ml <- mirai_map(c(a = 1, b = 2, c = 3), \(x) fn(x, x * 2), fn = fn)
ml
#> < mirai map [0/3] >
ml[]
#> $a
#> [1] 2.637793
#> 
#> $b
#> [1] 2.328183 5.649959
#> 
#> $c
#> [1] 5.302906 3.531788 6.389231
```

#### Collecting Options

- `x[.flat]` flattens results (checks types to avoid coercion)
- `x[.progress]` shows progress bar (via cli) or text indicator
- `x[.stop]` applies early stopping, cancelling remaining tasks on first
  failure

``` r
mirai_map(list(a = 1, b = "a", c = 3), function(x) exp(x))[.stop]
#> Error in `mirai_map()`:
#> ℹ In index: 2.
#> ℹ With name: b.
#> Caused by error in `exp()`:
#> ! non-numeric argument to mathematical function

mirai_map(c(0.1, 0.2, 0.3), Sys.sleep)[.progress, .flat]
#> NULL
```

#### Multiple Map

Dataframes and matrices map over **rows**. `.f` must accept as many
arguments as there are columns:

``` r
fruit <- c("melon", "grapes", "coconut")
df <- data.frame(i = seq_along(fruit), fruit = fruit)

mirai_map(df, sprintf, .args = list(fmt = "%d. %s"))[.flat]
#> [1] "1. melon"   "2. grapes"  "3. coconut"
```

Matrices also map over rows:

``` r
mat <- matrix(1:4, nrow = 2L, dimnames = list(c("a", "b"), c("y", "z")))
mirai_map(mat, function(x = 10, y = 0, z = 0) x + y + z)[.flat]
#>  a  b 
#> 14 16

daemons(0)
```

> To map over columns instead, use
> [`as.list()`](https://rdrr.io/r/base/list.html) for dataframes or
> [`t()`](https://rdrr.io/r/base/t.html) for matrices.

#### Nested Maps

For nested mapping, don’t launch local daemons from within
[`mirai_map()`](https://mirai.r-lib.org/dev/reference/mirai_map.md).
Instead:

``` r
daemons(url = local_url())
launch_local(n)
```

### 5. Remote Infrastructure

This section covers setting up remote daemons, launching them on remote
machines, and securing connections with TLS.

#### Remote Daemons Overview

Remote daemons run on network machines to process tasks remotely.

Call [`daemons()`](https://mirai.r-lib.org/dev/reference/daemons.md)
with a ‘url’ (e.g., ‘tcp://10.75.32.70:5555’) or use
[`host_url()`](https://mirai.r-lib.org/dev/reference/host_url.md) to
construct one automatically. The host listens on a single port for
daemons to connect.

> IPv6 addresses are also supported and must be enclosed in square
> brackets `[]` to avoid confusion with the final colon separating the
> port. For example, port 5555 on the IPv6 address `::ffff:a6f:50d`
> would be specified as `tcp://[::ffff:a6f:50d]:5555`.

Calling
[`host_url()`](https://mirai.r-lib.org/dev/reference/host_url.md)
without a port uses ‘0’, which automatically assigns a free ephemeral
port:

``` r
daemons(url = host_url())
```

Query the assigned port with
[`status()`](https://mirai.r-lib.org/dev/reference/status.md):

``` r
status()
#> $connections
#> [1] 0
#> 
#> $daemons
#> [1] "tcp://10.216.62.38:49515"
#> 
#> $mirai
#>  awaiting executing completed 
#>         0         0         0
```

Dynamically scale the number of daemons up or down as needed.

Reset all connections:

``` r
daemons(0)
```

Closing connections exits all daemons. With dispatcher, this exits the
dispatcher first, then all connected daemons.

#### Launching Remote Daemons

> Launchers deploy daemons on remote machines. Once deployed, daemons
> connect back to the host via TCP or TLS.

Local launchers run `Rscript` via a local shell. Remote launchers run
`Rscript` on remote machines.

Supply a remote launch configuration to the ‘remote’ argument of
[`daemons()`](https://mirai.r-lib.org/dev/reference/daemons.md) or
[`launch_remote()`](https://mirai.r-lib.org/dev/reference/launch_local.md).

Three configuration options:

1.  [`ssh_config()`](https://mirai.r-lib.org/dev/reference/ssh_config.md)
    for SSH access
2.  [`cluster_config()`](https://mirai.r-lib.org/dev/reference/cluster_config.md)
    for HPC resource managers (Slurm, SGE, Torque/PBS, LSF)
3.  [`remote_config()`](https://mirai.r-lib.org/dev/reference/remote_config.md)
    for generic/custom launchers

All return simple lists that can be pre-constructed, saved, and reused.

#### SSH Direct Connection

Use for internal networks where the host can accept incoming
connections. Remote daemons connect back directly to the host port.

TLS is recommended for additional security.

Launch 4 daemons on 10.75.32.90 (SSH port 22 is default):

``` r
daemons(
  n = 4,
  url = host_url(tls = TRUE, port = 5555),
  remote = ssh_config("ssh://10.75.32.90")
)
```

Launch one daemon on each machine using custom SSH port 222:

``` r
daemons(
  n = 1,
  url = host_url(tls = TRUE, port = 5555),
  remote = ssh_config(c("ssh://10.75.32.90:222", "ssh://10.75.32.91:222"))
)
```

#### SSH Tunnelling

Use SSH tunnelling when firewall policies prevent direct connections.
Requires SSH key-based authentication to be setup.

SSH tunnelling creates a tunnel after the initial SSH connection, using
the same port on both host and daemon.

Supply a ‘127.0.0.1’ URL to
[`daemons()`](https://mirai.r-lib.org/dev/reference/daemons.md):

- `local_url(tcp = TRUE)` constructs this automatically
- Default wildcard port ‘0’ assigns a free ephemeral port
- Specify a whitelisted port if the ephemeral port might be unavailable
  on daemons

With `local_url(tcp = TRUE, port = 5555)`, the host listens at
`127.0.0.1:5555` and daemons dial into `127.0.0.1:5555` on their own
machines.

Launch 2 daemons on 10.75.32.90 with tunnelling:

``` r
daemons(
  n = 2,
  url = local_url(tcp = TRUE),
  remote = ssh_config("ssh://10.75.32.90", tunnel = TRUE)
)
```

#### HPC Cluster Resource Managers

[`cluster_config()`](https://mirai.r-lib.org/dev/reference/cluster_config.md)
deploys daemons via cluster resource managers.

Specify `command`: - `"sbatch"` for Slurm - `"qsub"` for
SGE/Torque/PBS - `"bsub"` for LSF

The `options` argument accepts scheduler options (lines typically
preceded by `#`):

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

- Pass as multi-line string (whitespace auto-handled) or use `\n` for
  newlines
- Include other shell commands (e.g., `cd` for working directory)
- Omit shebang lines (e.g., `#!/bin/bash`)
- Load environment modules if needed:

&nbsp;

    module load R

or for a specific R version:

    module load R/4.5.0

The `rscript` argument defaults to `"Rscript"` (assumes R is on PATH).
Specify full path if needed: `file.path(R.home("bin"), "Rscript")`.

##### Job Arrays

For many daemons, use job arrays instead of individual jobs.

Instead of:

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
provides a generic framework for custom deployment commands.

The `args` argument must contain `"."`, which is replaced with the
daemon launch command.

[`cluster_config()`](https://mirai.r-lib.org/dev/reference/cluster_config.md)
is easier for HPC, but
[`remote_config()`](https://mirai.r-lib.org/dev/reference/remote_config.md)
offers flexibility. Slurm example:

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

Call
[`launch_remote()`](https://mirai.r-lib.org/dev/reference/launch_local.md)
without ‘remote’ to get shell commands for manual deployment:

``` r
daemons(url = host_url())
launch_remote()
#> [1]
#> Rscript -e 'mirai::daemon("tcp://10.216.62.38:49516")'
daemons(0)
```

#### TLS Secure Connections

TLS secures communications between host and remote daemons.

##### Automatic Zero-configuration Default

Use `tls+tcp://` scheme or `host_url(tls = TRUE)`:

``` r
daemons(url = host_url(tls = TRUE))
```

Keys and certificates generate automatically. Private keys remain on the
host.

Self-signed certificates are included in
[`launch_remote()`](https://mirai.r-lib.org/dev/reference/launch_local.md)
commands:

``` r
launch_remote(1)
#> [1]
#> Rscript -e 'mirai::daemon("tls+tcp://10.216.62.38:49517",tlscert=c("-----BEGIN CERTIFICATE-----
#> MIIFPzCCAyegAwIBAgIBATANBgkqhkiG9w0BAQsFADA3MRUwEwYDVQQDDAwxMC4y
#> MTYuNjIuMzgxETAPBgNVBAoMCE5hbm9uZXh0MQswCQYDVQQGEwJKUDAeFw0wMTAx
#> MDEwMDAwMDBaFw0zMDEyMzEyMzU5NTlaMDcxFTATBgNVBAMMDDEwLjIxNi42Mi4z
#> ODERMA8GA1UECgwITmFub25leHQxCzAJBgNVBAYTAkpQMIICIjANBgkqhkiG9w0B
#> AQEFAAOCAg8AMIICCgKCAgEAydxZw07AviS9yZjnYP9PL+x/TA5RGEbm+G0Iobct
#> ML2a/t8pk+cJ/hwpB8HA0i7eoc52Km8TCz2hturtGe3BS0mvvnzipcs9k2pxga6o
#> 3sqbLXvI19sC/CMu5gUWOU9dcFh6BYavVLpUW4j0xjjcXAr4PBBIjF+/Lt5FNWuZ
#> srPKC7Q6/ay7b8bFANEcYwZWkoXlWqhY/8EmOqECA97cdCybkfXcIFRU2SFMTQtx
#> NbpHqXWvtGKRQxwvYcfnlkLyQwJZr3CsB10gdPCeoXVPKCJf+ZoPQDGA2BH1jdHx
#> sxUVMIg9skMdciGHWM/zu+7urXn7HFMoMmXfSnsQSgJ46EnJSEqFQ5W2ZIstfnQE
#> tIZFmJqyIr3D6NOvwdk54lK7CkfWr17tcvWlTUhxRsJzR3/rWnQKAIx/R+eMsPfK
#> fP8ajpxhFXsfnyZF0U3onvU2L6qjKSUyj3NS4lpb85T5LN56Kp7OauZiqXNBV7b5
#> PCdgSMJljRSXYolMjk7B7KA1LbMigMJwLN5KfnvwUswS6B24XI4F2NmUJXe2nec7
#> Cy7iCiUYI2O1v2MKn0xWUHuJW21EJtPXoNBOBFA6Bpz93/Wf0m6MbSjUH7rf8Xgo
#> accxoffGXlE3oKwO/BMbbNwtHMupsdu5MMyv8TGD8F2NqE7b1eT57oDVkfzjGjwR
#> b1sCAwEAAaNWMFQwEgYDVR0TAQH/BAgwBgEB/wIBADAdBgNVHQ4EFgQU7J2cGBmo
#> ZcqDzBVYVQLcQUCQ5ccwHwYDVR0jBBgwFoAU7J2cGBmoZcqDzBVYVQLcQUCQ5ccw
#> DQYJKoZIhvcNAQELBQADggIBAHhjNztuQAaPsKKZWweaIY06jak24YsSG64zJBGj
#> dbMta7s4r4Sj8DaidEQMcVl4FeVO/3ZLtC9xDpq+QWQkj44Zi1gbOloEkbIy2TK7
#> cmfsPCP3sgjGt9+TAI2Fib5eBXHGH5eITCf99PBUC/rEHhd9LsBqih0gD0iRVZw8
#> PD7KiVUK6R5f0dpGfVvl4l0HEpOFNnq23w6JGZeyMmHbknW6o62VTh+7FtBEci6E
#> wwBoUK6lTujzDK3jTLdAPVipTad6yIBK1wgQBfWuGB8/U4Sbr9ji/+sQ5Yp9rUP6
#> aQis8f+KOmj2mxqsEj/NYwm22BmwufAy/5RmXg3S9gdfg2Lf3g73cJZOppd5B/AH
#> dL4G2Iym1c8PcT1UkkKDIIzfTHxV4vvyUsqoNX5aJcbmp/Qla7aXkO69ilkDzIjT
#> AypracLmZzve8NYtws196/bc1Lk93ezaER+AWODxCoquUDWjl2ybFrfnWhqJ1Z96
#> nK8w4u0LvA6D4JG1lG15XykY/CIj91rRpIaijg3qi0pAoU340YgiT5cKn6tOmBNe
#> EdPlZKBazZ3TXTST5NwiMEslLKyKj9htOEIfO0gDKwvb82bazG7SEn1bjxyvGCMb
#> DLZFvTcRrv+OT6sFYe8ii1umnwuI+PuRAboyU4ltTSoUaIV0kEvkFTzQBZf5mvrY
#> b8kO
#> -----END CERTIFICATE-----
#> ",""))'
```

``` r
daemons(0)
```

##### CA Signed Certificates

Alternatively, generate certificates via a Certificate Signing Request
(CSR) to a Certificate Authority (public or internal).

1.  Generate a private key and CSR:

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

### 6. Compute Profiles

The `.compute` argument to
[`daemons()`](https://mirai.r-lib.org/dev/reference/daemons.md) creates
separate, independent daemon sets (*compute profiles*) for heterogeneous
compute requirements:

- Target daemons with specific specs (CPUs, memory, GPU, accelerators)
- Split between local and remote computation

Pass a character string to `.compute` as the profile name (`NULL`
defaults to ‘default’). Settings save under this name.

Specify `.compute` in
[`mirai()`](https://mirai.r-lib.org/dev/reference/mirai.md) to use a
profile (`NULL` uses ‘default’).

Other functions
([`status()`](https://mirai.r-lib.org/dev/reference/status.md),
[`launch_local()`](https://mirai.r-lib.org/dev/reference/launch_local.md),
[`launch_remote()`](https://mirai.r-lib.org/dev/reference/launch_local.md))
also accept `.compute`.

#### `with_daemons()` and `local_daemons()`

[`with_daemons()`](https://mirai.r-lib.org/dev/reference/with_daemons.md)
or
[`local_daemons()`](https://mirai.r-lib.org/dev/reference/with_daemons.md)
with a profile name sets the default for all functions within that
scope:

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
#> [1] "ipc:///tmp/79b5fc7a162b5413cdd1b0e6"
m1[]
#> [1] 12700

s2$daemons
#> [1] "ipc:///tmp/5710972c9d0d836a64e8c45a"
m2[] # different to m1
#> [1] 12726

m3[] # same as m1
#> [1] 12700
m4[] # same as m1
#> [1] 12700

with_daemons("cpu", daemons(0))
with_daemons("gpu", daemons(0))
```

#### With Method

The [`with()`](https://rdrr.io/r/base/with.html) method creates daemons
for an expression’s duration, then automatically resets them. Functions
within the scope use the daemons’ compute profile.

Designed for running Shiny apps with specific daemon counts:

``` r
with(daemons(4), shiny::runApp(app))
# Or:
with(daemons(4, .compute = "shiny"), shiny::runApp(app))
```

> Note: The app must already be created. Don’t wrap `shiny::shinyApp()`
> since `runApp()` is called when printed, after
> [`with()`](https://rdrr.io/r/base/with.html) returns.

Shiny apps execute all mirai calls before returning (blocking). For
other expressions, collect all mirai values to ensure completion before
daemon reset.

### 7. Advanced Topics

#### Random Number Generation

mirai uses L’Ecuyer-CMRG streams (like base R’s parallel package) for
statistically-sound parallel RNG.

Streams divide the RNG sequence at far-apart intervals that don’t
overlap, ensuring valid parallel results.

**Default (`seed = NULL`)**: New stream per daemon (like base R):

- Statistically sound but not numerically reproducible across runs
- Different daemon counts send tasks to different daemons
- Dispatcher sends tasks dynamically (not guaranteed same daemon each
  run)

**Reproducible (`seed = integer`)**: New stream per
[`mirai()`](https://mirai.r-lib.org/dev/reference/mirai.md) call (not
per daemon):

- Deterministic, reproducible results
- Regardless of daemon count
- Negligible performance impact

#### Synchronous Mode

`daemons(sync = TRUE)` enables synchronous mode. Mirai evaluate
immediately without async operation, useful for testing and debugging
with [`browser()`](https://rdrr.io/r/base/browser.html).

Restrict to a specific profile by specifying `.compute`. Only `seed`
affects behavior with `sync = TRUE`.

Example usage:

``` r
# run everything in sync:
daemons(sync = TRUE)
mp <- mirai_map(1:2, \(x) Sys.getpid())
daemons(0)
mp[]
#> [[1]]
#> [1] 4978
#> 
#> [[2]]
#> [1] 4978


# Use sync with the 'sync' compute profile:
daemons(sync = TRUE, .compute = "sync")
with_daemons("sync", {
  mp <- mirai_map(1:2, \(x) Sys.getpid())
})
daemons(0, .compute = "sync")
mp[]
#> [[1]]
#> [1] 4978
#> 
#> [[2]]
#> [1] 4978
```
