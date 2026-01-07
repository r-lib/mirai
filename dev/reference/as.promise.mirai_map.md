# Make mirai_map Promise

Creates a 'promise' from a 'mirai_map'. S3 method for
[`promises::as.promise()`](https://rstudio.github.io/promises/reference/is.promise.html).

## Usage

``` r
# S3 method for class 'mirai_map'
as.promise(x)
```

## Arguments

- x:

  (mirai_map) object to convert to promise.

## Value

A 'promise' object.

## Details

Allows a 'mirai_map' to be used with the promise pipe `%...>%`,
scheduling a function to run upon resolution of all mirai.

Uses
[`promises::promise_all()`](https://rstudio.github.io/promises/reference/promise_all.html)
internally: resolves to a list of values if all succeed, or rejects with
the first error encountered.

Requires the promises package.

## Examples

``` r
if (FALSE) { # interactive() && requireNamespace("promises", quietly = TRUE)
library(promises)

with(daemons(1), {
  mp <- mirai_map(1:3, function(x) { Sys.sleep(1); x })
  p <- as.promise(mp)
  print(p)
  p %...>% print
  mp[.flat]
})
}
```
