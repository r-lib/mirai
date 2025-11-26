# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working
with code in this repository.

## Overview

mirai is a minimalist async evaluation framework for R that provides
asynchronous, parallel and distributed computing. It’s built on nanonext
and NNG (Nanomsg-Next-Generation), implementing a message-passing
paradigm where daemons (persistent background processes) execute tasks
sent by the host process.

## Key Architecture

### Core Components

- **mirai()**: Creates an asynchronous evaluation that returns
  immediately with a ‘mirai’ object
- **daemons()**: Sets up persistent background daemon processes to
  receive mirai requests
- **daemon()**: The daemon instance that runs in background processes to
  execute tasks
- **dispatcher()**: Optional scheduler process that ensures optimal FIFO
  scheduling and enables features like cancellation and custom
  serialization
- **mirai_map()**: Asynchronous parallel map over lists/vectors with
  progress bars and early stopping
- **everywhere()**: Evaluates expressions on all connected daemons (for
  loading packages/exporting data)

### Message-Passing Topology

The network topology has daemons **dial into** the host/dispatcher (not
vice versa). The host/dispatcher listens at a URL, allowing dynamic
addition/removal of compute resources. This inverted topology design
enables: - Local daemons via IPC (Unix sockets on Linux/macOS, named
pipes on Windows) - Remote daemons via TCP/TLS (including automatic
zero-config TLS certificate generation) - Distributed computing across
networks - True dynamic scaling

### Dispatcher vs. Direct Connection

