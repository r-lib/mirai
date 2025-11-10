# Changelog

## mirai (development version)

##### Updates

- OpenTelemetry: ‘daemon connect’ spans are now recorded only after a
  connection has actually been made
  ([\#511](https://github.com/r-lib/mirai/issues/511)).
- Fixes a bug which caused mirai to remain unresolved after switching
  from synchronous daemons to dispatcher daemons in the same session
  ([\#509](https://github.com/r-lib/mirai/issues/509)).

## mirai 2.5.2

CRAN release: 2025-11-05

##### Updates

- The default daemons `autoexit = TRUE` behaviour has been updated for
  OpenTelemetry compatibility
  ([\#500](https://github.com/r-lib/mirai/issues/500)).
  - Introduces a 200ms grace period for processes to exit normally
    before a forceful termination.
  - The behavioural changes announced in mirai 2.4.0 are now enforced
    for all daemon types - eliminating a bug that previously caused this
    to only be applied to ephemeral daemons.
- OpenTelemetry span names and attributes have been upgraded to be more
  informative and better follow semantic conventions
  ([\#481](https://github.com/r-lib/mirai/issues/481)).
- [`require_daemons()`](https://mirai.r-lib.org/dev/reference/require_daemons.md)
  updates:
  - Function now returns invisibly as intended.
  - Using with `.compute` as the first argument (which produced a
    warning) no longer works.
- Requires nanonext \>= 1.7.2.

## mirai 2.5.1

CRAN release: 2025-10-06

##### New Features

- Adds
  [`race_mirai()`](https://mirai.r-lib.org/dev/reference/race_mirai.md),
  which accepts a list of mirai and waits efficiently for the next mirai
  amongst them to resolve
  ([@t-kalinowski](https://github.com/t-kalinowski),
  [\#448](https://github.com/r-lib/mirai/issues/448)).
- New synchronous mode: `daemons(sync = TRUE)` causes mirai to run
  synchronously within the current process. This facilitates testing and
  debugging, e.g. via interactive
  [`browser()`](https://rdrr.io/r/base/browser.html) instances
  ([\#439](https://github.com/r-lib/mirai/issues/439),
  [@kentqin-cve](https://github.com/kentqin-cve)
  [\#442](https://github.com/r-lib/mirai/issues/442)).

##### Updates

- [`everywhere()`](https://mirai.r-lib.org/dev/reference/everywhere.md)
  adds argument `.min` to specify a minimum number of daemons on which
  to evaluate the expression (when using dispatcher). This creates a
  synchronization point and can be useful when launching remote daemons
  to ensure that the expression has run on all daemons to connect
  ([@louisaslett](https://github.com/louisaslett),
  [\#330](https://github.com/r-lib/mirai/issues/330)).
- OpenTelemetry span names have been updated. Spans for long-running
  daemons are now split into short spans when they are created and when
  they end - refer to the updated vignette for more details
  ([\#464](https://github.com/r-lib/mirai/issues/464),
  [\#471](https://github.com/r-lib/mirai/issues/471)).
- Removes the following developer features:
  - `nextget("pid")` is no longer a supported option.
  - Argument `id` is removed at
    [`daemon()`](https://mirai.r-lib.org/dev/reference/daemon.md). This
    means that
    [`status()`](https://mirai.r-lib.org/dev/reference/status.md) no
    longer reports daemon connection or disconnection events.
- Removes deprecated argument `tls` at
  [`daemon()`](https://mirai.r-lib.org/dev/reference/daemon.md),
  [`launch_local()`](https://mirai.r-lib.org/dev/reference/launch_local.md)
  and
  [`launch_remote()`](https://mirai.r-lib.org/dev/reference/launch_local.md).
- Removes deprecated dispatcher argument ‘none’ at
  [`daemons()`](https://mirai.r-lib.org/dev/reference/daemons.md),
  deprecated in mirai v2.1.0.
- Fixes a phenomenon where
  [`stop_mirai()`](https://mirai.r-lib.org/dev/reference/stop_mirai.md)
  or `mirai_map()[.stop]` could on occasion cause (dispatcher) daemons
  to be interrupted and exit on subsequent runs
  ([\#459](https://github.com/r-lib/mirai/issues/459)).
- Non-dispatcher daemons now synchronize upon timeout or task-out,
  ensuring that they exit safely only after all data has been sent
  ([\#458](https://github.com/r-lib/mirai/issues/458)).
- Requires nanonext \>= 1.7.1.

## mirai 2.5.0

CRAN release: 2025-09-04

##### Behavioural Changes

- Behavioural changes for
  [`daemons()`](https://mirai.r-lib.org/dev/reference/daemons.md):
  - Returns invisibly logical `TRUE` when creating daemons and `FALSE`
    when resetting, for simplicity and consistency
    ([\#384](https://github.com/r-lib/mirai/issues/384)).
  - Creating new daemons resets any existing daemons for the compute
    profile rather than error. This means that an explicit `daemons(0)`
    is no longer required before applying new settings (thanks
    [@eliocamp](https://github.com/eliocamp),
    [\#383](https://github.com/r-lib/mirai/issues/383)).
  - Calling without supplying any arguments now errors rather than
    return the value of
    [`status()`](https://mirai.r-lib.org/dev/reference/status.md).

##### New Features

- Complete observability of mirai requests by emitting OpenTelemetry
  traces when tracing is enabled by the otelsdk package
  ([\#394](https://github.com/r-lib/mirai/issues/394)).
- Adds [`info()`](https://mirai.r-lib.org/dev/reference/info.md) as an
  alternative to
  [`status()`](https://mirai.r-lib.org/dev/reference/status.md) for
  retrieving more succinct information statistics, more convenient for
  programmatic use (thanks [@wlandau](https://github.com/wlandau),
  [\#410](https://github.com/r-lib/mirai/issues/410)).
- Adds
  [`with_daemons()`](https://mirai.r-lib.org/dev/reference/with_daemons.md)
  and
  [`local_daemons()`](https://mirai.r-lib.org/dev/reference/with_daemons.md)
  helper functions for using a particular compute profile. These work
  with daemons that are already set up unlike the existing
  [`with.miraiDaemons()`](https://mirai.r-lib.org/dev/reference/with.miraiDaemons.md)
  method, which creates a new scope and tears it down when finished
  ([\#360](https://github.com/r-lib/mirai/issues/360)).
- A mirai now has an attribute `id`, which is a monotonically increasing
  integer identifier unique to each session.

##### Updates

- [`stop_mirai()`](https://mirai.r-lib.org/dev/reference/stop_mirai.md)
  is more efficient and responsive, especially for ‘mirai_map’ objects
  ([\#417](https://github.com/r-lib/mirai/issues/417)).
- `miraiError` enhancements:
  - The original condition classes are preserved as `$condition.class`
    (thanks [@sebffischer](https://github.com/sebffischer),
    [\#400](https://github.com/r-lib/mirai/issues/400)).
  - The print method includes the customary additional line break
    (thanks [@sebffischer](https://github.com/sebffischer),
    [\#399](https://github.com/r-lib/mirai/issues/399)).
- Fixes `daemons(n)` failing to launch local daemons if mirai was
  installed in a custom user library set by an explicit
  [`.libPaths()`](https://rdrr.io/r/base/libPaths.html) call in
  ‘.Rprofile’ (thanks [@erydit](https://github.com/erydit) and
  [@dpastoor](https://github.com/dpastoor),
  [\#390](https://github.com/r-lib/mirai/issues/390)).
- Improved behaviour for
  [`serial_config()`](https://mirai.r-lib.org/dev/reference/serial_config.md)
  custom serialization. If the serialization hook function errors or
  otherwise fails to return a raw vector, this will error out rather
  than be silently ignored (thanks
  [@dipterix](https://github.com/dipterix),
  [\#378](https://github.com/r-lib/mirai/issues/378)).
- [`as.promise()`](https://rstudio.github.io/promises/reference/is.promise.html)
  method for mirai made robust for high-throughput scenarios
  ([\#377](https://github.com/r-lib/mirai/issues/377)).
- [`mirai_map()`](https://mirai.r-lib.org/dev/reference/mirai_map.md)
  now supports Arrow Tables and Polars DataFrames
  ([\#366](https://github.com/r-lib/mirai/issues/366)).
- [`require_daemons()`](https://mirai.r-lib.org/dev/reference/require_daemons.md)
  arguments are swapped so that `.compute` comes before `call` for ease
  of use. Previous usage will work for the time being, although is
  deprecated and will be defunct in a future version.
- Enhancements to
  [`everywhere()`](https://mirai.r-lib.org/dev/reference/everywhere.md):
  - Consecutive
    [`everywhere()`](https://mirai.r-lib.org/dev/reference/everywhere.md)
    calls are permissible again when using dispatcher (behaviour update
    in v2.4.1) ([\#354](https://github.com/r-lib/mirai/issues/354)).
  - No longer has any effect on the RNG stream when using a reproducible
    `seed` value at
    [`daemons()`](https://mirai.r-lib.org/dev/reference/daemons.md)
    ([\#356](https://github.com/r-lib/mirai/issues/356)).
- A [`mirai()`](https://mirai.r-lib.org/dev/reference/mirai.md)
  evaluated on an ephemeral daemon returns invisibly, consistent with
  other cases ([\#351](https://github.com/r-lib/mirai/issues/351)).
- [`daemon()`](https://mirai.r-lib.org/dev/reference/daemon.md) gains a
  `tlscert` argument for custom TLS certificates. The change in argument
  name lets this be passed when making a
  [`daemons()`](https://mirai.r-lib.org/dev/reference/daemons.md) call
  ([\#344](https://github.com/r-lib/mirai/issues/344)).
- The `tls` argument at
  [`daemon()`](https://mirai.r-lib.org/dev/reference/daemon.md),
  [`launch_local()`](https://mirai.r-lib.org/dev/reference/launch_local.md)
  and
  [`launch_remote()`](https://mirai.r-lib.org/dev/reference/launch_local.md)
  is deprecated.
- Requires nanonext \>= 1.7.0.

## mirai 2.4.1

CRAN release: 2025-07-15

##### New Features

- Reproducible parallel RNG by setting the `seed` argument to
  [`daemons()`](https://mirai.r-lib.org/dev/reference/daemons.md):
  - The default `NULL` uses L’Ecuyer-CMRG RNG streams advanced per
    daemon, the same as base R’s parallel package, which produces
    statistically-sound yet generally non-reproducible results.
  - Setting an integer seed now initializes a L’Ecuyer-CMRG RNG stream
    for the compute profile, which is advanced for each mirai
    evaluation, which does provide reproducible results.

##### Updates

- [`everywhere()`](https://mirai.r-lib.org/dev/reference/everywhere.md)
  has been updated for robustness and ease of use:
  - Returns a `mirai_map` object for easier handling (rather than just a
    list of mirai).
  - When using dispatcher, no longer has the potential to fail if
    sending large data
    ([\#326](https://github.com/r-lib/mirai/issues/326)).
- [`dispatcher()`](https://mirai.r-lib.org/dev/reference/dispatcher.md)
  function signature simplified with `rs`, `tls` and `pass` arguments
  removed (no user-facing impact).
- Fixes a bug where using non-dispatcher daemons, an `unresolvedValue`
  could be returned as the fulfilled value of a promise in extremely
  rare cases (thanks [@James-G-Hill](https://github.com/James-G-Hill)
  and [@olivier7121](https://github.com/olivier7121),
  [\#243](https://github.com/r-lib/mirai/issues/243) and
  [\#317](https://github.com/r-lib/mirai/issues/317)).
- Fixes a regression in mirai 2.4.0 where the L’Ecuyer-CMRG seed was not
  being passed correctly for remote daemons
  ([\#333](https://github.com/r-lib/mirai/issues/333)).
- Requires nanonext \>= 1.6.2.

## mirai 2.4.0

CRAN release: 2025-06-25

##### Behavioural Changes

- An ephemeral daemon started by
  [`mirai()`](https://mirai.r-lib.org/dev/reference/mirai.md) without
  setting daemons now exits as soon as the parent process does rather
  than finish the task.
- Change in
  [`daemon()`](https://mirai.r-lib.org/dev/reference/daemon.md)
  defaults:
  - Argument `autoexit` default of `TRUE` now ensures daemons are
    terminated along with the parent process. Set to `NA` to retain the
    previous behaviour of having them automatically exit after
    completing any in-progress tasks.
  - Argument `dispatcher` now defaults to `TRUE`.
- Calling
  [`daemons()`](https://mirai.r-lib.org/dev/reference/daemons.md) to
  create local daemons now errors if performed within a
  [`mirai_map()`](https://mirai.r-lib.org/dev/reference/mirai_map.md)
  call. This guards against excessive spawning of local processes on a
  single machine.

##### New Features

- Adds
  [`cluster_config()`](https://mirai.r-lib.org/dev/reference/cluster_config.md)
  to launch remote daemons via HPC resource managers for Slurm, SGE,
  Torque, PBS and LSF clusters.
- Adds
  [`require_daemons()`](https://mirai.r-lib.org/dev/reference/require_daemons.md)
  as a developer function that prompts the user to set daemons if not
  already set, with a clickable function link if the cli package is
  available.

##### Updates

- Simplifies launches when using dispatcher -
  [`launch_remote()`](https://mirai.r-lib.org/dev/reference/launch_local.md)
  commands are now the same irrespective of the number of launches. This
  is as daemons now retrieve the next RNG stream from dispatcher rather
  than the `rs` argument to
  [`daemon()`](https://mirai.r-lib.org/dev/reference/daemon.md).
- Deprecated `call_mirai_()` is now removed.
- Requires nanonext \>= 1.6.1.

## mirai 2.3.0

CRAN release: 2025-05-22

##### Behavioural Changes

- [`mirai()`](https://mirai.r-lib.org/dev/reference/mirai.md) argument
  `.timeout` is upgraded to automatically cancel ongoing mirai upon
  timeout when using dispatcher (thanks
  [@be-marc](https://github.com/be-marc),
  [@sebffischer](https://github.com/sebffischer)
  [\#251](https://github.com/r-lib/mirai/issues/251)).
- [`serial_config()`](https://mirai.r-lib.org/dev/reference/serial_config.md)
  now accepts vector arguments to register multiple custom serialization
  configurations. Argument `vec` is dropped as internal optimizations
  mean this option no longer needs to be set.

##### New Features

- [`host_url()`](https://mirai.r-lib.org/dev/reference/host_url.md) is
  upgraded to return all local IP addresses (named by network
  interface), which provides a more comprehensive solution than just
  using a hostname.
- Adds
  [`register_serial()`](https://mirai.r-lib.org/dev/reference/register_serial.md)
  to register serialization configurations for all
  [`daemons()`](https://mirai.r-lib.org/dev/reference/daemons.md) calls
  (may be used by package authors as a convenience).
- Adds
  [`on_daemon()`](https://mirai.r-lib.org/dev/reference/on_daemon.md)
  which returns a logical value, whether or not evaluation is taking
  place within a mirai call on a daemon.
- Adds
  [`daemons_set()`](https://mirai.r-lib.org/dev/reference/daemons_set.md)
  which returns a logical value, whether or not daemons are set for a
  given compute profile.
- [`daemons()`](https://mirai.r-lib.org/dev/reference/daemons.md) now
  supports initial synchronization exceeding 10s (between
  host/dispatcher/daemons). This is particularly relevant for HPC setups
  (thanks [@sebffischer](https://github.com/sebffischer),
  [\#275](https://github.com/r-lib/mirai/issues/275)).

##### Updates

- For all functions that use `.compute`, this argument has a new default
  of `NULL`, which continues to use the `default` profile (and hence
  should not result in any change in behaviour).
- Fixes
  [`stop_mirai()`](https://mirai.r-lib.org/dev/reference/stop_mirai.md)
  failing to interrupt in certain cases on non-Windows platforms, and
  more robust interruption if
  [`tools::SIGINT`](https://rdrr.io/r/tools/pskill.html) is supplied or
  passed through to the `autoexit` argument of
  [`daemon()`](https://mirai.r-lib.org/dev/reference/daemon.md) (thanks
  [@LennardLux](https://github.com/LennardLux),
  [\#240](https://github.com/r-lib/mirai/issues/240)).
- [`daemons()`](https://mirai.r-lib.org/dev/reference/daemons.md)
  dispatcher argument ‘process’, deprecated in mirai v2.1.0, is removed.
- Requires nanonext \>= 1.6.0.
- Package is re-licensed under the MIT license.

## mirai 2.2.0

CRAN release: 2025-03-20

##### Behavioural Changes

- Simplified SSH tunnelling for distributed computing:
  - [`ssh_config()`](https://mirai.r-lib.org/dev/reference/ssh_config.md)
    argument ‘port’ is removed, with the tunnel port now inferred at the
    time of launch, and no longer set by the configuration.
  - [`local_url()`](https://mirai.r-lib.org/dev/reference/host_url.md)
    adds logical argument ‘tcp’ for easily constructing an automatic
    local TCP URL when setting
    [`daemons()`](https://mirai.r-lib.org/dev/reference/daemons.md) for
    SSH tunnelling.

##### New Features

- Adds
  [`as.promise()`](https://rstudio.github.io/promises/reference/is.promise.html)
  method for ‘mirai_map’ objects. This will resolve upon completion of
  the entire map operation.

##### Updates

- mirai (in R \>= 4.5) is now one of the official base R parallel
  cluster types.
  - `register_cluster()` is removed as no longer required.
  - Directly use `parallel::makeCluster(type = "MIRAI")` to create a
    ‘miraiCluster’.
- [`call_mirai()`](https://mirai.r-lib.org/dev/reference/call_mirai.md)
  is now user-interruptible, consistent with all other functions in the
  package.
  - `call_mirai_()` is hence redundant and now deprecated.
- [`with()`](https://rdrr.io/r/base/with.html) method for
  [`daemons()`](https://mirai.r-lib.org/dev/reference/daemons.md) now
  propagates “.compute” so that this does not need to be specified in
  functions such as
  [`mirai()`](https://mirai.r-lib.org/dev/reference/mirai.md) within the
  [`with()`](https://rdrr.io/r/base/with.html) clause.
- [`mirai()`](https://mirai.r-lib.org/dev/reference/mirai.md) arguments
  `...` and `.args` now accept environments containing variables
  beginning with a dot `.`
  ([\#207](https://github.com/r-lib/mirai/issues/207)).
- ‘miraiError’ stack traces no longer sometimes contain an additional
  (internal) call ([\#216](https://github.com/r-lib/mirai/issues/216)).
- ‘miraiError’ condition `$call` objects are now stripped of ‘srcref’
  attributes (thanks [@lionel-](https://github.com/lionel-),
  [\#218](https://github.com/r-lib/mirai/issues/218)).
- A mirai promise now rejects in exactly the same way whether or not the
  mirai was already resolved at time of creation. This avoids Shiny deep
  stack trace errors when the mirai had already resolved
  ([\#229](https://github.com/r-lib/mirai/issues/229)).
- [`daemons()`](https://mirai.r-lib.org/dev/reference/daemons.md) calls
  that error due to the remote launcher no longer leave the compute
  profile set up ([\#237](https://github.com/r-lib/mirai/issues/237)).

## mirai 2.1.0

CRAN release: 2025-02-07

##### Behavioural Changes

- [`daemons()`](https://mirai.r-lib.org/dev/reference/daemons.md) now
  requires an explicit reset before providing revised settings for a
  compute profile, and will error otherwise.
- [`mirai_map()`](https://mirai.r-lib.org/dev/reference/mirai_map.md)
  now errors if daemons have not yet been set (rather than warn and
  launch one local daemon).
- Removal of mirai v1 compatibility features:
  - `saisei()` is now removed as no longer required.
  - [`daemons()`](https://mirai.r-lib.org/dev/reference/daemons.md)
    dispatcher argument “thread” is removed.
  - [`daemons()`](https://mirai.r-lib.org/dev/reference/daemons.md)
    dispatcher arguments “process” and “none” are formally deprecated
    and will be removed in a future version.

##### Updates

- ‘miraiError’ evaluation errors now return the call stack at
  `$stack.trace` as a list of calls (with srcrefs removed) without
  deparsing to character strings.
- [`mirai_map()`](https://mirai.r-lib.org/dev/reference/mirai_map.md)
  improvements:
  - Multiple map on a dataframe or matrix now correctly preserves the
    row names of the input as the names of the output.
  - Fixes language objects being evaluated before the map function is
    applied ([\#194](https://github.com/r-lib/mirai/issues/194)).
  - Fixes classes of objects in a dataframe being dropped during a
    multiple map ([\#196](https://github.com/r-lib/mirai/issues/196)).
  - Better `cli` errors when collecting a ‘mirai_map’.
- Fixes `daemons(NULL)` not causing all daemons started with
  `autoexit = FALSE` to quit, regression introduced in mirai v2.0.0.
- Requires nanonext \>= 1.5.0.

## mirai 2.0.1

CRAN release: 2025-01-16

##### Updates

- [`mirai_map()`](https://mirai.r-lib.org/dev/reference/mirai_map.md)
  collection option improvements:
  - The cli package is used, if installed, for richer progress bars and
    error messages.
  - `[.progress_cli]` is no longer a separate option.
  - `[.stop]` now reports the index number that errored.
- [`collect_mirai()`](https://mirai.r-lib.org/dev/reference/collect_mirai.md)
  replaces ‘…’ with an ‘options’ argument, to which collection options
  should be supplied as a character vector. This avoids non-standard
  evaluation in this function.
- [`daemon()`](https://mirai.r-lib.org/dev/reference/daemon.md) now
  returns an integer exit code to indicate the reason for termination.
- Adds
  [`nextcode()`](https://mirai.r-lib.org/dev/reference/nextstream.md) to
  provide a human-readable translation of the exit codes returned by
  [`daemon()`](https://mirai.r-lib.org/dev/reference/daemon.md).
- [`everywhere()`](https://mirai.r-lib.org/dev/reference/everywhere.md)
  now returns a list of at least one mirai regardless of the number of
  actual connections.

## mirai 2.0.0

CRAN release: 2025-01-08

##### New Architecture

- Distributed computing now uses a single socket and URL at which all
  daemons connect (with or without dispatcher).
  - Allows a more efficient `tcp://` or `tls+tcp://` connection in all
    cases.
  - The number of connected daemons may be upscaled or downscaled at any
    time without limit.

##### New Features

- `daemons(dispatcher = TRUE)` provides a new and more efficient
  architecture for dispatcher. This argument reverts to a logical value,
  although ‘process’ is still accepted and retains the previous
  behaviour of the v1 dispatcher.
- [`daemons()`](https://mirai.r-lib.org/dev/reference/daemons.md) gains
  argument ‘serial’ to register serialization configurations when using
  dispatcher. These automatically apply to all daemons that connect.
- [`stop_mirai()`](https://mirai.r-lib.org/dev/reference/stop_mirai.md)
  is now able to cancel remote mirai tasks (when using dispatcher),
  returning a logical value indicating whether cancellation was
  successful.
- A ‘miraiError’ now preserves the original condition object. This means
  that [`rlang::abort()`](https://rlang.r-lib.org/reference/abort.html)
  custom metadata may now be accessed using `$` on the ‘miraiError’
  (thanks [@James-G-Hill](https://github.com/James-G-Hill)
  [\#173](https://github.com/r-lib/mirai/issues/173)).

##### Updates

- [`status()`](https://mirai.r-lib.org/dev/reference/status.md) using
  the new dispatcher is updated to provide more concise and insightful
  information.
- [`everywhere()`](https://mirai.r-lib.org/dev/reference/everywhere.md)
  updates:
  - Enhanced to return a list of mirai, which may be waited for and
    inspected (thanks [@dgkf](https://github.com/dgkf),
    [\#164](https://github.com/r-lib/mirai/issues/164)).
  - Drops argument ‘.serial’ as serialization configurations are now
    registered via an argument at
    [`daemons()`](https://mirai.r-lib.org/dev/reference/daemons.md).
- [`daemon()`](https://mirai.r-lib.org/dev/reference/daemon.md) updates:
  - Gains the new argument ‘dispatcher’, which should be set to `TRUE`
    when connecting to dispatcher and `FALSE` when connecting directly
    to host.
  - Gains argument ‘id’ which accepts an integer value that allows
    [`status()`](https://mirai.r-lib.org/dev/reference/status.md) to
    track connection and disconnection events.
  - ‘…’ has been moved up to prevent partial matching on any of the
    optional arguments.
  - ‘cleanup’ argument simplified to a TRUE/FALSE value.
  - ‘timerstart’ argument removed.
- [`launch_local()`](https://mirai.r-lib.org/dev/reference/launch_local.md)
  and
  [`launch_remote()`](https://mirai.r-lib.org/dev/reference/launch_local.md)
  updates:
  - Enhanced to now launch daemons with the originally-supplied
    arguments by default.
  - Simplified to take the argument ‘n’ instead of ‘url’ for how many
    daemons to launch.
  - [`launch_local()`](https://mirai.r-lib.org/dev/reference/launch_local.md)
    now returns the number of daemons launched rather than invisible
    NULL.
- [`collect_mirai()`](https://mirai.r-lib.org/dev/reference/collect_mirai.md)
  is now interruptible and takes a ‘…’ argument accepting the collection
  options provided to the ‘mirai_map’ `[]` method, such as `.flat` etc.
- [`ssh_config()`](https://mirai.r-lib.org/dev/reference/ssh_config.md)
  simplified to take the argument ‘port’ instead of ‘host’. For SSH
  tunnelling, this is the port that will be used, and the hostname is
  now required to be ‘127.0.0.1’ (no longer accepting ‘localhost’).
- [`host_url()`](https://mirai.r-lib.org/dev/reference/host_url.md)
  argument ‘ws’ is removed as a TCP URL is now always recommended
  (although websocket URLs are still supported).
- `saisei()` is defunct as no longer required, but still available for
  use with the old v1 dispatcher.
- `daemons(dispatcher = "thread")` (experimental threaded dispatcher)
  has been retired - as this was based on the old dispatcher
  architecture and future development will focus on the current design.
  Specifying ‘dispatcher = thread’ is defunct, but will point to
  ‘dispatcher = process’ for the time being.
- Requires `nanonext` \>= 1.4.0.

## mirai 1.3.1

CRAN release: 2024-11-15

##### Updates

- Cleanup of packages only detaches them from the search path and does
  not attempt to unload them, as it is not always safe to do so. Fixes
  daemon crashes using packages such as `data.table` (thanks
  [@D3SL](https://github.com/D3SL),
  [\#166](https://github.com/r-lib/mirai/issues/166)).
- `serialization()` deprecated in mirai 1.2.0 is now removed.

## mirai 1.3.0

CRAN release: 2024-10-09

##### New Features

- `daemons(dispatcher = "thread")` implements threaded dispatcher
  (experimental), a faster and more efficient alternative to running
  dispatcher in a separate process.
- [`mirai_map()`](https://mirai.r-lib.org/dev/reference/mirai_map.md)
  adds `[.progress_cli]` as an alternative progress indicator, using the
  cli package to show % complete and ETA.
- [`daemons()`](https://mirai.r-lib.org/dev/reference/daemons.md) gains
  argument ‘force’ to control whether further calls reset previous
  settings for the same compute profile.
- [`daemon()`](https://mirai.r-lib.org/dev/reference/daemon.md) gains
  argument ‘asyncdial’ to allow control of connection behaviour
  independently of what happens when the daemon exits.

##### Behavioural Changes

- For [`daemons()`](https://mirai.r-lib.org/dev/reference/daemons.md):
  - Argument ‘dispatcher’ now takes the character options ‘process’,
    ‘thread’ and ‘none’. Previous values of TRUE/FALSE continue to be
    accepted (thanks [@hadley](https://github.com/hadley)
    [\#157](https://github.com/r-lib/mirai/issues/157)).
  - Return value is now always an integer - either the number of daemons
    set if using dispatcher, or the number of daemons launched locally
    (zero if using a remote launcher).
  - Invalid type of `...` arguments are now dropped instead of throwing
    an error. This allows `...` containing unused arguments to be more
    easily passed from other functions.
- For
  [`mirai_map()`](https://mirai.r-lib.org/dev/reference/mirai_map.md):
  - Now only performs multiple map over the rows of matrices and
    dataframes (thanks [@andrewGhazi](https://github.com/andrewGhazi),
    [\#147](https://github.com/r-lib/mirai/issues/147)).
  - Combining collection options is now easier, in the fashion of:
    `x[.stop, .progress]`.
  - Collection options now work even if mirai is not on the search path
    e.g. `mirai::mirai_map(1:4, Sys.sleep)[.progress]`.
- [`dispatcher()`](https://mirai.r-lib.org/dev/reference/dispatcher.md)
  drops argument ‘asyncdial’ as it is rarely useful to set this here.
- [`everywhere()`](https://mirai.r-lib.org/dev/reference/everywhere.md)
  now errors if the specified compute profile is not yet set up, rather
  than fail silently.
- [`launch_local()`](https://mirai.r-lib.org/dev/reference/launch_local.md)
  and
  [`launch_remote()`](https://mirai.r-lib.org/dev/reference/launch_local.md)
  now strictly require daemons to be set, and will error otherwise.
- [`serial_config()`](https://mirai.r-lib.org/dev/reference/serial_config.md)
  now validates the arguments provided and returns them as a list. This
  means any saved configurations from previous package versions must be
  re-generated.

##### Updates

- Fixes [`daemons()`](https://mirai.r-lib.org/dev/reference/daemons.md)
  to correctly handle a vector of URLs passed to ‘url’ again.
- Fixes flatmap with `mirai_map()[.flat]` assigning a variable ‘typ’ to
  the calling environment.
- Performance enhancements for
  [`mirai()`](https://mirai.r-lib.org/dev/reference/mirai.md),
  [`mirai_map()`](https://mirai.r-lib.org/dev/reference/mirai_map.md)
  and the promises method.
- Requires `nanonext` \>= 1.3.0.
- The package has a shiny new hex logo.

## mirai 1.2.0

CRAN release: 2024-08-18

- [`everywhere()`](https://mirai.r-lib.org/dev/reference/everywhere.md)
  adds argument ‘.serial’ to accept serialization configurations created
  by
  [`serial_config()`](https://mirai.r-lib.org/dev/reference/serial_config.md).
  These allow normally non-exportable reference objects such as Arrow
  Tables or torch tensors to be used seamlessly across parallel
  processes without additional marshalling steps. Configurations apply
  on a per compute profile basis.
- `serialization()` is now deprecated in favour of the above usage of
  [`everywhere()`](https://mirai.r-lib.org/dev/reference/everywhere.md),
  and will be removed in a future version.
- [`mirai_map()`](https://mirai.r-lib.org/dev/reference/mirai_map.md)
  enhanced to perform multiple map over 2D lists/vectors, allowing
  advanced patterns such as mapping over the rows of a dataframe or
  matrix.
- ‘mirai_map’ `[]` method gains the option `[.flat]` to collect and
  flatten results, avoiding coercion.
- Collecting a ‘mirai_map’ no longer spuriously introduces empty names
  where none were present originally.
- Faster local `daemons(dispatcher = FALSE)` and
  [`make_cluster()`](https://mirai.r-lib.org/dev/reference/make_cluster.md)
  by using asynchronous launches (thanks
  [@mtmorgan](https://github.com/mtmorgan)
  [\#123](https://github.com/r-lib/mirai/issues/123)).
- Local dispatcher daemons now synchronize with host, the same as
  non-dispatcher daemons (prevents use before all have connected).
- Fixes rare cases of
  [`everywhere()`](https://mirai.r-lib.org/dev/reference/everywhere.md)
  not reaching all daemons when using dispatcher.
- More efficient dispatcher startup by only loading the base package, in
  addition to not reading startup configurations (thanks
  [@krlmlr](https://github.com/krlmlr)).
- Removes hard dependency on `stats` and `utils` base packages.
- Requires `nanonext` \>= 1.2.0.

## mirai 1.1.1

CRAN release: 2024-07-01

- `serialization()` function signature and return value slightly
  modified for clarity. Successful registration / cancellation messages
  are no longer printed to the console.
- [`dispatcher()`](https://mirai.r-lib.org/dev/reference/dispatcher.md)
  argument ‘retry’ now defaults to FALSE for consistency with
  non-dispatcher behaviour.
- [`remote_config()`](https://mirai.r-lib.org/dev/reference/remote_config.md)
  gains argument ‘quote’ to control whether or not to quote the daemon
  launch command, and now works with Slurm (thanks
  [@michaelmayer2](https://github.com/michaelmayer2)
  [\#119](https://github.com/r-lib/mirai/issues/119)).
- Ephemeral daemons now exit as soon as permissible, eliminating the 2s
  linger period.
- Requires `nanonext` \>= 1.1.1.

## mirai 1.1.0

CRAN release: 2024-06-06

- Adds
  [`mirai_map()`](https://mirai.r-lib.org/dev/reference/mirai_map.md)
  for asynchronous parallel/distributed map using `mirai`, with
  `promises` integration. Allows recovery from partial failure or else
  early stopping, together with optional progress reporting.
  - `x[]` collects the results of a mirai_map `x`, waiting for all
    asynchronous operations to complete.
  - `x[.progress]` collects the results whilst showing a text progress
    bar.
  - `x[.stop]` collects the results applying early-stopping, which stops
    at the first error, and aborts remaining in-progress operations.
- Adds the ‘mirai’ method `x[]` as a more efficient equivalent of the
  interruptible `call_mirai_(x)$data`.
- Adds
  [`collect_mirai()`](https://mirai.r-lib.org/dev/reference/collect_mirai.md)
  as a more efficient equivalent of the non-interruptible
  `call_mirai(x)$data`.
- [`unresolved()`](https://mirai.r-lib.org/dev/reference/unresolved.md),
  [`call_mirai()`](https://mirai.r-lib.org/dev/reference/call_mirai.md),
  [`collect_mirai()`](https://mirai.r-lib.org/dev/reference/collect_mirai.md)
  and
  [`stop_mirai()`](https://mirai.r-lib.org/dev/reference/stop_mirai.md)
  now accept a list of ‘mirai’ such as that returned by
  [`mirai_map()`](https://mirai.r-lib.org/dev/reference/mirai_map.md).
- Improved mirai print method indicates whether a mirai has resolved.
- Calling
  [`daemons()`](https://mirai.r-lib.org/dev/reference/daemons.md) with
  new settings when the compute profile is already set now implicitly
  resets daemons before applying the new settings instead of silently
  doing nothing.
- Argument ‘resilience’ retired at
  [`daemons()`](https://mirai.r-lib.org/dev/reference/daemons.md) as
  automatic re-tries are no longer performed for non-dispatcher daemons.
- New argument ‘retry’ at
  [`dispatcher()`](https://mirai.r-lib.org/dev/reference/dispatcher.md)
  governs whether to auto-retry in the dispatcher case.
- Fixes promises method for potential crashes when launching improbably
  short-lived mirai.
- Fixes bug that could cause a hang or crash when launching additional
  non-dispatcher daemons.
- Requires `nanonext` \>= 1.1.0.

## mirai 1.0.0

CRAN release: 2024-05-03

- Implements completely event-driven (non-polling) promises (thanks
  [@jcheng5](https://github.com/jcheng5) for prototyping).
  - This is an innovation which allows higher responsiveness and massive
    scalability for ‘mirai’ promises.
- Behavioural changes to
  [`mirai()`](https://mirai.r-lib.org/dev/reference/mirai.md) and
  [`everywhere()`](https://mirai.r-lib.org/dev/reference/everywhere.md):
  - (breaking change) no longer permits an unnamed list to be supplied
    to ‘.args’.
  - allows an environment
    e.g. [`environment()`](https://rdrr.io/r/base/environment.html) to
    be supplied to ‘.args’ or as the only element of ‘…’.
  - allows evaluation of a symbol in the ‘mirai’ environment,
    e.g. `mirai(x, x = 1)`.
- [`ssh_config()`](https://mirai.r-lib.org/dev/reference/ssh_config.md)
  improvements:
  - new argument ‘host’ allows specifying the localhost URL and port to
    create a standalone configuration object.
  - order of arguments ‘tunnel’ and ‘timeout’ reversed.
- [`stop_mirai()`](https://mirai.r-lib.org/dev/reference/stop_mirai.md)
  now resolves to an ‘errorValue’ 20 (operation canceled) in the case
  the asynchronous task was still ongoing (thanks
  [@jcheng5](https://github.com/jcheng5)
  [\#110](https://github.com/r-lib/mirai/issues/110)).
- Rejected promises now show the complete error code and message in the
  case of an ‘errorValue’.
- A ‘miraiError’ reverts to not including a trailing line break (as
  prior to mirai 0.13.2).
- Non-dispatcher local daemons now synchronize with host in all cases
  (prevents use before all have connected).
- `[` method for ‘miraiCluster’ no longer produces a ‘miraiCluster’
  object (thanks [@HenrikBengtsson](https://github.com/HenrikBengtsson)
  [\#83](https://github.com/r-lib/mirai/issues/83)).
- Faster startup time as the `parallel` package is now only loaded when
  first used.
- Requires `nanonext` \>= 1.0.0.

## mirai 0.13.2

CRAN release: 2024-04-11

- [`mirai()`](https://mirai.r-lib.org/dev/reference/mirai.md) and
  [`everywhere()`](https://mirai.r-lib.org/dev/reference/everywhere.md)
  behaviour changed such that ‘…’ args are now assigned to the global
  environment of the daemon process.
- Adds [`with()`](https://rdrr.io/r/base/with.html) method for mirai
  daemons, allowing for example: `with(daemons(4), {expr})`, where the
  daemons last for the duration of ‘expr’.
- Adds `register_cluster()` for registering ‘miraiCluster’ as a parallel
  Cluster type (requires R \>= 4.4).
- Adds
  [`is.promising()`](https://rstudio.github.io/promises/reference/is.promise.html)
  method for ‘mirai’ for the promises package.
- A ‘miraiError’ now includes the full call stack, which may be accessed
  at `$stack.trace`, and includes the trailing line break for
  consistency with ‘as.character.error()’.
- mirai promises now preserve deep stacks when a ‘miraiError’ occurs
  within a Shiny app (thanks [@jcheng5](https://github.com/jcheng5)
  [\#104](https://github.com/r-lib/mirai/issues/104)).
- Simplified registration for ‘parallel’ and ‘promises’ methods (thanks
  [@jcheng5](https://github.com/jcheng5)
  [\#103](https://github.com/r-lib/mirai/issues/103)).
- Fixes to promises error handling and Shiny vignette (thanks
  [@jcheng5](https://github.com/jcheng5)
  [\#98](https://github.com/r-lib/mirai/issues/98)
  [\#99](https://github.com/r-lib/mirai/issues/99)).
- Requires R \>= 3.6.

## mirai 0.13.1

- Fixes regression in mirai 0.12.1, which introduced the potential for
  unintentional low level errors to emerge when querying dispatcher
  (thanks [@dsweber2](https://github.com/dsweber2) for reporting in
  downstream {targets}).

## mirai 0.13.0

- `serialization` adds arguments ‘class’ and ‘vec’ for custom
  serialisation of all reference object types.
- Requires nanonext \>= 0.13.3.

## mirai 0.12.1

CRAN release: 2024-02-02

- Dispatcher initial sync timeout widened to 10s to allow for launching
  large numbers of daemons.
- Default for
  [`ssh_config()`](https://mirai.r-lib.org/dev/reference/ssh_config.md)
  argument ‘timeout’ widened to 10 (seconds).
- Fixes [`daemons()`](https://mirai.r-lib.org/dev/reference/daemons.md)
  specifying ‘output = FALSE’ registering as TRUE instead.
- Fixes use of
  [`everywhere()`](https://mirai.r-lib.org/dev/reference/everywhere.md)
  specifying ‘.args’ as an unnamed list or ‘.expr’ as a language object.
- Ensures compatibility with nanonext \>= 0.13.0.
- Internal performance enhancements.

## mirai 0.12.0

CRAN release: 2024-01-12

- More minimal print methods for ‘mirai’ and ‘miraiCluster’.
- Adds
  [`local_url()`](https://mirai.r-lib.org/dev/reference/host_url.md)
  helper to construct a random inter-process communications URL for
  local daemons (thanks [@noamross](https://github.com/noamross)
  [\#90](https://github.com/r-lib/mirai/issues/90)).
- [`daemon()`](https://mirai.r-lib.org/dev/reference/daemon.md) argument
  ‘autoexit’ now accepts a signal value such as
  [`tools::SIGINT`](https://rdrr.io/r/tools/pskill.html) in order to
  raise it upon exit.
- [`daemon()`](https://mirai.r-lib.org/dev/reference/daemon.md) now
  records the state of initial global environment objects (e.g. those
  created in .Rprofile) for cleanup purposes (thanks
  [@noamross](https://github.com/noamross)
  [\#91](https://github.com/r-lib/mirai/issues/91)).
- Slightly more optimal
  [`as.promise()`](https://rstudio.github.io/promises/reference/is.promise.html)
  method for ‘mirai’.
- Eliminates potential memory leaks along certain error paths.
- Requires nanonext \>= 0.12.0.

## mirai 0.11.3

CRAN release: 2023-12-07

- Implements `serialization()` for registering custom serialization and
  unserialization functions when using daemons.
- Introduces `call_mirai_()`, a user-interruptible version of
  [`call_mirai()`](https://mirai.r-lib.org/dev/reference/call_mirai.md)
  suitable for interactive use.
- Simplification of
  [`mirai()`](https://mirai.r-lib.org/dev/reference/mirai.md) interface:
  - ‘.args’ will now coerce to a list if an object other than a list is
    supplied, rather than error.
  - ‘.signal’ argument removed - now all ‘mirai’ signal if daemons are
    set up.
- [`everywhere()`](https://mirai.r-lib.org/dev/reference/everywhere.md)
  now returns invisible NULL in the case the specified compute profile
  is not set up, rather than error.
- [`mirai()`](https://mirai.r-lib.org/dev/reference/mirai.md) specifying
  a timeout when
  [`daemons()`](https://mirai.r-lib.org/dev/reference/daemons.md) has
  not been set - the timeout begins immediately rather than after the
  ephemeral daemon has connected - please factor in a small amount of
  time for the daemon to launch.
- [`make_cluster()`](https://mirai.r-lib.org/dev/reference/make_cluster.md)
  now prints daemon launch commands where ‘url’ is specified without
  ‘remote’ whether or not interactive.
- Cluster node failures during load balanced operations now rely on the
  ‘parallel’ mechanism to error and no longer fail early or
  automatically stop the cluster.
- Fixes regression since 0.11.0 which prevented dispatcher exiting in a
  timely manner when tasks are backlogged (thanks
  [@wlandau](https://github.com/wlandau)
  [\#86](https://github.com/r-lib/mirai/issues/86)).
- Improved memory efficiency and stability at dispatcher.
- No longer loads the ‘promises’ package if not already loaded (but
  makes the ‘mirai’ method available via a hook function).
- Requires nanonext \>= 0.11.0.

## mirai 0.11.2

CRAN release: 2023-11-15

- [`make_cluster()`](https://mirai.r-lib.org/dev/reference/make_cluster.md)
  specifying only ‘url’ now succeeds with implied ‘n’ of one.
- Fixes [`mirai()`](https://mirai.r-lib.org/dev/reference/mirai.md)
  specifying a language object by name for ‘.expr’ in R versions 4.0 and
  earlier.
- Fixes regression in 0.11.1 which prevented the correct random seed
  being set when using dispatcher.
- Internal performance enhancements.

## mirai 0.11.1

CRAN release: 2023-11-04

- Adds ‘mirai’ method for ‘as.promise()’ from the {promises} package (if
  available). This functionality is merged from the package
  {mirai.promises}, allowing use of the promise pipe `%...>%` with a
  ‘mirai’.
- Parallel clusters (the alternative communications backend for R) now
  work with existing R versions, no longer requiring R \>= 4.4.
- [`everywhere()`](https://mirai.r-lib.org/dev/reference/everywhere.md)
  evaluates an expression ‘everywhere’ on all connected daemons for a
  compute profile. Resulting changes to the global environment, loaded
  pacakges or options are persisted regardless of the ‘cleanup’ setting
  (request by [@krlmlr](https://github.com/krlmlr)
  [\#80](https://github.com/r-lib/mirai/issues/80)).
- [`host_url()`](https://mirai.r-lib.org/dev/reference/host_url.md)
  implemented as a helper function to automatically construct the host
  URL using the computer’s hostname.
- [`daemon()`](https://mirai.r-lib.org/dev/reference/daemon.md) adds
  argument ‘autoexit’, which replaces ‘asyncdial’, to govern persistence
  settings for a daemon. A daemon can now survive a host session and
  re-connect to another one (request by
  [@krlmlr](https://github.com/krlmlr)
  [\#81](https://github.com/r-lib/mirai/issues/81)).
- `daemons(NULL)` implemented as a variant of `daemons(0)` which also
  sends exit signals to connected persistent daemons.
- [`dispatcher()`](https://mirai.r-lib.org/dev/reference/dispatcher.md)
  argument ‘lock’ removed as this is now applied in all cases to prevent
  more than one daemon dialling into a dispatcher URL at any one time.
- [`daemon()`](https://mirai.r-lib.org/dev/reference/daemon.md) argument
  ‘cleanup’ simplified to a logical argument, with more granular control
  offered by the existing integer bitmask (thanks
  [@krlmlr](https://github.com/krlmlr)
  [\#79](https://github.com/r-lib/mirai/issues/79)).
- Daemons connecting over TLS now perform synchronous dials by default
  (as documented).
- Fixes supplying an
  [`ssh_config()`](https://mirai.r-lib.org/dev/reference/ssh_config.md)
  specifying tunnelling to the ‘remote’ argument of
  [`daemons()`](https://mirai.r-lib.org/dev/reference/daemons.md).
- Fixes the print method for a subset ‘miraiCluster’ (thanks
  [@HenrikBengtsson](https://github.com/HenrikBengtsson)
  [\#83](https://github.com/r-lib/mirai/issues/83)).
- Removes the deprecated deferred evaluation pipe `%>>%`.
- Requires nanonext \>= 0.10.4.

## mirai 0.11.0

CRAN release: 2023-10-06

- Implements an alternative communications backend for R, adding methods
  for the ‘parallel’ base package.
  - Fulfils a request by R Core at R Project Sprint 2023, and requires R
    \>= 4.4 (currently R-devel).
  - [`make_cluster()`](https://mirai.r-lib.org/dev/reference/make_cluster.md)
    creates a ‘miraiCluster’, compatible with all existing functions
    taking a ‘cluster’ object, for example in the ‘parallel’ and
    ‘doParallel’ / ‘foreach’ packages.
  - [`status()`](https://mirai.r-lib.org/dev/reference/status.md) can
    now take a ‘miraiCluster’ as the argument to query its connection
    status.
- [`launch_remote()`](https://mirai.r-lib.org/dev/reference/launch_local.md)
  improvements:
  - Simplified interface with a single ‘remote’ argument taking a remote
    configuration to launch daemons.
  - Returned shell commands now have a custom print method which means
    they may be directly copy/pasted to a remote machine.
  - Can now take a ‘miraiCluster’ or ‘miraiNode’ to return the shell
    commands for deployment of remote nodes.
- [`daemons()`](https://mirai.r-lib.org/dev/reference/daemons.md) gains
  the following features:
  - Adds argument ‘remote’ for launching remote daemons directly without
    recourse to a separate call to
    [`launch_remote()`](https://mirai.r-lib.org/dev/reference/launch_local.md).
  - Adds argument ‘resilience’ to control the behaviour, when not using
    dispatcher, of whether to retry failed tasks on other daemons.
- [`remote_config()`](https://mirai.r-lib.org/dev/reference/remote_config.md)
  added to generate configurations for directly launching remote
  daemons, and can be supplied directly to a ‘remote’ argument.
- [`ssh_config()`](https://mirai.r-lib.org/dev/reference/ssh_config.md)
  added as a convenience method to generate launch configurations using
  SSH, including SSH tunnelling.
- [`mirai()`](https://mirai.r-lib.org/dev/reference/mirai.md) adds
  logical argument ‘.signal’ for whether to signal the condition
  variable within the compute profile upon resolution of the ‘mirai’.
- [`daemon()`](https://mirai.r-lib.org/dev/reference/daemon.md) argument
  ‘exitlinger’ retired as daemons now synchronise with the
  host/dispatcher and exit as soon as possible (although a default
  ‘exitlinger’ period still applies to ephemeral daemons).
- Optimises scheduling at dispatcher: tasks are no longer assigned to a
  daemon if it is exiting due to specified time/task-outs.
- An ‘errorValue’ 19 ‘Connection reset’ is now returned for a ‘mirai’ if
  the connection to either dispatcher or an ephemeral daemon drops, for
  example if they have crashed, rather than remaining unresolved.
- Invalid type of ‘…’ arguments specified to
  [`daemons()`](https://mirai.r-lib.org/dev/reference/daemons.md) or
  [`dispatcher()`](https://mirai.r-lib.org/dev/reference/dispatcher.md)
  now raise an error early rather than attempting to launch daemons that
  fail.
- Eliminates a potential crash in the host process after querying
  [`status()`](https://mirai.r-lib.org/dev/reference/status.md) if there
  is no longer a connection to dispatcher.
- Reverts the trailing line break added to the end of a ‘miraiError’
  character string.
- Moves the ‘…’ argument to
  [`daemons()`](https://mirai.r-lib.org/dev/reference/daemons.md),
  [`dispatcher()`](https://mirai.r-lib.org/dev/reference/dispatcher.md)
  and [`daemon()`](https://mirai.r-lib.org/dev/reference/daemon.md) to
  clearly delineate core vs peripheral options.
- Deprecates the Deferred Evaluation Pipe `%>>%` in favour of a
  recommendation to use package `mirai.promises` for performing side
  effects upon ‘mirai’ resolution.
- Deprecated use of alias `server()` for
  [`daemon()`](https://mirai.r-lib.org/dev/reference/daemon.md) is
  retired.
- Adds a ‘reference’ vignette, incorporating most of the information
  from the readme.
- Requires nanonext \>= 0.10.2.

## mirai 0.10.0

CRAN release: 2023-09-16

- Uses L’Ecuyer-CMRG streams for safe and reproducible (in certain
  cases) random number generation across parallel processes (thanks
  [@ltierney](https://github.com/ltierney) for discussion during R
  Project Sprint 2023).
  - [`daemons()`](https://mirai.r-lib.org/dev/reference/daemons.md)
    gains the new argument ‘seed’ to set a random seed for generating
    these streams.
  - [`daemon()`](https://mirai.r-lib.org/dev/reference/daemon.md) and
    [`dispatcher()`](https://mirai.r-lib.org/dev/reference/dispatcher.md)
    gain the argument ‘rs’ which takes a L’Ecuyer-CMRG random seed.
- New developer functions
  [`nextstream()`](https://mirai.r-lib.org/dev/reference/nextstream.md)
  and
  [`nextget()`](https://mirai.r-lib.org/dev/reference/nextstream.md),
  opening interfaces for packages which extend `mirai`.
- Dispatcher enhancements and fixes:
  - Runs in an R session with `--vanilla` flags for efficiency, avoiding
    lengthy startup configurations (thanks
    [@alexpiper](https://github.com/alexpiper)).
  - Straight pass through without serialization/unserialization allows
    higher performance and lower memory utilisation.
  - Fixes edge cases of
    [`status()`](https://mirai.r-lib.org/dev/reference/status.md)
    occasionally failing to communicate with dispatcher.
  - Fixes edge cases of ending a session with unresolved mirai resulting
    in a crash rather than a clean exit.
- Tweaks to `saisei()`:
  - specifying argument ‘force’ as TRUE now immediately regenerates the
    socket and returns any ongoing mirai as an ‘errorValue’. This allows
    tasks that consistently hang or crash to be cancelled rather than
    repeated when a new daemon connects.
  - argument ‘i’ is now required and no longer defaults to 1L.
- Tweaks to
  [`status()`](https://mirai.r-lib.org/dev/reference/status.md):
  - The daemons status matrix adds a column ‘i’ for ease of use with
    functions such as `saisei()` or
    [`launch_local()`](https://mirai.r-lib.org/dev/reference/launch_local.md).
  - The ‘instance’ column is now always cumulative - regenerating a URL
    with `saisei()` no longer resets the counter but instead turns it
    negative until a new daemon connects.
- Improves shell quoting of daemon launch commands, making it easier to
  deploy manually via
  [`launch_remote()`](https://mirai.r-lib.org/dev/reference/launch_local.md).
- [`daemons()`](https://mirai.r-lib.org/dev/reference/daemons.md) and
  [`dispatcher()`](https://mirai.r-lib.org/dev/reference/dispatcher.md)
  gain the argument ‘pass’ to support password-protected private keys
  when supplying TLS credentials (thanks
  [@wlandau](https://github.com/wlandau)
  [\#76](https://github.com/r-lib/mirai/issues/76)).
- Cryptographic errors when using dispatcher with TLS are now reported
  to the user (thanks [@wlandau](https://github.com/wlandau)
  [\#76](https://github.com/r-lib/mirai/issues/76)).
- Passing a filename to the ‘tls’ argument of
  [`daemons()`](https://mirai.r-lib.org/dev/reference/daemons.md),
  [`launch_local()`](https://mirai.r-lib.org/dev/reference/launch_local.md)
  or
  [`launch_remote()`](https://mirai.r-lib.org/dev/reference/launch_local.md)
  now works correctly as documented.
- Extends and clarifies documentation surrounding use of certificate
  authority signed TLS certificates.
- Certain error messages are more accurate and informative.
- Increases in performance and lower resource utilisation due to updates
  in nanonext 0.10.0.
- Requires nanonext \>= 0.10.0 and R \>= 3.5.

## mirai 0.9.1

CRAN release: 2023-07-19

- Secure TLS connections implemented for distributed computing:
  - Zero-configuration experience - simply specify a `tls+tcp://` or
    `wss://` URL in
    [`daemons()`](https://mirai.r-lib.org/dev/reference/daemons.md).
    Single-use keys and certificates are automatically generated.
  - Alternatively, custom certificates may be passed to the ‘tls’
    argument of
    [`daemons()`](https://mirai.r-lib.org/dev/reference/daemons.md) and
    [`daemon()`](https://mirai.r-lib.org/dev/reference/daemon.md), such
    as those generated via a Ceritficate Signing Request (CSR) to a
    Certificate Authority (CA).
- [`launch_remote()`](https://mirai.r-lib.org/dev/reference/launch_local.md)
  launches daemons on remote machines and/or returns the shell command
  for launching daemons as a character vector.
  - Example using SSH:
    `launch_remote("ws://192.168.0.1:5555", command = "ssh", args = c("-p 22 192.168.0.2", .)`.
- User interface optimised for consistency and ease of use:
  - Documentation updated to refer consistently to host and daemons
    (rather than client and server) for clarity.
  - [`daemon()`](https://mirai.r-lib.org/dev/reference/daemon.md)
    replaces `server()`, which is deprecated (although currently
    retained as an alias).
  - [`launch_local()`](https://mirai.r-lib.org/dev/reference/launch_local.md)
    replaces `launch_server()` and now accepts a vector argument for
    ‘url’ as well as numeric values to select the relevant dispatcher or
    host URL, returning invisible NULL instead of an integer value.
  - [`status()`](https://mirai.r-lib.org/dev/reference/status.md) now
    retrieves connections and daemons status, replacing the call to
    [`daemons()`](https://mirai.r-lib.org/dev/reference/daemons.md) with
    no arguments (which is deprecated). The return value of `$daemons`
    is now always the host URL when not using dispatcher.
- Redirection of stdout and stderr from local daemons to the host
  process is now possible (when running without dispatcher) by
  specifying `output=TRUE` for
  [`daemons()`](https://mirai.r-lib.org/dev/reference/daemons.md) or
  [`launch_local()`](https://mirai.r-lib.org/dev/reference/launch_local.md).
  [`daemon()`](https://mirai.r-lib.org/dev/reference/daemon.md) accepts
  a new ‘output’ argument.
- `saisei()` argument validation now happens prior to sending a request
  to dispatcher rather than on dispatcher.
- A ‘miraiError’ now includes the trailing line break at the end of the
  character vector.
- Requires nanonext \>= 0.9.1, with R requirement relaxed back to \>=
  2.12.

## mirai 0.9.0

CRAN release: 2023-06-24

- mirai 0.9.0 is a major release focusing on stability improvements.
- Improvements to dispatcher:
  - Ensures the first URL retains the same format if `saisei(i = 1L)` is
    called.
  - Optimal scheduling when tasks are submitted prior to any servers
    coming online.
  - Fixes rare occasions where dispatcher running a single server
    instance could get stuck with a task.
  - [`daemons()`](https://mirai.r-lib.org/dev/reference/daemons.md)
    status requests have been rendered more robust.
- Ensures `saisei()` always returns `NULL` if ‘tcp://’ URLs are being
  used as they do not support tokens.
- Daemons status matrix ‘assigned’ and ‘complete’ are now cumulative
  statistics, and not reset upon new instances.
- Requires nanonext \>= 0.9.0 and R \>= 3.5.0.
- Internal performance enhancements.

## mirai 0.8.7

CRAN release: 2023-05-11

- `server()` and
  [`dispatcher()`](https://mirai.r-lib.org/dev/reference/dispatcher.md)
  argument ‘asyncdial’ is now FALSE by default, causing these functions
  to exit if a connection is not immediately available. This means that
  for distributed computing purposes,
  [`daemons()`](https://mirai.r-lib.org/dev/reference/daemons.md) should
  be called before `server()` is launched on remote resources, or else
  `server(asyncdial = TRUE)` allows servers to wait for a connection.
- `launch_server()` now parses the passed URL for correctness before
  attempting to launch a server, producing an error if not valid.

## mirai 0.8.4

CRAN release: 2023-05-09

- The deferred evaluation pipe `%>>%` gains the following enhancements:
  - `.()` implemented to wrap a piped expression, ensuring return of
    either an ‘unresolvedExpr’ or ‘resolvedExpr’.
  - expressions may be tested using
    [`unresolved()`](https://mirai.r-lib.org/dev/reference/unresolved.md)
    in the same way as a ‘mirai’.
  - allows for general use in all contexts, including within functions.
- Improved error messages for top level evaluation errors in a ‘mirai’.
- Requires nanonext \>= 0.8.3.
- Internal stability and performance enhancements.

## mirai 0.8.3

CRAN release: 2023-04-17

- [`mirai()`](https://mirai.r-lib.org/dev/reference/mirai.md) gains the
  following enhancements (thanks
  [@HenrikBengtsson](https://github.com/HenrikBengtsson)):
  - accepts a language or expression object being passed to ‘.expr’ for
    evaluation.
  - accepts a list of ‘name = value’ pairs being passed to ‘.args’ as
    well as the existing ‘…’.
  - objects specified via ‘…’ now take precedence over ‘.args’ if the
    same named object appears.
- [`dispatcher()`](https://mirai.r-lib.org/dev/reference/dispatcher.md)
  gains the following arguments:
  - `token` for appending a unique token to each URL the dispatcher
    listens at.
  - `lock` for locking sockets to prevent more than one server
    connecting at a unique URL.
- `saisei()` implemented to regenerate the token used by a given
  dispatcher socket.
- `launch_server()` replaces `launch()` for launching local instances,
  with a simpler interface directly mapping to `server()`.
- Automatically-launched local daemons revised to use unique tokens in
  their URLs.
- Daemons status matrix headers updated to ‘online’, ‘instance’,
  ‘assigned’, and ‘complete’.
- Fixes potential issue when attempting to use
  [`mirai()`](https://mirai.r-lib.org/dev/reference/mirai.md) with
  timeouts and no connection to a server.
- Requires nanonext \>= 0.8.2.
- Internal performance enhancements.

## mirai 0.8.2

CRAN release: 2023-04-03

- [`dispatcher()`](https://mirai.r-lib.org/dev/reference/dispatcher.md)
  re-implemented using an innovative non-polling design. Efficient
  process consumes zero processor usage when idle and features
  significantly higher throughput and lower latency.
  - Arguments ‘pollfreqh’ and ‘pollfreql’ removed as no longer
    applicable.
- Server and dispatcher processes exit automatically if the connection
  with the client is dropped. This significantly reduces the likelihood
  of orphaned processes.
- `launch()` exported as a utility for easily re-launching daemons that
  have timed out, for instance.
- Correct passthrough of `...` variables in the
  [`daemons()`](https://mirai.r-lib.org/dev/reference/daemons.md) call.
- Requires nanonext \>= 0.8.1.
- Internal performance enhancements.

## mirai 0.8.1

CRAN release: 2023-03-17

- Fixes issue where daemon processes may not launch for certain setups
  (only affecting binary package builds).

## mirai 0.8.0

CRAN release: 2023-03-15

- mirai 0.8.0 is a major feature release. Special thanks to
  [@wlandau](https://github.com/wlandau) for suggestions, discussion and
  testing for many of the new capabilities.
- Compute profiles have been introduced through a new `.compute`
  argument in
  [`daemons()`](https://mirai.r-lib.org/dev/reference/daemons.md) and
  [`mirai()`](https://mirai.r-lib.org/dev/reference/mirai.md) for
  sending tasks with heterogeneous compute requirements.
  - [`daemons()`](https://mirai.r-lib.org/dev/reference/daemons.md) can
    create new profiles to connect to different resources e.g. servers
    with GPU, accelerators etc.
  - [`mirai()`](https://mirai.r-lib.org/dev/reference/mirai.md) tasks
    can be sent using a specific compute profile.
- [`daemons()`](https://mirai.r-lib.org/dev/reference/daemons.md)
  interface has a new `url` argument along with `dispatcher` for using a
  background dispatcher process to ensure optimal FIFO task scheduling
  (now the default).
  - Supplying a client URL with a zero port number `:0` will
    automatically assign a free ephemeral port, with the actual port
    number subsequently reported by
    [`daemons()`](https://mirai.r-lib.org/dev/reference/daemons.md).
  - Calling with no arguments now provides an improved view of the
    current number of connections / daemons (URL, online and busy
    status, tasks assigned and completed, instance), replacing the
    previous `daemons("view")` functionality.
- [`dispatcher()`](https://mirai.r-lib.org/dev/reference/dispatcher.md)
  is implemented as a new function for the dispatcher.
- `server()` gains the following arguments:
  - `asyncdial` to specify how the server dials into the client.
  - `maxtasks` for specifying a maximum number of tasks before exiting.
  - `idletime` for specifying an idle time, since completion of the last
    task before exiting.
  - `walltime` for specifying a soft walltime before exiting.
  - `timerstart` for specifying a minimum number of task completions
    before starting timers.
- Invalid URLs provided to
  [`daemons()`](https://mirai.r-lib.org/dev/reference/daemons.md) and
  `server()` now error and return immediately instead of potentially
  causing a hang.
- `eval_mirai()` is removed as an alias for
  [`mirai()`](https://mirai.r-lib.org/dev/reference/mirai.md).
- ‘mirai’ processes are no longer launched in Rscript sessions with the
  `--vanilla` argument to enable site / user profile and environment
  files to be read.
- Requires nanonext \>= 0.8.0.
- Internal performance enhancements.

## mirai 0.7.2

CRAN release: 2023-01-17

- Internal performance enhancements.

## mirai 0.7.1

CRAN release: 2022-11-15

- Allow user interrupts of
  [`call_mirai()`](https://mirai.r-lib.org/dev/reference/call_mirai.md)
  again (regression in 0.7.0), now returning a ‘miraiInterrupt’.
- Adds auxiliary function
  [`is_mirai_interrupt()`](https://mirai.r-lib.org/dev/reference/is_mirai_error.md)
  to test if an object is a ‘miraiInterrupt’.
- Requires nanonext \>= 0.7.0: returned ‘errorValues’ e.g. mirai
  timeouts are no longer accompanied by warnings.
- Internal performance enhancements.

## mirai 0.7.0

CRAN release: 2022-10-19

- [`daemons()`](https://mirai.r-lib.org/dev/reference/daemons.md) now
  takes ‘n’ and ‘.url’ arguments. ‘.url’ is an optional client URL
  allowing mirai tasks to be distributed across the network.
  Compatibility with existing interface is retained.
- The server function `server()` is exported for creating daemon /
  ephemeral processes on network resources.
- Mirai errors are formatted better and now print to stdout rather than
  stderr.
- Improvements to performance and stability requiring nanonext \>=
  0.6.0.
- Internal enhancements to error handling in a mirai / daemon process.

## mirai 0.6.0

CRAN release: 2022-09-16

- Notice: older package versions will no longer be supported by
  ‘nanonext’ \>= 0.6.0. Please ensure you are using the latest version
  of ‘mirai’ or else refrain from upgrading ‘nanonext’.
- Internal enhancements to
  [`daemons()`](https://mirai.r-lib.org/dev/reference/daemons.md) and
  `%>>%` deferred evaluation pipe.

## mirai 0.5.3

CRAN release: 2022-08-16

- [`mirai()`](https://mirai.r-lib.org/dev/reference/mirai.md) gains a
  ‘.args’ argument for passing a list of objects already in the calling
  environment, allowing for example
  `mirai(func(x, y, z), .args = list(x, y, z))` rather than having to
  specify `mirai(func(x, y, z), x = x, y = y, z = z)`.
- Errors from inside a mirai will now return the error message as a
  character string of class ‘miraiError’ and ‘errorValue’, rather than
  just a nul byte. Utility function
  [`is_mirai_error()`](https://mirai.r-lib.org/dev/reference/is_mirai_error.md)
  should be used in place of
  [`is_nul_byte()`](https://nanonext.r-lib.org/reference/is_error_value.html),
  which is no longer re-exported.
- [`is_error_value()`](https://mirai.r-lib.org/dev/reference/is_mirai_error.md)
  can be used to test for all errors, including timeouts where the
  ‘.timeout’ argument has been used.
- All re-exports from ‘nanonext’ have been brought in-package for better
  documentation.

## mirai 0.5.2

CRAN release: 2022-07-21

- Internal optimisations requiring nanonext \>= 0.5.2.

## mirai 0.5.0

CRAN release: 2022-06-21

- Implements the `%>>%` deferred evaluation pipe.
- Adds ‘.timeout’ argument to
  [`mirai()`](https://mirai.r-lib.org/dev/reference/mirai.md) to ensure
  a mirai always resolves even if the child process crashes etc.

## mirai 0.4.1

CRAN release: 2022-04-21

- Exits cleanly when daemons have not been explicitly zeroed prior to
  ending an R session.
- Fixes possible hang on Windows when shutting down daemons.

## mirai 0.4.0

CRAN release: 2022-04-14

- Back to a pure R implementation thanks to enhanced internal design at
  nanonext.
- Adds auxiliary function
  [`is_mirai()`](https://mirai.r-lib.org/dev/reference/is_mirai.md) to
  test if an object is a mirai.
- Versioning system to synchronise with nanonext e.g. v0.4.x requires
  nanonext \>= 0.4.0.

## mirai 0.2.0

CRAN release: 2022-03-28

- The value of a mirai is now stored at `$data` to optimally align with
  the underlying implementation.
- Package now contains C code (requires compilation), using weak
  references for simpler management of resources.
- Switch to abstract sockets on Linux.

## mirai 0.1.1

CRAN release: 2022-03-15

- [`mirai()`](https://mirai.r-lib.org/dev/reference/mirai.md) added as
  an alias for `eval_mirai()`; supports evaluating arbitrary length
  expressions wrapped in [`{}`](https://rdrr.io/r/base/Paren.html).
- A mirai now resolves automatically without requiring
  [`call_mirai()`](https://mirai.r-lib.org/dev/reference/call_mirai.md).
  Access the `$value` directly and an ‘unresolved’ logical NA will be
  returned if the async operation is yet to complete.
- [`stop_mirai()`](https://mirai.r-lib.org/dev/reference/stop_mirai.md)
  added as a function to stop evaluation of an ongoing async operation.
- Auxiliary functions
  [`is_nul_byte()`](https://nanonext.r-lib.org/reference/is_error_value.html)
  and
  [`unresolved()`](https://mirai.r-lib.org/dev/reference/unresolved.md)
  re-exported from {nanonext} to test for evaluation errors and
  resolution of a ‘mirai’ respectively.
- New [`daemons()`](https://mirai.r-lib.org/dev/reference/daemons.md)
  interface to set and manage persistent background processes for
  receiving ‘mirai’ requests.

## mirai 0.1.0

CRAN release: 2022-02-16

- Initial release.
