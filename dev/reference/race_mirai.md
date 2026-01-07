# mirai (Race)

Accepts a list of 'mirai' objects, such as those returned by
[`mirai_map()`](https://mirai.r-lib.org/dev/reference/mirai_map.md).
Returns the index of the first resolved 'mirai'. If any mirai is already
resolved, returns immediately. Otherwise waits for at least one to
resolve, blocking but user-interruptible.

## Usage

``` r
race_mirai(x, .compute = NULL)
```

## Arguments

- x:

  (list) of 'mirai' objects.

- .compute:

  (character) name of the compute profile. Each profile has its own
  independent set of daemons. `NULL` (default) uses the 'default'
  profile.

## Value

Integer index of the first resolved 'mirai' (invisibly), or `0L` if the
list is empty.

## Details

All of the 'mirai' objects supplied must belong to the same compute
profile.

When called on a list where some mirais are already resolved, returns
the index of the first resolved mirai immediately without waiting. When
all mirais are unresolved, blocks until at least one resolves. If
multiple mirais resolve during the same wait iteration, returns the
index of the first resolved in list order.

This enables an efficient "process as completed" pattern:

      remaining <- list(m1, m2, m3)
      while (length(remaining) > 0) {
        idx <- race_mirai(remaining)
        process(remaining[[idx]]$data)
        remaining <- remaining[-idx]
      }
      

## See also

[`call_mirai()`](https://mirai.r-lib.org/dev/reference/call_mirai.md)

## Examples

``` r
if (FALSE) { # interactive()
daemons(2)
m1 <- mirai({ Sys.sleep(0.2); "one" })
m2 <- mirai({ Sys.sleep(0.1); "two" })
m3 <- mirai({ Sys.sleep(0.3); "three" })
remaining <- list(m1, m2, m3)
while (length(remaining) > 0) {
  idx <- race_mirai(remaining)
  print(remaining[[idx]]$data)
  remaining <- remaining[-idx]
}
daemons(0)
}
```