**With Dispatcher (default)**: `dispatcher = TRUE` - Optimal FIFO
scheduling - tasks queued and sent to next available daemon - Enables
mirai cancellation via
[`stop_mirai()`](https://mirai.r-lib.org/dev/reference/stop_mirai.md) -
Enables timeout cancellation (not just timeout detection) - Required for
custom serialization configurations - Slight additional overhead

**Direct Connection**: `dispatcher = FALSE` - Round-robin distribution -
tasks sent directly to daemons - Lower overhead, more
resource-efficient - Best for similar-length tasks or when concurrent
tasks \< available daemons - No cancellation or custom serialization
support

### Evaluation Model

Expressions evaluate in a **clean environment** (not global), containing
only objects supplied via `.args`. Objects passed through `...` are
assigned to the global environment of the daemon process. This
clean-room approach requires explicit passing of all dependencies to
prevent surprises from hidden state.

### Compute Profiles

Multiple named compute profiles can coexist, each with its own daemons
configuration. Use the `.compute` parameter in functions like
[`mirai()`](https://mirai.r-lib.org/dev/reference/mirai.md),
[`daemons()`](https://mirai.r-lib.org/dev/reference/daemons.md),
[`launch_local()`](https://mirai.r-lib.org/dev/reference/launch_local.md),
etc. to specify which profile to use. Default profile is “default”.

### Random Number Generation

Uses L’Ecuyer-CMRG RNG streams for statistical independence across
parallel processes, following base R’s parallel package conventions.

- **Default (`seed = NULL`)**: New stream per daemon (statistically
  sound, non-reproducible across runs)
- **Reproducible (`seed = integer`)**: New stream per mirai call
  (deterministic, reproducible results)

## Development Commands

### Testing

``` r
# Run all tests (uses custom minitest framework)
source("tests/tests.R")

# Tests are in tests/tests.R - a single file using minitest, not testthat
```

### Building and Checking

``` bash
# Build package
R CMD build .

# Check package (as done in CI)
R CMD check --no-manual --compact-vignettes=gs+qpdf mirai_*.tar.gz
```

``` r
# Generate documentation (from R)
devtools::document()
```

### Code Formatting

``` bash
# Format R code using Air (defined in air.toml)
# Line width: 100, indent: 2 spaces
```

### Documentation

``` r
# Build README from README.Rmd
rmarkdown::render("README.Rmd")

# Build vignettes (uses litedown, not knitr)
# Vignettes are in dev/vignettes/*.Rmd and pre-compiled to vignettes/*.Rmd
```

## Code Organization

### R/ Directory Structure

- **mirai.R**: Core mirai() function, unresolved(), call_mirai(),
  stop_mirai(), everywhere(), race_mirai()
- **daemons.R**: Setup functions for daemon infrastructure including
  daemons(), remote configurations, compute profiles, with_daemons(),
  local_daemons()
- **daemon.R**: The daemon instance implementation that runs in
  background processes
- **dispatcher.R**: Dispatcher process for optimal FIFO scheduling
- **map.R**: mirai_map() for parallel map operations with collection
  options (.flat, .progress, .stop)
- **launchers.R**: launch_local() and launch_remote() for deploying
  daemons; remote_config(), ssh_config(), cluster_config()
- **parallel.R**: Integration with R’s parallel package via
  make_cluster() - the first official alternative communications backend
  for R
- **promises.R**: Integration with the promises package for async
  workflows and Shiny ExtendedTask support
- **next.R**: Developer interface utilities (nextstream(), nextget())
  for packages extending mirai
- **otel.R**: OpenTelemetry integration for distributed tracing

### Dependencies

- **nanonext**: Core dependency providing NNG bindings for IPC/TCP/TLS
  communication
- **cli** (suggested): For progress bars in mirai_map
- **promises** (enhanced): For async promise integration
- **parallel** (enhanced): For MIRAI cluster type
- **otel**, **otelsdk** (suggested): For OpenTelemetry integration

## Testing Framework

This package uses **minitest**, a minimal custom testing framework
defined at the top of tests/tests.R. It provides: - `test_true()`,
`test_false()`, `test_null()`, `test_notnull()`, `test_zero()` -
`test_type()`, `test_class()`, `test_equal()`, `test_identical()` -
`test_error()` for expecting errors with optional message matching -
`test_print()` for verifying printability

Tests run sequentially in a single file rather than using testthat’s
directory structure.

## Serialization System

mirai supports custom serialization for non-exportable reference objects
(torch tensors, Arrow tables, Polars objects). This is configured via: -
[`serial_config()`](https://mirai.r-lib.org/dev/reference/serial_config.md)
for per-daemon configuration (requires dispatcher) -
[`register_serial()`](https://mirai.r-lib.org/dev/reference/register_serial.md)
for global registration - Serialization functions are applied during
message passing between host and daemons - Enables cross-language data
formats and zero-copy transfers

## OpenTelemetry Integration

Optional distributed tracing support via the otel package. When enabled,
mirai creates spans for: - “mirai” spans (client-side) - “daemon eval”
spans (server-side) - “mirai_map” spans - Links between spans preserve
distributed context across processes

## CI/CD

GitHub Actions workflows in .github/workflows/: - **R-CMD-check.yaml**:
Comprehensive checks across multiple R versions (oldrel-1, release,
devel) and platforms (Ubuntu, macOS, Windows) - **test-coverage.yaml**:
Code coverage via codecov - **pkgdown.yaml**: Documentation site
generation - **shiny-coreci.yaml**: Shiny core CI integration -
**rhub.yaml**: Additional platform testing

## Remote Daemon Deployment

### SSH Direct Connection

- Requires SSH key-based authentication
- Host port must be open to inbound connections from remotes
- Daemons dial back to host URL directly
- Use `ssh_config(remotes, tunnel = FALSE)`

### SSH Tunnelling

- Use when firewall blocks inbound connections to host
- Creates reverse SSH tunnel: remote port -\> host port
- Host URL must be `tcp://127.0.0.1:port` (use `local_url(tcp = TRUE)`)
- Daemons dial into their own localhost, traffic tunnels through SSH
- Use `ssh_config(remotes, tunnel = TRUE)`

### HPC Cluster Managers

Supported via
[`cluster_config()`](https://mirai.r-lib.org/dev/reference/cluster_config.md): -
**Slurm**: sbatch (batch), srun (interactive) - **SGE**: qsub -
**Torque/PBS**: qsub - **LSF**: bsub

Configuration includes job options (memory, output files, etc.) and
optional module loading commands.

### Manual Deployment

Use
[`remote_config()`](https://mirai.r-lib.org/dev/reference/remote_config.md)
with empty arguments to generate shell commands for manual copy/paste to
remote machines.

## Helper Functions

### URL Constructors

- `host_url(tls, port)`: Constructs host URL based on detected IP
  address
- `local_url(tcp, port)`: Generates IPC URL or localhost TCP URL

### Scope Management

- `with_daemons(.compute, expr)`: Temporarily use a specific compute
  profile
- `local_daemons(.compute, frame)`: Set profile for current scope

### Status and Monitoring

- `status(.compute)`: Detailed status (connections, URL, mirai counts)
- `info(.compute)`: Concise statistics vector
- `daemons_set(.compute)`: Check if daemons exist
- `require_daemons(.compute)`: Error if daemons not set

## Package Conventions

- Uses roxygen2 for documentation with markdown support
- NAMESPACE is auto-generated via roxygen2
- Version follows R package conventions: major.minor.patch.dev (e.g.,
  2.5.2.9000 for development)
- MIT license
- Part of the r-lib GitHub organization
- Maintained by Posit Software, PBC
