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

  character value for the compute profile to use (each has its own
  independent set of daemons), or NULL to use the 'default' profile.

- x:

  character value of item to retrieve. One of `"n"` (number of
  dispatcher daemons), `"dispatcher"` (the URL dispatcher uses to
  connect to host) `"url"` (the URL to connect to dispatcher from
  daemons) or `"tls"` (the stored client TLS configuration for use by
  daemons).

- xc:

  integer return value of
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

For `nextstream`: This function should be called for its return value
when required. The function also has the side effect of automatically
advancing the stream stored within the compute profile. This ensures
that the next recursive stream is returned when the function is called
again.

## Examples

``` r
daemons(sync = TRUE)
nextstream()
#> [1]       10407   792815129 -1884879098 -1960710705   286126532
#> [6]  1328909813 -1274208718
nextstream()
#> [1]       10407 -1925600861  -765594404 -1351620210 -1371409380
#> [6]   302119711 -1829637341

nextget("url")
#> [1] "abstract://9f76bc1e9728bc8449415581"

daemons(0)

nextcode(0L)
#> [1] "0 | Daemon connection terminated"
nextcode(1L)
#> [1] "1 | Daemon idletime limit reached"
```
