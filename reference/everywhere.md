# Evaluate Everywhere

Evaluate an expression 'everywhere' on all connected daemons for the
specified compute profile. Daemons must be set prior to calling this
function. Performs operations across daemons such as loading packages or
exporting common data. Resultant changes to the global environment,
loaded packages and options are persisted regardless of a daemon's
`cleanup` setting.

## Usage

``` r
everywhere(.expr, ..., .args = list(), .min = 1L, .compute = NULL)
```

## Arguments

- .expr:

  (expression) code to evaluate asynchronously, or a language object.
  Wrap multi-line expressions in
  [`{}`](https://rdrr.io/r/base/Paren.html).

- ...:

  (named arguments \| environment) objects required by `.expr`, assigned
  to the daemon's global environment. See 'evaluation' section below.

- .args:

  (named list \| environment) objects required by .expr, kept local to
  the evaluation environment (unlike `...`). See 'evaluation' section
  below.

- .min:

  (integer) minimum daemons to evaluate on (dispatcher only). Creates a
  synchronization point, useful for remote daemons that take time to
  connect.

- .compute:

  (character) name of the compute profile. Each profile has its own
  independent set of daemons. `NULL` (default) uses the 'default'
  profile.

## Value

A 'mirai_map' (list of 'mirai' objects).

## Details

If using dispatcher, this function forces a synchronization point: the
`everywhere()` call must complete on all daemons before subsequent mirai
evaluations proceed.

Calling `everywhere()` does not affect the RNG stream for mirai calls
when using a reproducible `seed` value at
[`daemons()`](https://mirai.r-lib.org/reference/daemons.md). This allows
the seed associated with each mirai call to be the same, regardless of
the number of daemons used. However, code evaluated in an `everywhere()`
call is itself non-reproducible if it involves random numbers.

## Evaluation

The expression `.expr` will be evaluated in a separate R process in a
clean environment (not the global environment), consisting only of the
objects supplied to `.args`, with the objects passed as `...` assigned
to the global environment of that process.

As evaluation occurs in a clean environment, all undefined objects must
be supplied through `...` and/or `.args`, including self-defined
functions. Functions from a package should use namespaced calls such as
[`mirai::mirai()`](https://mirai.r-lib.org/reference/mirai.md), or else
the package should be loaded beforehand as part of `.expr`.

Supply objects to `...` rather than `.args` for evaluation to occur *as
if* in your global environment. This is needed for non-local variables
or helper functions required by other functions, which scoping rules may
otherwise prevent from being found.

## Examples

``` r
daemons(sync = TRUE)

# export common data by a super-assignment expression:
everywhere(y <<- 3)
mirai(y)[]
#> [1] 3

# '...' variables are assigned to the global environment
# '.expr' may be specified as an empty {} in such cases:
everywhere({}, a = 1, b = 2)
mirai(a + b - y == 0L)[]
#> [1] TRUE

# everywhere() returns a mirai_map object:
mp <- everywhere("just a normal operation")
mp
#> < mirai map [1/1] >
mp[.flat]
#> [1] "just a normal operation"
mp <- everywhere(stop("everywhere"))
collect_mirai(mp)
#> [[1]]
#> 'miraiError' chr Error: everywhere
#> 
daemons(0)

# loading a package on all daemons
daemons(sync = TRUE)
everywhere(library(parallel))
m <- mirai("package:parallel" %in% search())
m[]
#> [1] TRUE
daemons(0)
```
