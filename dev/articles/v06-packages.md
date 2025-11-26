# mirai - For Package Authors

### 1. Developer Interfaces

mirai provides these functions for package authors:

1.  [`require_daemons()`](https://mirai.r-lib.org/dev/reference/require_daemons.md) -
    errors and prompts users to set daemons if not already set (with
    clickable function link if cli package available)
2.  [`daemons_set()`](https://mirai.r-lib.org/dev/reference/daemons_set.md) -
    detects if daemons are set
3.  [`on_daemon()`](https://mirai.r-lib.org/dev/reference/on_daemon.md) -
    detects if code runs on a daemon (within a
    [`mirai()`](https://mirai.r-lib.org/dev/reference/mirai.md) call)
4.  [`register_serial()`](https://mirai.r-lib.org/dev/reference/register_serial.md) -
    registers custom serialization functions, automatically available
    for all subsequent
    [`daemons()`](https://mirai.r-lib.org/dev/reference/daemons.md)
    calls
5.  [`nextget()`](https://mirai.r-lib.org/dev/reference/nextstream.md) -
    queries compute profile values like ‘url’ (see function
    documentation). Note: only specifically-documented values are
    supported interfaces.

### 2. Guidance

mirai supports transparent, inter-operable package use. Not relying on
global options or environment variables minimizes conflicts between
packages.

**Important points:**

1.  **Leave
    [`daemons()`](https://mirai.r-lib.org/dev/reference/daemons.md)
    settings to end-users.** As a package author, assume mirai run on
    whatever resources users have available. Don’t anticipate whether
    users run code locally, distributed, or mixed.

    - Point to
      [`mirai::daemons()`](https://mirai.r-lib.org/dev/reference/daemons.md)
      documentation or re-export
      [`daemons()`](https://mirai.r-lib.org/dev/reference/daemons.md)
      for convenience
    - **Never call
      [`daemons()`](https://mirai.r-lib.org/dev/reference/daemons.md)
      when using
      [`mirai_map()`](https://mirai.r-lib.org/dev/reference/mirai_map.md)**
      to prevent accidental recursive daemon creation (e.g., if your
      function is used within another package’s mirai-using function)
      - **Exception**: Can provide a synchronous fallback if users
        haven’t set daemons:

        ``` r
        with(if (!daemons_set()) daemons(sync = TRUE), {
          mirai_map(...)
        })
        ```
    - **Exceptional case**: Use
      `daemons(n = 1, dispatcher = FALSE, .compute = ...)` for a single
      dedicated daemon only with a unique `.compute` value. Example:
      `logger::appender_async()` where logger’s ‘namespace’ maps to
      mirai’s ‘compute profile’.

2.  **Don’t use
    [`status()`](https://mirai.r-lib.org/dev/reference/status.md)
    programmatically.** Its interface may change. Use
    [`info()`](https://mirai.r-lib.org/dev/reference/info.md) instead.

    - For `status()$daemons`, use `nextget("url")`

3.  **Use [`info()`](https://mirai.r-lib.org/dev/reference/info.md)
    programmatically by name, not position.** Index by element name
    (e.g., `info()[["cumulative"]]`) not position (e.g., `info()[[2]]`)
    in case values are added later.

4.  **Use official test functions for mirai state.** Use
    [`unresolved()`](https://mirai.r-lib.org/dev/reference/unresolved.md),
    [`is_error_value()`](https://mirai.r-lib.org/dev/reference/is_mirai_error.md),
    [`is_mirai_error()`](https://mirai.r-lib.org/dev/reference/is_mirai_error.md),
    and
    [`is_mirai_interrupt()`](https://mirai.r-lib.org/dev/reference/is_mirai_error.md).

    - Don’t rely on implementation characteristics (e.g., logical NA for
      ‘unresolvedValue’) as these may change

5.  **CRAN package rules:**

    - Use only one daemon with `dispatcher = FALSE` (stays within 2-core
      limit)
    - Always reset with `daemons(0)` at end of examples/test files, then
      sleep at least 1 second to ensure proper process exit
    - Never modify `asyncdial` or `autoexit` defaults for
      [`daemon()`](https://mirai.r-lib.org/dev/reference/daemon.md) (or
      functions passing arguments to it like
      [`daemons()`](https://mirai.r-lib.org/dev/reference/daemons.md)).
      This ensures processes exit with the host process.
