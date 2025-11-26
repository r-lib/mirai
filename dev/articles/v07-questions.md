# mirai - Community FAQs

This vignette provides answers to common questions from the community.

### 1. Migration from `future_promise()`

Translating Shiny ExtendedTask or async code from
[`promises::future_promise()`](https://rstudio.github.io/promises/reference/future_promise.html)
to mirai is straightforward.

[`future_promise()`](https://rstudio.github.io/promises/reference/future_promise.html)
exists because `future(...)` alone isn’t always async - it blocks when
parallel processes run out.
[`mirai()`](https://mirai.r-lib.org/dev/reference/mirai.md) is built as
an async framework, so use it directly in place of
[`future_promise()`](https://rstudio.github.io/promises/reference/future_promise.html).

**Globals:**

[`future_promise()`](https://rstudio.github.io/promises/reference/future_promise.html)
by default infers required global variables. If your code depended on
this, pass variables explicitly via `...` in
[`mirai()`](https://mirai.r-lib.org/dev/reference/mirai.md). A mirai
requires self-contained expressions with all variables or helper
functions explicitly supplied.

If your code used the `globals` argument, pass it directly to `.args` in
[`mirai()`](https://mirai.r-lib.org/dev/reference/mirai.md) (if it’s a
named list).

**Always pass globals explicitly.** This matches the behaviour of
multi-process parallelism and is suited for programmatic use. Automatic
globals detection creates an imperfect abstraction leading to
unpredictable edge cases or slower operation from sending unnecessary
data to daemons. Explicitly passing variables ensures reliable,
transparent behaviour.

**Capture globals using
[`environment()`](https://rdrr.io/r/base/environment.html):**

[`mirai()`](https://mirai.r-lib.org/dev/reference/mirai.md) accepts an
environment passed to `...` or `.args`. This is useful for Shiny
ExtendedTask invoked with arguments. Using
`mirai::mirai({...}, environment())` automatically captures variables
provided to the invoke method. See the Shiny vignette for examples.

**Special Case: `...`:**

A Shiny app may have used
[`future_promise()`](https://rstudio.github.io/promises/reference/future_promise.html)
code similar to the following within the server component:

``` r
func <- function(x, y){
  Sys.sleep(y)
  runif(x)
}

task <- ExtendedTask$new(
  function(...) future_promise(func(...))
) |> bind_task_button("btn")

observeEvent(input$btn, task$invoke(input$n, input$delay))
```

The equivalent in
[`mirai()`](https://mirai.r-lib.org/dev/reference/mirai.md) is achieved
by:

``` r
task <- ExtendedTask$new(
  function(...) mirai(func(...), func = func, .args = environment())
) |> bind_task_button("btn")
```

Note that here
[`environment()`](https://rdrr.io/r/base/environment.html) captures the
`...` that’s then used within the mirai expression.

### 2. Setting the random seed

This example may seem counter-intuitive: default ‘cleanup’ settings at
each daemon ensure global environment variables don’t carry over to
subsequent runs. This can be assumed to include `.Random.seed`.

``` r
library(mirai)
daemons(4)

vec <- 1:3
vec2 <- 4:6

# Returns different values: good
mirai_map(list(vec, vec2), \(x) rnorm(x))[]
#> [[1]]
#> [1]  0.001644678 -1.187782046 -0.297140635
#> 
#> [[2]]
#> [1] -0.7211057 -0.8825230 -0.9686437

# Set the seed in the function
mirai_map(list(vec, vec2), \(x) {
  set.seed(123)
  rnorm(x)
})[]
#> [[1]]
#> [1] -0.9685927  0.7061091  1.4890213
#> 
#> [[2]]
#> [1] -0.9685927  0.7061091  1.4890213

# Do not set the seed in the function: still identical results?
mirai_map(list(vec, vec2), \(x) rnorm(x))[]
#> [[1]]
#> [1] -1.8150926  0.3304096 -1.1421557
#> 
#> [[2]]
#> [1] -1.8150926  0.3304096 -1.1421557

daemons(0)
```

Random seed changes persist because mirai uses L’Ecuyer CMRG streams for
parallel-safe random numbers.

Streams are entry points on the pseudo-random number line, far apart to
ensure independent random results across daemons. The random seed isn’t
reset after each mirai call - this ensures that random draws continue
along the stream, maintaining desired statistical properties regardless
of how many draws occur per call.

**Set the random seed once on the host process when creating daemons,
not in each daemon.**

For numerical reproducibility, set the `seed` argument in
[`daemons()`](https://mirai.r-lib.org/dev/reference/daemons.md) (see
Random Number Generation in the reference vignette).

### 3. Accessing package functions during development

A mirai call usually requires package-namespaced functions. However,
development packages are often loaded dynamically by
`devtools::load_all()` or `pkgload::load_all()` for quick iteration.

Use
[`everywhere()`](https://mirai.r-lib.org/dev/reference/everywhere.md) to
call `devtools::load_all()` on all (local) daemons. They’ll then access
the same functions as your host session for subsequent
[`mirai()`](https://mirai.r-lib.org/dev/reference/mirai.md) calls.

### 4. Why does `mirai()` take time when it’s meant to return immediately?

A [`mirai()`](https://mirai.r-lib.org/dev/reference/mirai.md) call
returns almost instantaneously, as does Shiny `ExtendedTask`. The only
reason it takes time is passing large objects requiring serialization to
the parallel process.

Be careful passing functions or environments to
[`mirai()`](https://mirai.r-lib.org/dev/reference/mirai.md) via `...` or
`.args`. Functions include their closure (enclosing environment), and
environments include parent environments. You may be passing more than
intended.

Use `lobstr::obj_size()` from the lobstr package to check actual object
size (more accurate than base R’s `object.size`).

**Mitigation for large objects:**

- **Functions**: Use `carrier::crate()` from the carrier package (used
  in purrr). This ensures only necessary components are ‘crated’ with
  the function. To crate an existing function, use an anonymous function
  (supplying anything required by `fn` via `...`):

``` r
func <- carrier::crate(\(x) fn(x), fn = fn)
```

- **Environments**: Consider `parent.env(e) <- emptyenv()`. Not required
  for R6 classes (already isolated by default). Environments or R6
  classes may contain unnecessary items for the parallel process -
  consider passing individual members (`env$x`, `env$y`) rather than the
  entire object (`env`).

### 5. Creating daemons on-demand or shutting down idle daemons

Setting daemons is separate from launching (deploying) them. To set
daemons for local use:

``` r
daemons(url = local_url())
```

For local and/or remote machines:

``` r
daemons(url = host_url())
```

This creates a ‘base station’ listening for incoming daemon connections.

To launch (deploy) a daemon:

``` r
launch_local()
```

or

``` r
launch_remote(remote = ssh_config("ssh://servername")) # or cluster_config()
```

For flexible scaling up and down, specify one of these arguments to
`...` in
[`launch_local()`](https://mirai.r-lib.org/dev/reference/launch_local.md)
or
[`launch_remote()`](https://mirai.r-lib.org/dev/reference/launch_local.md).
Supply these to the initial
[`daemons()`](https://mirai.r-lib.org/dev/reference/daemons.md) call to
apply by default for all launches:

- `maxtasks`: Integer number of tasks to perform before exiting
- `idletime`: Milliseconds idle time before exiting
- `walltime`: Milliseconds soft wall time before exiting (at least this
  amount, possibly more - no forcible timeout mid-task)

To launch a daemon for one task only:

``` r
launch_remote(remote = ssh_config("ssh://servername"), maxtasks = 1L)
```

This enables on-demand HPC cluster jobs via
[`cluster_config()`](https://mirai.r-lib.org/dev/reference/cluster_config.md)
without persistent daemons. Note: you incur latency costs from job
launch time.
