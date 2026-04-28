# Dispatcher Capacity

Retrieve the approximate current and peak memory used by queued task
payloads at dispatcher, in MB (metric, 1 MB = 1,000,000 bytes), to
monitor queue pressure against the `capacity` budget set in
[`daemons()`](https://mirai.r-lib.org/dev/reference/daemons.md).

## Usage

``` r
dispatcher_capacity(.compute = NULL)
```

## Arguments

- .compute:

  (character) name of the compute profile. Each profile has its own
  independent set of daemons. `NULL` (default) uses the 'default'
  profile.

## Value

Named numeric vector of length 3: **used** (current) and **peak**
(high-watermark) usage, and **capacity** (the budget set in
[`daemons()`](https://mirai.r-lib.org/dev/reference/daemons.md),
`NA_real_` if unset/unbounded), all in MB. `NULL` if the compute profile
is not using dispatcher.

## Examples

``` r
if (FALSE) { # interactive()
daemons(1, capacity = 100)
m <- mirai(Sys.sleep(0.5))
dispatcher_capacity()
m[]
daemons(0)
}
```
