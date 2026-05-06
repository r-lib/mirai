# Status Information

Retrieve status information for the specified compute profile,
comprising current connections, daemons status, and (when using
dispatcher) queue depth and memory pressure.

## Usage

``` r
status(.compute = NULL)
```

## Arguments

- .compute:

  (character \| miraiCluster) compute profile name, or `NULL` for
  'default'. Also accepts a 'miraiCluster'.

## Value

A named list comprising:

- **connections** - integer number of active daemon connections.

- **daemons** - character URL at which host / dispatcher is listening,
  or else `0L` if daemons have not yet been set.

- **mirai** (present only if using dispatcher) - a named integer vector
  comprising: **awaiting** - number of tasks queued for execution at
  dispatcher, **executing** - number of tasks sent to a daemon for
  execution, and **completed** - number of tasks for which the result
  has been received (either completed or cancelled).

- **memory** (present only if using dispatcher) - a named numeric vector
  in MB (metric, 1 MB = 1,000,000 bytes) comprising: **used** - current
  and **peak** - high-watermark queued task payloads at dispatcher, and
  **capacity** - the value set as the `memory` argument to
  [`daemons()`](https://mirai.r-lib.org/dev/reference/daemons.md)
  (`NA_real_` if unset/unbounded).

## See also

[`info()`](https://mirai.r-lib.org/dev/reference/info.md) for more
succinct information statistics.

## Examples

``` r
status()
#> $connections
#> [1] 0
#> 
#> $daemons
#> [1] 0
#> 
daemons(sync = TRUE)
status()
#> $connections
#> [1] 0
#> 
#> $daemons
#> [1] "abstract://182d3b7d01e7381c4ef035aa"
#> 
daemons(0)
```
