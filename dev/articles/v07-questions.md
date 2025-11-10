# Community FAQs

This vignette is designed to provide a knowledgebase for questions posed
by the community, and will be added to over time.

### 1. Migration from `future_promise()`

For use within Shiny, it should be straightforward translating
ExtendedTask or other async code that was originally written for use
with a
[`promises::future_promise()`](https://rstudio.github.io/promises/reference/future_promise.html).

Note:
[`future_promise()`](https://rstudio.github.io/promises/reference/future_promise.html)
exists in the promises package as we had to find a workaround to make
`future(...)` always async. `future(...)` by itself is not always async
as it blocks as soon as it runs out of parallel processes on which to
run tasks.

[`mirai()`](https://mirai.r-lib.org/dev/reference/mirai.md) on the other
hand is built as an async framework, so there’s no need for an
additional function from the promises package. You should simply use a
[`mirai()`](https://mirai.r-lib.org/dev/reference/mirai.md) directly in
place of a
[`future_promise()`](https://rstudio.github.io/promises/reference/future_promise.html).

**Globals:**

One important difference is that a
[`future_promise()`](https://rstudio.github.io/promises/reference/future_promise.html)
by default tries to infer all the global variables that are required by
the expression. If your code depended on this convenience feature then
you will need to instead pass these in via the `...` of
[`mirai()`](https://mirai.r-lib.org/dev/reference/mirai.md). A mirai
requires that the expression be self-contained, with any variables or
helper functions explicitly supplied to it.

On the other hand, if your code previously used the `globals` argument
to supply these variables, then you can pass this directly to the
`.args` of [`mirai()`](https://mirai.r-lib.org/dev/reference/mirai.md)
if it is a named list.

Regardless of using
[`mirai()`](https://mirai.r-lib.org/dev/reference/mirai.md) or
[`future_promise()`](https://rstudio.github.io/promises/reference/future_promise.html),
we recommend that you always pass globals explicitly. This matches what
actually happens in multi-process parallelism, and is hence
better-suited to programmatic use. Automatic globals detection is an
imperfect abstraction that can lead to unpredictable edge cases, or
simply slower operation through sending more than required to daemons.
Explicit passing of variables allows for reliable and transparent
behaviour that remains robust over time.

**Capture globals using
[`environment()`](https://rdrr.io/r/base/environment.html):**

[`mirai()`](https://mirai.r-lib.org/dev/reference/mirai.md) allows
passing an environment to `...` or to `.args`. This is especially useful
for Shiny ExtendedTask, where it is invoked with a set of arguments. By
using `mirai::mirai({...}, environment())` you automatically capture the
variables provided to the invoke method. See the Shiny vignette for
example usage.

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

The following example was raised as being potentially counter-intuitive,
given that default ‘cleanup’ settings at each daemon ensures that
variables in the global environment, of which `.Random.seed` is one, do
not carry over to subsequent runs.

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

The reason the change in random seed persists in all circumstances is
due to this being a special case, arising from the use of L’Ecuyer CMRG
streams to provide parallel-safe random numbers.

Streams can be thought of as entry points to the pseudo random number
line far away from each other to ensure that random results in each
daemon are independent from one another. The random seed is not reset
after each mirai call to ensure that however many random draws are made
in any mirai call, the next random draw follows on in the stream, and
hence have the desired statistical properties.

Hence normally, the random seed should be set once on the host process
when daemons are created, rather than in each daemon.

For numerical reproducibility, set the `seed` argument to
[`daemons()`](https://mirai.r-lib.org/dev/reference/daemons.md) (see the
Random Number Generation section of the reference vignette for further
details).

### 3. Accessing package functions during development

A mirai call usually requires package-namespaced functions. However the
latest version of a package in development is often loaded dynamically
by `devtools::load_all()` or the underlying `pkgload::load_all()` for
quick iteration.

In this case, use
[`everywhere()`](https://mirai.r-lib.org/dev/reference/everywhere.md) to
also call `devtools::load_all()` on all (local) daemons. They will then
have access to the same functions as your host session for subsequent
[`mirai()`](https://mirai.r-lib.org/dev/reference/mirai.md) calls.

### 4. Why does it take time for `mirai()` to execute when it’s meant to return immediately?

A [`mirai()`](https://mirai.r-lib.org/dev/reference/mirai.md) call is
meant to return almost instantaneously. The same when invoked by a Shiny
`ExtendedTask`. The only reason it would take time is if you are passing
through large objects, which then need to be serialized to be sent to
the parallel process.

Care should be taken when you pass a function or environment to
[`mirai()`](https://mirai.r-lib.org/dev/reference/mirai.md) in the `...`
or `.args` arguments. This is as a function includes its closure
(enclosing environment), and an environment its parent environments.
This means you could be passing more than you bargained for.

Generally, `lobstr::obj_size()` from the lobstr package is a great
function for checking the actual size of an object (capturing many cases
more accurately than the base R `object.size`).

As mitigation for accidentally passing large objects:

- For functions, use `carrier::crate()` from the carrier package. This
  is what we use in purrr, and it makes sure only what’s necessary is
  ‘crated’ with the function. To crate an existing function, use an
  anonymous function (making sure to also supply anything required by
  `fn` as part of the `...`):

``` r
func <- carrier::crate(\(x) fn(x), fn = fn)
```

- For environments, consider using `parent.env(e) <- emptyenv()`. This
  is not required for R6 classes as they are already isolated by
  default. Regardless of any parent environment, an environment / R6
  class could still contain many items that are not needed by the
  parallel process, in which case consider passing individual members
  (`env$x`, `env$y`) rather than the entire object (`env`) where
  possible.

### 5. How to create daemons on-demand or shutdown daemons when they’re not used

Setting daemons can be totally separate from the task of actually
launching (deploying) them. To just set daemons when you’re using only
your local machine:

``` r
daemons(url = local_url())
```

or if you’re using your local machine and/or remote machines:

``` r
daemons(url = host_url())
```

This sets up daemons. You can think of this as a ‘base station’ that
listens for incoming daemon connections.

When you actually want to launch (deploy) a daemon, you may use either:

``` r
launch_local()
```

or

``` r
launch_remote(remote = ssh_config("ssh://servername")) # or cluster_config()
```

The key to adopting a flexible-use pattern that lets you scale up and
down is to specify one of the following arguments to the `...` argument
of
[`launch_local()`](https://mirai.r-lib.org/dev/reference/launch_local.md)
or
[`launch_remote()`](https://mirai.r-lib.org/dev/reference/launch_local.md).
You may also supply these to the initial
[`daemons()`](https://mirai.r-lib.org/dev/reference/daemons.md) call for
them to apply by default for all launches:

- `maxtasks`: integer number of tasks to perform before exiting.
- `idletime`: milliseconds idle time before exiting.
- `walltime`: milliseconds (soft) wall time before exiting (i.e. at
  least this amount of time, and possibly more as there is no forcible
  timeout mid-task)

As an example, to launch a daemon to perform one task only:

``` r
launch_remote(remote = ssh_config("ssh://servername"), maxtasks = 1L)
```

In this way, you may use
[`cluster_config()`](https://mirai.r-lib.org/dev/reference/cluster_config.md)
to launch jobs on an HPC cluster on demand, without using persistent
daemons. Note that you will incur the latency costs of however long it
takes to launch the job.
