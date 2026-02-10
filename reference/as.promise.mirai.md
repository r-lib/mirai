# Make mirai Promise

Creates a 'promise' from a 'mirai'. S3 method for
[`promises::as.promise()`](https://rstudio.github.io/promises/reference/is.promise.html).

## Usage

``` r
# S3 method for class 'mirai'
as.promise(x)
```

## Arguments

- x:

  (mirai) object to convert to promise.

## Value

A 'promise' object.

## Details

Allows a 'mirai' to be used with the promise pipe `%...>%`, scheduling a
function to run upon resolution.

Requires the promises package.

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
