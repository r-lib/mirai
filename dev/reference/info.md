# Information Statistics

Retrieve statistics for the specified compute profile.

## Usage

``` r
info(.compute = NULL)
```

## Arguments

- .compute:

  (character) name of the compute profile. Each profile has its own
  independent set of daemons. `NULL` (default) uses the 'default'
  profile.

## Value

Named integer vector or else `NULL` if the compute profile is yet to be
set up.

## Details

The returned statistics are:

- Connections: active daemon connections.

- Cumulative: total daemons that have ever connected.

- Awaiting: mirai tasks currently queued for execution at dispatcher.

- Executing: mirai tasks currently being evaluated on a daemon.

- Completed: mirai tasks that have been completed or cancelled.

For non-dispatcher daemons: only 'connections' will be available and the
other values will be `NA`.

## Examples

``` r
info()
#> NULL
daemons(sync = TRUE)
info()
#> connections  cumulative    awaiting   executing   completed 
#>           0          NA          NA          NA          NA 
daemons(0)
```
