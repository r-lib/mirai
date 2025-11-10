# mirai (Call Value)

Waits for the 'mirai' to resolve if still in progress, stores the value
at `$data`, and returns the 'mirai' object.

## Usage

``` r
call_mirai(x)
```

## Arguments

- x:

  a 'mirai' object, or list of 'mirai' objects.

## Value

The passed object (invisibly). For a 'mirai', the retrieved value is
stored at `$data`.

## Details

Accepts a list of 'mirai' objects, such as those returned by
[`mirai_map()`](https://mirai.r-lib.org/dev/reference/mirai_map.md), as
well as individual 'mirai'.

Waits for the asynchronous operation(s) to complete if still in
progress, blocking but user-interruptible.

`x[]` may also be used to wait for and return the value of a mirai `x`,
and is the equivalent of `call_mirai(x)$data`.

## Alternatively

The value of a 'mirai' may be accessed at any time at `$data`, and if
yet to resolve, an 'unresolved' logical NA will be returned instead.

Using
[`unresolved()`](https://mirai.r-lib.org/dev/reference/unresolved.md) on
a 'mirai' returns TRUE only if it has yet to resolve and FALSE
otherwise. This is suitable for use in control flow statements such as
`while` or `if`.

## Errors

If an error occurs in evaluation, the error message is returned as a
character string of class 'miraiError' and 'errorValue'.
[`is_mirai_error()`](https://mirai.r-lib.org/dev/reference/is_mirai_error.md)
may be used to test for this. The elements of the original condition are
accessible via `$` on the error object. A stack trace comprising a list
of calls is also available at `$stack.trace`, and the original condition
classes at `$condition.class`.

If a daemon crashes or terminates unexpectedly during evaluation, an
'errorValue' 19 (Connection reset) is returned.

[`is_error_value()`](https://mirai.r-lib.org/dev/reference/is_mirai_error.md)
tests for all error conditions including 'mirai' errors, interrupts, and
timeouts.

## See also

[`race_mirai()`](https://mirai.r-lib.org/dev/reference/race_mirai.md)

## Examples

``` r
if (FALSE) { # interactive()
# using call_mirai()
df1 <- data.frame(a = 1, b = 2)
df2 <- data.frame(a = 3, b = 1)
m <- mirai(as.matrix(rbind(df1, df2)), df1 = df1, df2 = df2, .timeout = 1000)
call_mirai(m)$data

# using unresolved()
m <- mirai(
  {
    res <- rnorm(n)
    res / rev(res)
  },
  n = 1e6
)
while (unresolved(m)) {
  cat("unresolved\n")
  Sys.sleep(0.1)
}
str(m$data)
}
```
