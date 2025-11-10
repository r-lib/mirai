# mirai Map

Asynchronous parallel map of a function over a list or vector using
mirai, with optional promises integration. Performs multiple map over
the rows of a dataframe or matrix.

## Usage

``` r
mirai_map(.x, .f, ..., .args = list(), .promise = NULL, .compute = NULL)
```

## Arguments

- .x:

  a list or atomic vector. Also accepts a matrix or dataframe, in which
  case multiple map is performed over its rows.

- .f:

  a function to be applied to each element of `.x`, or row of `.x` as
  the case may be.

- ...:

  (optional) named arguments (name = value pairs) specifying objects
  referenced, but not defined, in `.f`.

- .args:

  (optional) further constant arguments to `.f`, provided as a list.

- .promise:

  (optional) if supplied, registers a promise against each mirai. Either
  a function, supplied to the `onFulfilled` argument of
  [`promises::then()`](https://rstudio.github.io/promises/reference/then.html)
  or a list of 2 functions, supplied respectively to `onFulfilled` and
  `onRejected` of
  [`promises::then()`](https://rstudio.github.io/promises/reference/then.html).
  Using this argument requires the promises package.

- .compute:

  character value for the compute profile to use (each has its own
  independent set of daemons), or NULL to use the 'default' profile.

## Value

A 'mirai_map' (list of 'mirai' objects).

## Details

Sends each application of function `.f` on an element of `.x` (or row of
`.x`) for computation in a separate
[`mirai()`](https://mirai.r-lib.org/dev/reference/mirai.md) call. If
`.x` is named, names are preserved.

This simple and transparent behaviour is designed to make full use of
mirai scheduling to minimise overall execution time.

Facilitates recovery from partial failure by returning all 'miraiError'
/ 'errorValue' as the case may be, thus allowing only failures to be
re-run.

This function requires daemons to have previously been set, and will
error otherwise.

## Collection Options

`x[]` collects the results of a 'mirai_map' `x` and returns a list. This
will wait for all asynchronous operations to complete if still in
progress, blocking but user-interruptible.

`x[.flat]` collects and flattens map results to a vector, checking that
they are of the same type to avoid coercion. Note: errors if an
'errorValue' has been returned or results are of differing type.

`x[.progress]` collects map results whilst showing a progress bar from
the cli package, if installed, with completion percentage and ETA, or
else a simple text progress indicator. Note: if the map operation
completes too quickly then the progress bar may not show at all.

`x[.stop]` collects map results applying early stopping, which stops at
the first failure and cancels remaining operations.

The options above may be combined in the manner of:  
`x[.stop, .progress]` which applies early stopping together with a
progress indicator.

## Multiple Map

If `.x` is a matrix or dataframe (or other object with 'dim'
attributes), *multiple* map is performed over its **rows**. Character
row names are preserved as names of the output.

This allows map over 2 or more arguments, and `.f` should accept at
least as many arguments as there are columns. If the dataframe has
names, or the matrix column dimnames, named arguments are provided to
`.f`.

To map over **columns** instead, first wrap a dataframe in
[`as.list()`](https://rdrr.io/r/base/list.html), or transpose a matrix
using [`t()`](https://rdrr.io/r/base/t.html).

## Nested Maps

At times you way wish to run maps within maps. To do this, the function
provided to the outer map needs to include a call to
[`daemons()`](https://mirai.r-lib.org/dev/reference/daemons.md) to set
daemons used by the inner map. To guard against inadvertently spawning
an excessive number of daemons on the same machine, attempting to launch
local daemons within a map using `daemons(n)` will error.

A legitimate use of this pattern however is when the outer daemons are
launched on remote machines, and you then wish to launch daemons locally
on each of those machines. In this case, use the following solution:
instead of a single call to `daemons(n)` make 2 separate calls to
`daemons(url = local_url()); launch_local(n)`. This is equivalent, and
is permitted from within a map.

## Examples

``` r
if (FALSE) { # interactive()
daemons(4)

# perform and collect mirai map
mm <- mirai_map(c(a = 1, b = 2, c = 3), rnorm)
mm
mm[]

# map with constant args specified via '.args'
mirai_map(1:3, rnorm, .args = list(n = 5, sd = 2))[]

# flatmap with helper function passed via '...'
mirai_map(
  10^(0:9),
  function(x) rnorm(1L, valid(x)),
  valid = function(x) min(max(x, 0L), 100L)
)[.flat]

# unnamed matrix multiple map: arguments passed to function by position
(mat <- matrix(1:4, nrow = 2L))
mirai_map(mat, function(x = 10, y = 0, z = 0) x + y + z)[.flat]

# named matrix multiple map: arguments passed to function by name
(mat <- matrix(1:4, nrow = 2L, dimnames = list(c("a", "b"), c("y", "z"))))
mirai_map(mat, function(x = 10, y = 0, z = 0) x + y + z)[.flat]

# dataframe multiple map: using a function taking '...' arguments
df <- data.frame(a = c("Aa", "Bb"), b = c(1L, 4L))
mirai_map(df, function(...) sprintf("%s: %d", ...))[.flat]

# indexed map over a vector (using a dataframe)
v <- c("egg", "got", "ten", "nap", "pie")
mirai_map(
  data.frame(1:length(v), v),
  sprintf,
  .args = list(fmt = "%d_%s")
)[.flat]

# return a 'mirai_map' object, check for resolution, collect later
mp <- mirai_map(2:4, function(x) runif(1L, x, x + 1))
unresolved(mp)
mp
mp[.flat]
unresolved(mp)

# progress indicator counts up from 0 to 4 seconds
res <- mirai_map(1:4, Sys.sleep)[.progress]

# stops early when second element returns an error
tryCatch(mirai_map(list(1, "a", 3), sum)[.stop], error = identity)

daemons(0)
}
if (FALSE) { # interactive() && requireNamespace("promises", quietly = TRUE)
# promises example that outputs the results, including errors, to the console
daemons(1, dispatcher = FALSE)
ml <- mirai_map(
  1:30,
  function(i) {Sys.sleep(0.1); if (i == 30) stop(i) else i},
  .promise = list(
    function(x) cat(paste(x, "")),
    function(x) { cat(conditionMessage(x), "\n"); daemons(0) }
  )
)
}
```
