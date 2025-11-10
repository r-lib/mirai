# mirai (Evaluate Async)

Evaluate an expression asynchronously in a new background R process or
persistent daemon (local or remote). This function will return
immediately with a 'mirai', which will resolve to the evaluated result
once complete.

## Usage

``` r
mirai(.expr, ..., .args = list(), .timeout = NULL, .compute = NULL)
```

## Arguments

- .expr:

  an expression to evaluate asynchronously (of arbitrary length, wrapped
  in { } where necessary), **or else** a pre-constructed language
  object.

- ...:

  (optional) **either** named arguments (name = value pairs) specifying
  objects referenced, but not defined, in `.expr`, **or** an environment
  containing such objects. See 'evaluation' section below.

- .args:

  (optional) **either** a named list specifying objects referenced, but
  not defined, in `.expr`, **or** an environment containing such
  objects. These objects will remain local to the evaluation environment
  as opposed to those supplied in `...` above - see 'evaluation' section
  below.

- .timeout:

  integer value in milliseconds, or NULL for no timeout. A mirai will
  resolve to an 'errorValue' 5 (timed out) if evaluation exceeds this
  limit.

- .compute:

  character value for the compute profile to use (each has its own
  independent set of daemons), or NULL to use the 'default' profile.

## Value

A 'mirai' object.

## Details

This function will return a 'mirai' object immediately.

The value of a mirai may be accessed at any time at `$data`, and if yet
to resolve, an 'unresolved' logical NA will be returned instead. Each
mirai has an attribute `id`, which is a monotonically increasing integer
identifier in each session.

[`unresolved()`](https://mirai.r-lib.org/dev/reference/unresolved.md)
may be used on a mirai, returning TRUE if a 'mirai' has yet to resolve
and FALSE otherwise. This is suitable for use in control flow statements
such as `while` or `if`.

Alternatively, to call (and wait for) the result, use
[`call_mirai()`](https://mirai.r-lib.org/dev/reference/call_mirai.md) on
the returned 'mirai'. This will block until the result is returned.

Specify `.compute` to send the mirai using a specific compute profile
(if previously created by
[`daemons()`](https://mirai.r-lib.org/dev/reference/daemons.md)),
otherwise leave as `"default"`.

## Evaluation

The expression `.expr` will be evaluated in a separate R process in a
clean environment (not the global environment), consisting only of the
objects supplied to `.args`, with the objects passed as `...` assigned
to the global environment of that process.

As evaluation occurs in a clean environment, all undefined objects must
be supplied through `...` and/or `.args`, including self-defined
functions. Functions from a package should use namespaced calls such as
`mirai::mirai()`, or else the package should be loaded beforehand as
part of `.expr`.

For evaluation to occur *as if* in your global environment, supply
objects to `...` rather than `.args`, e.g. for non-local variables or
helper functions required by other functions, as scoping rules may
otherwise prevent them from being found.

## Timeouts

Specifying the `.timeout` argument ensures that the mirai always
resolves. When using dispatcher, the mirai will be cancelled after it
times out (as if
[`stop_mirai()`](https://mirai.r-lib.org/dev/reference/stop_mirai.md)
had been called). As in that case, there is no guarantee that any
cancellation will be successful, if the code cannot be interrupted for
instance. When not using dispatcher, the mirai task will continue to
completion in the daemon process, even if it times out in the host
process.

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
# specifying objects via '...'
n <- 3
m <- mirai(x + y + 2, x = 2, y = n)
m
m$data
Sys.sleep(0.2)
m$data

# passing the calling environment to '...'
df1 <- data.frame(a = 1, b = 2)
df2 <- data.frame(a = 3, b = 1)
df_matrix <- function(x, y) {
  mirai(as.matrix(rbind(x, y)), environment(), .timeout = 1000)
}
m <- df_matrix(df1, df2)
m[]

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

# evaluating scripts using source() in '.expr'
n <- 10L
file <- tempfile()
cat("r <- rnorm(n)", file = file)
m <- mirai({source(file); r}, file = file, n = n)
call_mirai(m)$data
unlink(file)

# use source(local = TRUE) when passing in local variables via '.args'
n <- 10L
file <- tempfile()
cat("r <- rnorm(n)", file = file)
m <- mirai({source(file, local = TRUE); r}, .args = list(file = file, n = n))
call_mirai(m)$data
unlink(file)

# passing a language object to '.expr' and a named list to '.args'
expr <- quote(a + b + 2)
args <- list(a = 2, b = 3)
m <- mirai(.expr = expr, .args = args)
collect_mirai(m)
}
```
