# For Package Authors

### 1. Developer Interfaces

mirai offers the following functions primarily for package authors using
mirai:

1.  [`require_daemons()`](https://mirai.r-lib.org/dev/reference/require_daemons.md)
    will error and prompt the user to set daemons (with a clickable
    function link if the cli package is available) if daemons are not
    already set.
2.  [`daemons_set()`](https://mirai.r-lib.org/dev/reference/daemons_set.md),
    to detect if daemons have already been set.
3.  [`on_daemon()`](https://mirai.r-lib.org/dev/reference/on_daemon.md),
    to detect if code is already running on a daemon, i.e. within a
    [`mirai()`](https://mirai.r-lib.org/dev/reference/mirai.md) call.
4.  [`register_serial()`](https://mirai.r-lib.org/dev/reference/register_serial.md)
    to register custom serialization functions, which are automatically
    available by default for all subsequent
    [`daemons()`](https://mirai.r-lib.org/dev/reference/daemons.md)
    calls.
5.  [`nextget()`](https://mirai.r-lib.org/dev/reference/nextstream.md),
    for querying values for a compute profile, such as ‘url’, described
    in the function’s documentation. Note: only the
    specifically-documented values are supported interfaces.

### 2. Guidance

mirai as a framework is designed to support completely transparent and
inter-operable use within packages. A core design precept of not relying
on global options or environment variables minimises the likelihood of
conflict between use by different packages.

There are hence only a few important points to note:

1.  [`daemons()`](https://mirai.r-lib.org/dev/reference/daemons.md)
    settings should wherever possible be left to end-users. This means
    that as a package author, you should just consider that mirai are
    run on whatever resources are available to the user at the time the
    code is run. You do not need to anticipate whether an end-user will
    run the code on their own machine, distributed over the network, or
    a mixture of both.

- Consider pointing to the documentation for
  [`mirai::daemons()`](https://mirai.r-lib.org/dev/reference/daemons.md),
  or re-exporting
  [`daemons()`](https://mirai.r-lib.org/dev/reference/daemons.md) in
  your package as a convenience.
- Never include a call to
  [`daemons()`](https://mirai.r-lib.org/dev/reference/daemons.md) when
  using
  [`mirai_map()`](https://mirai.r-lib.org/dev/reference/mirai_map.md).
  This is important to ensure that there is no accidental recursive
  creation of daemons on the same machine, for example if your function
  is used within another package’s function that also uses mirai.
  - The exception to this rule is that package authors may decide to
    provide a fallback to synchronous behaviour to ensure that a map
    always runs even if the user has not set daemons. In this case, it
    is permissible to set synchronous daemons for the duration of the
    map, if daemons have not been set, and provided that they are reset
    after the map. For this purpose, you may use code such as:

    ``` r
    with(if (!daemons_set()) daemons(sync = TRUE), {
      mirai_map(...)
    })
    ```
- Exceptionally, a `daemons(n = 1, dispatcher = FALSE, .compute = ...)`
  call may be used to set up a single dedicated daemon, but only if used
  with a unique value for `.compute`. A representative example of this
  usage pattern is `logger::appender_async()`, where the logger
  package’s ‘namespace’ concept maps directly to mirai’s ‘compute
  profile’.

2.  The shape and contents of a
    [`status()`](https://mirai.r-lib.org/dev/reference/status.md) call
    must not be used programmatically, as this user interface is subject
    to change at any time. Use
    [`info()`](https://mirai.r-lib.org/dev/reference/info.md) instead.

- For the value of `status()$daemons`, instead use `nextget("url")`.

3.  [`info()`](https://mirai.r-lib.org/dev/reference/info.md) may be
    used programmatically, but only index into the vector using the name
    of the element rather than its position
    e.g. `info()[["cumulative"]]` rather than `info()[[2]]`. This is in
    case other values are added at a later date.

4.  The functions
    [`unresolved()`](https://mirai.r-lib.org/dev/reference/unresolved.md),
    [`is_error_value()`](https://mirai.r-lib.org/dev/reference/is_mirai_error.md),
    [`is_mirai_error()`](https://mirai.r-lib.org/dev/reference/is_mirai_error.md),
    and
    [`is_mirai_interrupt()`](https://mirai.r-lib.org/dev/reference/is_mirai_error.md)
    should be used to test for the relevant state of a mirai or its
    value.

- The characteristics of their current implementation, e.g. as a logical
  NA for an ‘unresolvedValue’, should not be relied upon, as these are
  subject to change at any time.

5.  For CRAN packages, all examples and tests should respect the
    following rules when running on CRAN:

- Use only one daemon (with `dispatcher = FALSE`) to ensure that only
  one additional process is used, to remain within the 2-core limit.
- Always reset daemons with `daemons(0)` at the end of each example or
  test file. Then allow at least a one-second sleep to ensure that all
  background processes have properly exited and that no ‘detritus’ from
  the processes remains.
- Never modify the default value of `asyncdial` or `autoexit` for
  [`daemon()`](https://mirai.r-lib.org/dev/reference/daemon.md), in that
  function or any functions that pass arguments through to it such as
  [`daemons()`](https://mirai.r-lib.org/dev/reference/daemons.md). This
  is to ensure that processes exit as soon as the host process does.
