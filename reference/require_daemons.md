# Require Daemons

Returns `TRUE` invisibly only if daemons are set, otherwise produces an
informative error for the user to set daemons, with a clickable function
link if the cli package is available.

## Usage

``` r
require_daemons(.compute = NULL, call = environment())
```

## Arguments

- .compute:

  character value for the compute profile to use (each has its own
  independent set of daemons), or NULL to use the 'default' profile.

- call:

  (only used if the cli package is installed) the execution environment
  of a currently running function, e.g.
  [`environment()`](https://rdrr.io/r/base/environment.html). The
  function will be mentioned in error messages as the source of the
  error.

## Value

Invisibly, logical `TRUE`, or else errors.

## Examples

``` r
daemons(sync = TRUE)
(require_daemons())
#> [1] TRUE
daemons(0)
```
