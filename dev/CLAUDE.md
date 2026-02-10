# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working
with code in this repository.

## Overview

mirai is a minimalist async evaluation framework for R that provides
asynchronous, parallel and distributed computing. Built on nanonext and
NNG (Nanomsg-Next-Generation), it implements a message-passing paradigm
where daemons (persistent background processes) execute tasks sent by
the host process. Only runtime dependency: nanonext (\>= 1.8.0).
Requires R \>= 3.6.

## Development Commands

### Testing

``` r
# Run all tests (single file, custom minitest framework — not testthat)
source("tests/tests.R")
```

Set `NOT_CRAN=true` environment variable to run extended tests that
require network connectivity.

### Building and Checking

``` bash
# Build package
R CMD build .

# Check package (matches CI)
R CMD check --no-manual --compact-vignettes=gs+qpdf mirai_*.tar.gz
```

``` r
# Generate documentation from roxygen2 comments
devtools::document()
```

### Code Formatting

Uses [Air](https://posit-dev.github.io/air/) formatter configured in
`air.toml`: - Line width: 100, indent: 2 spaces,
`persistent-line-breaks = false` - **tests/ directory is excluded** from
Air formatting

### Vignettes

Vignettes are pre-compiled because they require daemon connections.
Source files live in `dev/vignettes/_*.Rmd` and compile to
`vignettes/*.Rmd`:

``` r
# Pre-compile all vignettes (uses knitr::knit, not litedown)
source("dev/vignettes/precompile.R")

# Build README
rmarkdown::render("README.Rmd")
```

The package uses **litedown** (not knitr) as VignetteBuilder for final
rendering.

## Key Architecture

### Core Components

- **mirai()**: Creates an async evaluation, returns immediately with a
  ‘mirai’ object
- **daemons()**: Sets up persistent background daemon processes
- **daemon()**: The daemon instance running in background processes
- **dispatcher()**: FIFO scheduler (reimplemented in C in nanonext
  1.8.0+ for ~50% less overhead)
- **mirai_map()**: Async parallel map with progress bars and early
  stopping
- **everywhere()**: Evaluates expressions on all connected daemons

### Message-Passing Topology

Daemons **dial into** the host/dispatcher (not vice versa). The
host/dispatcher listens at a URL, enabling dynamic addition/removal of
compute resources. Supports IPC (platform-dependent), TCP, and TLS
transports.

### Dispatcher vs. Direct Connection

- **With Dispatcher** (`dispatcher = TRUE`, default): FIFO scheduling,
  cancellation via
  [`stop_mirai()`](https://mirai.r-lib.org/dev/reference/stop_mirai.md),
  custom serialization support
- **Direct Connection** (`dispatcher = FALSE`): Round-robin
  distribution, lower overhead, no cancellation/serialization support

### Evaluation Model

Expressions evaluate in a **clean environment** (not global), containing
only objects supplied via `.args`. Objects passed through `...` are
assigned to the daemon’s global environment. All dependencies must be
passed explicitly.

### Compute Profiles

Multiple named profiles can coexist via the `.compute` parameter.
Default profile is “default”.

## Internal State Management

Understanding these package-level environments in `mirai-package.R` is
essential for working on the codebase:

- **`.`**: Stores the current compute profile name (default:
  `"default"`) under key `"cp"`
- **`..`**: Stores compute profile configurations (daemon URLs,
  connections, etc.)
- **`.opts`**: Collection options for
  [`mirai_map()`](https://mirai.r-lib.org/dev/reference/mirai_map.md)
  (`.flat`, `.progress`, `.stop`)
- **`._`**: Error message templates (created with `hash = TRUE` for fast
  lookup)

### Platform-Specific Initialization

`.onLoad` sets platform-dependent defaults: - **Linux**: `abstract://`
URL scheme (abstract Unix domain sockets) - **macOS/POSIX**:
`ipc:///tmp/` URL scheme (Unix domain sockets) - **Windows**: `ipc://`
URL scheme (named pipes)

Also caches the Rscript path in `.command` and checks for cli package
availability.

## Code Organization

### R/ Directory Structure

- **mirai-package.R**: Package docs, `.onLoad`, global state (`.`, `..`,
  `.opts`, `._`), constants
- **mirai.R**: Core
  [`mirai()`](https://mirai.r-lib.org/dev/reference/mirai.md),
  [`unresolved()`](https://mirai.r-lib.org/dev/reference/unresolved.md),
  [`call_mirai()`](https://mirai.r-lib.org/dev/reference/call_mirai.md),
  [`stop_mirai()`](https://mirai.r-lib.org/dev/reference/stop_mirai.md),
  [`everywhere()`](https://mirai.r-lib.org/dev/reference/everywhere.md),
  [`race_mirai()`](https://mirai.r-lib.org/dev/reference/race_mirai.md)
- **daemons.R**:
  [`daemons()`](https://mirai.r-lib.org/dev/reference/daemons.md),
  remote configs, compute profiles,
  [`with_daemons()`](https://mirai.r-lib.org/dev/reference/with_daemons.md),
  [`local_daemons()`](https://mirai.r-lib.org/dev/reference/with_daemons.md)
- **daemon.R**: Daemon instance implementation
- **dispatcher.R**: Dispatcher process (thin wrapper — core logic now in
  C via nanonext)
- **map.R**:
  [`mirai_map()`](https://mirai.r-lib.org/dev/reference/mirai_map.md)
  with collection options
- **launchers.R**:
  [`launch_local()`](https://mirai.r-lib.org/dev/reference/launch_local.md),
  [`launch_remote()`](https://mirai.r-lib.org/dev/reference/launch_local.md),
  [`remote_config()`](https://mirai.r-lib.org/dev/reference/remote_config.md),
  [`ssh_config()`](https://mirai.r-lib.org/dev/reference/ssh_config.md),
  [`cluster_config()`](https://mirai.r-lib.org/dev/reference/cluster_config.md),
  [`http_config()`](https://mirai.r-lib.org/dev/reference/http_config.md)
- **parallel.R**:
  [`make_cluster()`](https://mirai.r-lib.org/dev/reference/make_cluster.md)
  — official alternative communications backend for R’s parallel package
- **promises.R**: Promises integration for async workflows and Shiny
  ExtendedTask
- **next.R**: Developer interface
  ([`nextstream()`](https://mirai.r-lib.org/dev/reference/nextstream.md),
  [`nextget()`](https://mirai.r-lib.org/dev/reference/nextstream.md))
  for packages extending mirai
- **otel.R**: OpenTelemetry distributed tracing integration

## Testing Framework

Uses **minitest**, a minimal custom framework defined at the top of
`tests/tests.R`: - `test_true()`, `test_false()`, `test_null()`,
`test_notnull()`, `test_zero()` - `test_type()`, `test_class()`,
`test_equal()`, `test_identical()` - `test_error()` for expecting errors
with optional message matching - `test_print()` for verifying
printability

All tests run sequentially in a single file. Extended tests (daemon
connectivity, dispatcher) are gated behind `NOT_CRAN=true`.

## Error Handling

Custom error classes with structured information: - **miraiError**:
Wraps errors from daemon evaluation, preserves `$stack.trace` and
`$condition.class` - **miraiInterrupt**: Represents task cancellation -
Both support
[`conditionMessage()`](https://rdrr.io/r/base/conditions.html) and
[`conditionCall()`](https://rdrr.io/r/base/conditions.html) methods

## CI/CD

GitHub Actions in `.github/workflows/`: - **R-CMD-check.yaml**: 8
OS/R-version combinations (Ubuntu ARM devel, Ubuntu release/oldrel,
macOS release/oldrel, Windows release/oldrel) - **test-coverage.yaml**:
Coverage via covr, uploaded to codecov - **pkgdown.yaml**: Documentation
site with tidytemplate - **shiny-coreci.yaml**: Shiny integration tests
(manual trigger) - **pr-commands.yaml**: PR comment commands `/document`
(roxygen2) and `/style` (styler)

## Package Conventions

- roxygen2 with markdown support; NAMESPACE is auto-generated
- Version: major.minor.patch.dev (e.g., 2.5.3.9000 for development)
- MIT license, r-lib GitHub organization, maintained by Posit Software,
  PBC
- `CLAUDE.md` and `.claude/` are excluded from package builds (via
  `.Rbuildignore`)
