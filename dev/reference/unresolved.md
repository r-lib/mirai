# Query if a mirai is Unresolved

Query whether a 'mirai', 'mirai' value or list of 'mirai' remains
unresolved. Unlike
[`call_mirai()`](https://mirai.r-lib.org/dev/reference/call_mirai.md),
this function does not wait for completion.

## Usage

``` r
unresolved(x)
```

## Arguments

- x:

  a 'mirai' object or list of 'mirai' objects, or a 'mirai' value stored
  at `$data`.

## Value

Logical TRUE if `x` is an unresolved 'mirai' or 'mirai' value or the
list contains at least one unresolved 'mirai', or FALSE otherwise.

## Details

Suitable for use in control flow statements such as `while` or `if`.

## Examples

``` r
if (FALSE) { # interactive()
m <- mirai(Sys.sleep(0.1))
unresolved(m)
Sys.sleep(0.3)
unresolved(m)
}
```
