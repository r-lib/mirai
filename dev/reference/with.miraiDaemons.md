# With Mirai Daemons

Evaluate an expression with daemons that last for the duration of the
expression. Ensure each mirai within the statement is explicitly called
(or their values collected) so that daemons are not reset before they
have all completed.

## Usage

``` r
# S3 method for class 'miraiDaemons'
with(data, expr, ...)
```

## Arguments

- data:

  a call to
  [`daemons()`](https://mirai.r-lib.org/dev/reference/daemons.md).

- expr:

  an expression to evaluate.

- ...:

  not used.

## Value

The return value of `expr`.

## Details

This function is an S3 method for the generic
[`with()`](https://rdrr.io/r/base/with.html) for class 'miraiDaemons'.

## Examples

``` r
if (FALSE) { # interactive()
with(
  daemons(2, dispatcher = FALSE),
  {
    m1 <- mirai(Sys.getpid())
    m2 <- mirai(Sys.getpid())
    cat(m1[], m2[], "\n")
  }
)

status()
}
```
