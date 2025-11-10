# Evaluate Everywhere

Evaluate an expression 'everywhere' on all connected daemons for the
specified compute profile - this must be set prior to calling this
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

  an expression to evaluate asynchronously (of arbitrary length, wrapped
  in { } where necessary), **or else** a pre-constructed language
  object.

- ...:

  (optional) **either** named arguments (name = value pairs) specifying
  objects referenced, but not defined, in `.expr`, **or** an environment
  containing such objects. See 'evaluation' section below.

- .args:

  (optional) **either** a named list specifying objects referenced, but
  not defined, in `.expr`, **or** an environment containing such
  objects. These objects will remain local to the evaluation environment
  as opposed to those supplied in `...` above - see 'evaluation' section
  below.

- .min:

  (only applicable when using dispatcher) integer minimum number of
  daemons on which to evaluate the expression. A synchronization point
  is created, which can be useful for remote daemons, as these may take
  some time to connect.

- .compute:

  character value for the compute profile to use (each has its own
  independent set of daemons), or NULL to use the 'default' profile.

## Value

A 'mirai_map' (list of 'mirai' objects).

## Details

If using dispatcher, this function forces a synchronization point at
dispatcher, whereby the `everywhere()` call must have been evaluated on
all daemons prior to subsequent mirai evaluations taking place.

Calling `everywhere()` does not affect the RNG stream for mirai calls
when using a reproducible `seed` value at
[`daemons()`](https://mirai.r-lib.org/dev/reference/daemons.md). This
allows the seed associated for each mirai call to be the same,
regardless of the number of daemons actually used to evaluate the code.
Note that this means the code evaluated in an `everywhere()` call is
itself non-reproducible if it should involve random numbers.

## Evaluation

The expression `.expr` will be evaluated in a separate R process in a
clean environment (not the global environment), consisting only of the
objects supplied to `.args`, with the objects passed as `...` assigned
to the global environment of that process.

As evaluation occurs in a clean environment, all undefined objects must
be supplied through `...` and/or `.args`, including self-defined
functions. Functions from a package should use namespaced calls such as
[`mirai::mirai()`](https://mirai.r-lib.org/dev/reference/mirai.md), or
else the package should be loaded beforehand as part of `.expr`.

For evaluation to occur *as if* in your global environment, supply
objects to `...` rather than `.args`, e.g. for non-local variables or
helper functions required by other functions, as scoping rules may
otherwise prevent them from being found.

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
