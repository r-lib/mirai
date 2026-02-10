# Next \>\> Developer Interface

`nextstream` retrieves the currently stored L'Ecuyer-CMRG RNG stream for
the specified compute profile and advances it to the next stream.

`nextget` retrieves the specified item from the specified compute
profile.

`nextcode` translates integer exit codes returned by
[`daemon()`](https://mirai.r-lib.org/dev/reference/daemon.md).

## Usage

``` r
nextstream(.compute = "default")

nextget(x, .compute = "default")

nextcode(xc)
```

## Arguments

- .compute:

  (character) name of the compute profile. Each profile has its own
  independent set of daemons. `NULL` (default) uses the 'default'
  profile.

- x:

  (character) item to retrieve: `"n"` (daemon count), `"dispatcher"`
  (dispatcher-to-host URL), `"url"` (daemon connection URL), or `"tls"`
  (client TLS configuration).

- xc:

  (integer) return value from
  [`daemon()`](https://mirai.r-lib.org/dev/reference/daemon.md).

## Value

For `nextstream`: a length 7 integer vector, as given by `.Random.seed`
when the L'Ecuyer-CMRG RNG is in use (may be passed directly to the `rs`
argument of
[`daemon()`](https://mirai.r-lib.org/dev/reference/daemon.md)), or else
NULL if a stream has not yet been created.

For `nextget`: the requested item, or else NULL if not present.

For `nextcode`: character string.

## Details

These functions are exported for use by packages extending mirai with
alternative launchers of
[`daemon()`](https://mirai.r-lib.org/dev/reference/daemon.md) processes.

For `nextstream`: Calling this function advances the stream stored
within the compute profile. This ensures that the next recursive stream
is returned on subsequent calls.

## Examples

``` r
daemons(sync = TRUE)
nextstream()
#> [1]       10407   466761875   751420600  -515383463  -331456698
#> [6] -1206986481   -34040828
nextstream()
#> [1]       10407 -1171813903 -1636859713   -45560966  1701905993
#> [6]  -739104734  -843469383

nextget("url")
#> [1] "abstract://828a9c623bbe96ca63c5482d"

daemons(0)

nextcode(0L)
#> [1] "0 | Daemon connection terminated"
nextcode(1L)
#> [1] "1 | Daemon idletime limit reached"
```
