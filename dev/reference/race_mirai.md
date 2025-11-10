# mirai (Race)

Accepts a list of 'mirai' objects, such as those returned by
[`mirai_map()`](https://mirai.r-lib.org/dev/reference/mirai_map.md).
Waits for the next 'mirai' to resolve if at least one is still in
progress, blocking but user-interruptible. If none of the objects
supplied are unresolved, the function returns immediately.

## Usage

``` r
race_mirai(x)
```

## Arguments

- x:

  a 'mirai' object, or list of 'mirai' objects.

## Value

The passed object (invisibly).

## Details

All of the 'mirai' objects supplied must belong to the same compute
profile - the currently-active one i.e. 'default' unless within a
[`with_daemons()`](https://mirai.r-lib.org/dev/reference/with_daemons.md)
or
[`local_daemons()`](https://mirai.r-lib.org/dev/reference/with_daemons.md)
scope.

## See also

[`call_mirai()`](https://mirai.r-lib.org/dev/reference/call_mirai.md)

## Examples

``` r
if (FALSE) { # interactive()
daemons(2)
m1 <- mirai(Sys.sleep(0.2))
m2 <- mirai(Sys.sleep(0.1))
start <- Sys.time()
race_mirai(list(m1, m2))
Sys.time() - start
race_mirai(list(m1, m2))
Sys.time() - start
daemons(0)
}
```
