# Query if Daemons are Set

Returns a logical value, whether or not daemons have been set for a
given compute profile.

## Usage

``` r
daemons_set(.compute = NULL)
```

## Arguments

- .compute:

  character value for the compute profile to use (each has its own
  independent set of daemons), or NULL to use the 'default' profile.

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
