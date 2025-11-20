# mirai (Collect Value)

Waits for the 'mirai' to resolve if still in progress, and returns its
value directly. It is a more efficient version of and equivalent to
`call_mirai(x)$data`.

## Usage

``` r
collect_mirai(x, options = NULL)
```

## Arguments

- x:

  a 'mirai' object, or list of 'mirai' objects.

- options:

  (if `x` is a list of mirai) a character vector comprising any
  combination of collection options for
  [`mirai_map()`](https://mirai.r-lib.org/dev/reference/mirai_map.md),
  such as `".flat"` or `c(".progress", ".stop")`.

## Value

An object (the return value of the 'mirai'), or a list of such objects
(the same length as `x`, preserving names).

## Details

This function will wait for the asynchronous operation(s) to complete if
still in progress, blocking but interruptible.

`x[]` is an equivalent way to wait for and return the value of a mirai
`x`.

## Options

As an alternative to a character vector, a list where the names are the
collection options is also accepted. The value for `.progress` is passed
to the cli progress bar - if a character value as the name, and if a
list as named parameters to
[`cli::cli_progress_bar`](https://cli.r-lib.org/reference/cli_progress_bar.html).
Examples: `c(.stop = TRUE, .progress = "bar name")` or
`list(.stop = TRUE, .progress = list(name = "bar", type = "tasks"))`

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

## Examples

``` r
if (FALSE) { # interactive()
# using collect_mirai()
df1 <- data.frame(a = 1, b = 2)
df2 <- data.frame(a = 3, b = 1)
m <- mirai(as.matrix(rbind(df1, df2)), df1 = df1, df2 = df2, .timeout = 1000)
collect_mirai(m)

# using x[]
m[]

# mirai_map with collection options
daemons(1, dispatcher = FALSE)
m <- mirai_map(1:3, rnorm)
collect_mirai(m, c(".flat", ".progress"))
daemons(0)
}
```
