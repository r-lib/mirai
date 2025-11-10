# Status Information

Retrieve status information for the specified compute profile,
comprising current connections and daemons status.

## Usage

``` r
status(.compute = NULL)
```

## Arguments

- .compute:

  character value for the compute profile to query, or NULL to query the
  'default' profile.

  **or** a 'miraiCluster' to obtain its status.

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

## See also

[`info()`](https://mirai.r-lib.org/dev/reference/info.md) for more
succinct information statistics.

## Examples

``` r
if (FALSE) { # interactive()
status()
daemons(url = "tcp://[::1]:0")
status()
daemons(0)
}
```
