# Make mirai Promise

Creates a 'promise' from a 'mirai'.

## Usage

``` r
# S3 method for class 'mirai'
as.promise(x)
```

## Arguments

- x:

  an object of class 'mirai'.

## Value

A 'promise' object.

## Details

This function is an S3 method for the generic
[`as.promise()`](https://rstudio.github.io/promises/reference/is.promise.html)
for class 'mirai'.

Requires the promises package.

Allows a 'mirai' to be used with the promise pipe `%...>%`, which
schedules a function to run upon resolution of the 'mirai'.

## Examples

``` r
if (FALSE) { # interactive() && requireNamespace("promises", quietly = TRUE)
library(promises)

p <- as.promise(mirai("example"))
print(p)
is.promise(p)

p2 <- mirai("completed") %...>% identity()
p2$then(cat)
is.promise(p2)
}
```
