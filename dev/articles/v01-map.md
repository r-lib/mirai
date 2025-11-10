# Mirai Map

### 1. Introduction

[`mirai_map()`](https://mirai.r-lib.org/dev/reference/mirai_map.md)
performs asynchronous parallel/distributed map using `mirai`.

This function is similar to
[`purrr::map()`](https://purrr.tidyverse.org/reference/map.html), but
instead of a list of values, returns a ‘mirai_map’ object, which is a
list of mirai.

A [`mirai_map()`](https://mirai.r-lib.org/dev/reference/mirai_map.md)
call returns almost immediately. The results of a mirai_map `x` may be
collected using `x[]` or `collect_mirai(x)`, the same as for a mirai.
This waits for all asynchronous operations to complete if still in
progress.

> Use of
> [`mirai_map()`](https://mirai.r-lib.org/dev/reference/mirai_map.md)
> requires that
> [`daemons()`](https://mirai.r-lib.org/dev/reference/daemons.md) have
> previously been set, and will error if this is not the case. This
> avoids launching potentially too many *ephemeral daemons* if the map
> is over a large number of elements.

### 2. Key Advantages

1.  Returns immediately with all evaluations taking place
    asynchronously. Printing a ‘mirai map’ object shows the current
    completion progress.
2.  The ‘.promise’ argument allows a promise action to be registered
    against each iteration. This can be used to perform side-effects
    when each iteration completes (such as checkpointing or recording a
    progress update).
3.  Returns evaluation errors as ‘miraiError’ or ‘errorValue’ as the
    case may be, rather than causing the entire map to fail. This allows
    more efficient recovery from partial failure.
4.  Does not rely on a ‘chunking’ algorithm that attempts to split work
    into batches according to the number of available daemons, as
    implemented for instance in the `parallel` package. Chunking cannot
    take into account varying or unpredictable compute times over the
    indices, which `mirai` scheduling is designed to deal with
    optimally. This is demonstrated in the example below:

``` r
library(mirai)
library(parallel)
cl <- make_cluster(4)
daemons(4)
vec <- c(1, 1, 4, 4, 1, 1, 1, 1)
system.time(mirai_map(vec, Sys.sleep)[])
#>    user  system elapsed 
#>   0.010   0.001   4.007
system.time(parLapply(cl, vec, Sys.sleep))
#>    user  system elapsed 
#>   0.012   0.001   8.011
daemons(0)
```

`.args` is used to specify further constant arguments to `.f` - the
`mean` and `sd` in the example below:

``` r
with(
  daemons(3, seed = 1234L),
  mirai_map(1:3, rnorm, .args = list(mean = 20, sd = 2))[]
)
#> [[1]]
#> [1] 19.86409
#> 
#> [[2]]
#> [1] 19.55834 22.30159
#> 
#> [[3]]
#> [1] 20.62193 23.06144 19.61896
```

Use `...` to further specify objects referenced but not defined in
`.f` - the function `fn` below:

``` r
daemons(4, seed = 2345L)
fn <- function(x, range) {
  runif(x, x, x + range)
}
ml <- mirai_map(
  c(a = 1, b = 2, c = 3),
  \(x) fn(x, x * 2),
  fn = fn
)
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

### 3. Collecting Results

When collecting the results, optionally specify arguments to `[]`:

- `x[.flat]` collects and flattens the results, checking that they are
  of the same type to avoid coercion.
- `x[.progress]` collects results using a `cli` progress bar, if
  available, showing completion percentage and ETA, or else a simple
  text progress indicator of parts completed of the total. If the map
  operation completes quickly, the `cli` progress bar may not show at
  all, and this is by design.
- `x[.stop]` collects the results applying early stopping, which stops
  at the first failure and cancels remaining computations. If the `cli`
  package is available, it will be used for displaying the error
  message.

Combinations of the above may be supplied in the fashion of
`x[.stop, .progress]`.

``` r
mirai_map(list(a = 1, b = "a", c = 3), function(x) exp(x))[.stop]
#> Error in `mirai_map()`:
#> ℹ In index: 2.
#> ℹ With name: b.
#> Caused by error in `exp()`:
#> ! non-numeric argument to mathematical function

with(
  daemons(4, dispatcher = FALSE, .compute = "sleep"),
  mirai_map(c(0.1, 0.2, 0.3), Sys.sleep)[.progress, .flat]
)
#> NULL
```

### 4. Multiple Map

When a dataframe or matrix is passed as `.x`, multiple map is
automatically performed over its **rows**, as this is most often the
desired behaviour.

> As a dataframe often contains columns of differing type, it is unusual
> to want to map over the **columns**, however this is possible by
> simply transforming it beforehand into a list using
> [`as.list()`](https://rdrr.io/r/base/list.html).

This allows map over 2 or more arguments by specifying a dataframe. One
of those may be an index value for indexed map.

The function `.f` must take as many arguments as there are columns,
either explicitly or via `...`.

``` r
fruit <- c("melon", "grapes", "coconut")

# create a dataframe for indexed map:
df <- data.frame(i = seq_along(fruit), fruit = fruit)

with(
  daemons(3, dispatcher = FALSE, .compute = "fruit"),
  mirai_map(df, sprintf, .args = list(fmt = "%d. %s"))[.flat]
)
#> [1] "1. melon"   "2. grapes"  "3. coconut"
```

[`mirai_map()`](https://mirai.r-lib.org/dev/reference/mirai_map.md) maps
a matrix over its **rows**, consistent with the behaviour for dataframes
Note that this is different to the behaviour of
[`lapply()`](https://rdrr.io/r/base/lapply.html) or
[`purrr::map()`](https://purrr.tidyverse.org/reference/map.html), which
treats a matrix the same as an ordinary vector.

> If instead, mapping over the columns is desired, simply take the
> transpose of the matrix beforehand using
> [`t()`](https://rdrr.io/r/base/t.html).

``` r
mat <- matrix(1:4, nrow = 2L, dimnames = list(c("a", "b"), c("y", "z")))
mirai_map(mat, function(x = 10, y = 0, z = 0) x + y + z)[.flat]
#>  a  b 
#> 14 16

daemons(0)
```

### 5. Nested Maps

In certain cases it may be desirable to perform maps within maps. To do
this, the function provided to the outer map needs to include a call to
[`daemons()`](https://mirai.r-lib.org/dev/reference/daemons.md) to set
daemons used by the inner map.

To prevent accidental proliferation of processes on the same machine,
setting local daemons of the form `daemons(6)` from within a function
provided to
[`mirai_map()`](https://mirai.r-lib.org/dev/reference/mirai_map.md) will
error. As an example, 8 daemons created in the outer map, which each
then create 8 in the inner map leads to 64 daemons being created.

It is far more common (and useful) for these to be created across
different machines. Creating and launching remote daemons is permitted
in all cases.

The above limitation does however prevent a legitimate use pattern: when
the outer daemons are launched on remote machines, and you wish to
launch inner daemons locally on each of those machines.

The solution in such a case is to use ‘remote’ daemons which are in fact
identical to local daemons. Instead of a single call to:

``` r
daemons(n)
```

Instead, make 2 separate calls to:

``` r
⁠daemons(url = local_url())
launch_local(n)
```

This is permitted from within a mirai map operation.
