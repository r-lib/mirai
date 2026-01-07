# Query if Daemons are Set

Returns a logical value, whether or not daemons have been set for a
given compute profile.

## Usage

``` r
daemons_set(.compute = NULL)
```

## Arguments

- .compute:

  (character) name of the compute profile. Each profile has its own
  independent set of daemons. `NULL` (default) uses the 'default'
  profile.

## Value

Logical `TRUE` or `FALSE`.

## Examples

``` r
daemons_set()
#> [1] FALSE
daemons(sync = TRUE)
daemons_set()
#> [1] TRUE
daemons(0)
```
