# Make mirai_map Promise

Creates a 'promise' from a 'mirai_map'.

## Usage

``` r
# S3 method for class 'mirai_map'
as.promise(x)
```

## Arguments

- x:

  an object of class 'mirai_map'.

## Value

A 'promise' object.

## Details

This function is an S3 method for the generic
[`as.promise()`](https://rstudio.github.io/promises/reference/is.promise.html)
for class 'mirai_map'.

Requires the promises package.

Allows a 'mirai_map' to be used with the promise pipe `%...>%`, which
schedules a function to run upon resolution of the entire 'mirai_map'.

The implementation internally uses
[`promises::promise_all()`](https://rstudio.github.io/promises/reference/promise_all.html).
If all of the promises were successful, the returned promise will
resolve to a list of the promise values; if any promise fails, the first
error to be encountered will be used to reject the returned promise.

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
