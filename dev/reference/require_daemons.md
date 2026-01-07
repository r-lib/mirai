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

  (character) name of the compute profile. Each profile has its own
  independent set of daemons. `NULL` (default) uses the 'default'
  profile.

- call:

  (environment) execution environment for error attribution, e.g.
  [`environment()`](https://rdrr.io/r/base/environment.html). Used by
  cli for error messages.

## Value

Invisibly, logical `TRUE`, or else errors.

## Examples

``` r
daemons(sync = TRUE)
(require_daemons())
#> [1] TRUE
daemons(0)
```
