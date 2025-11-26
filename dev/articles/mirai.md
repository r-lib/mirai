# mirai - Quick Reference

## Core Concepts

**mirai** = *future* in Japanese. Async evaluation framework for R built
on NNG/nanonext.

**Architecture**: daemons dial into host, a topology which facilitates
dynamic scaling.

This is a cheatsheet. Refer to the [mirai reference
manual](https://mirai.r-lib.org/dev/articles/v01-reference.md) for a
detailed introduction.

## Key Takeaways

- **[`mirai()`](https://mirai.r-lib.org/dev/reference/mirai.md)**
  returns immediately, access result via `m[]` or `m$data`
- **[`daemons()`](https://mirai.r-lib.org/dev/reference/daemons.md)**
  sets persistent background processes
- **Dispatcher** enabled by default for optimal scheduling
- **SSH tunnelling**: Use `local_url(tcp=TRUE)` + `tunnel=TRUE` when
  ports blocked
- **HPC clusters**: Use
  [`cluster_config()`](https://mirai.r-lib.org/dev/reference/cluster_config.md)
  with appropriate scheduler
- **Compute profiles**: Multiple independent daemon sets with `.compute`
  parameter
- **[`mirai_map()`](https://mirai.r-lib.org/dev/reference/mirai_map.md)**:
  Parallel map with progress bars, early stopping, flatmap

## 1. Basic mirai Usage

### Create and Access Results

``` r
library(mirai)

# Create a mirai (returns immediately)
m <- mirai(
  {
    Sys.sleep(1)
    rnorm(5, mean)
  },
  mean = 10
)

# Direct access (non-blocking)
unresolved(m)              # Check if resolved (TRUE if still running)
m$data                     # Returns value (NA if unresolved)

# Access result (blocks until ready)
m[]                        # Wait and return value
collect_mirai(m)           # Wait and return value
call_mirai(m)              # Wait and return mirai object
```

### Passing Data

``` r
# Via ... (assigned to daemon global env)
m <- mirai(func(x), func = my_func, x = data)

# Via .args (local to evaluation env)
m <- mirai(func(x), .args = list(func = my_func, x = data))

# Pass entire environment
write_async <- function(x, file) {
  mirai(write.csv(x, file), .args = environment())
}
```

## 2. Local Daemons

### Basic Setup

``` r
# Set 4 local daemons (with dispatcher - default)
daemons(4)

# Without dispatcher (round-robin distribution)
daemons(4, dispatcher = FALSE)

# Reset daemons
daemons(0)

# Check connection / statistics
info()
```

### Daemon Configuration

``` r
daemons(
  n = 4,
  dispatcher = TRUE,          # Use dispatcher for optimal FIFO scheduling
  cleanup = TRUE,             # Clean env between tasks
  output = FALSE,             # Capture stdout/stderr
  maxtasks = Inf,             # Task limit per daemon
  idletime = Inf,             # Max idle time (ms) before exit
  walltime = Inf              # Time limit (ms) before exit
)
```

### Synchronous Mode (Testing/Debugging)

``` r
daemons(sync = TRUE)          # Run in current process
m <- mirai(Sys.getpid())
daemons(0)
```

## 3. Remote Daemons - SSH Direct

### Setup Host to Accept Remote Connections

``` r
# Listen at host URL with TLS
daemons(
  url = host_url(tls = TRUE),
  remote = ssh_config(c("ssh://10.75.32.90", "ssh://node2:22"))
)

# Or without automatic launching
daemons(url = host_url(tls = TRUE))
launch_remote(2, remote = ssh_config("ssh://10.75.32.90"))
```

### URL Constructors

``` r
host_url()                    # Auto-detect IP, tcp://x.x.x.x:0
host_url(tls = TRUE)          # TLS connection
host_url(tls = TRUE, port = 5555)  # Specific port

local_url()                   # IPC (Unix sockets/named pipes)
local_url(tcp = TRUE)         # tcp://127.0.0.1:0
local_url(tcp = TRUE, port = 5555) # tcp://127.0.0.1:5555
```

### SSH Configuration

``` r
ssh_config(
  remotes = c("ssh://node1:22", "ssh://node2:22"),
  tunnel = FALSE,             # Direct connection
  timeout = 10,               # Connection timeout (seconds)
  command = "ssh",            # SSH executable
  rscript = "Rscript"         # R executable on remote
)
```

**Requirements for SSH Direct**:

- SSH key-based authentication in place
- Host port open to inbound connections from remote
- Remotes dial back to host URL directly

## 4. Remote Daemons - SSH Tunnelling

### When to Use Tunnelling

- Firewall blocks inbound connections to host
- Security policies prevent opening ports
- Connecting to cloud/external machines

### Setup

``` r
# Host uses localhost URL
daemons(
  n = 4,
  url = local_url(tcp = TRUE),              # tcp://127.0.0.1:0
  remote = ssh_config("ssh://10.75.32.90", tunnel = TRUE)
)

# Or with specific port
daemons(
  n = 2,
  url = local_url(tcp = TRUE, port = 5555), # tcp://127.0.0.1:5555
  remote = ssh_config("ssh://remote-server", tunnel = TRUE)
)
```

**How Tunnelling Works**:

1.  Host listens on 127.0.0.1:port
2.  SSH creates reverse tunnel: remote port -\> host port
3.  Remote daemons dial into their own 127.0.0.1:port
4.  Traffic tunnels back through SSH connection

## 5. HPC Cluster Configurations

### General Pattern

``` r
daemons(
  n = 4,
  url = host_url(),
  remote = cluster_config(
    command = "sbatch",  # Scheduler command: "sbatch", "qsub", "bsub", etc.
    options = "#SBATCH --job-name=mirai
               #SBATCH --mem=16G
               #SBATCH --cpus-per-task=1
               #SBATCH --output=mirai_%j.out
               #SBATCH --error=mirai_%j.err
               module load R/4.5.0",
    rscript = file.path(R.home("bin"), "Rscript")
  )
)
```

### Scheduler-Specific Directives

| Scheduler      | Command  | Job Name                  | Memory            | CPUs                |
|----------------|----------|---------------------------|-------------------|---------------------|
| **Slurm**      | `sbatch` | `#SBATCH --job-name=NAME` | `--mem=16G`       | `--cpus-per-task=1` |
| **SGE**        | `qsub`   | `#$ -N NAME`              | `-l mem_free=16G` | `-pe smp 1`         |
| **Torque/PBS** | `qsub`   | `#PBS -N NAME`            | `-l mem=16gb`     | `-l nodes=1:ppn=1`  |
| **LSF**        | `bsub`   | `#BSUB -J NAME`           | `-M 16000`        | `-n 1`              |

## 6. Manual Daemon Deployment

### Generate Launch Commands

``` r
# Set daemons to listen
daemons(url = host_url(tls = TRUE))

# Get launch commands (doesn't execute)
cmds <- launch_remote(
  n = 2,
  remote = remote_config()  # Empty config returns commands
)

# Copy/paste commands to run on remote machines
# E.g. Rscript -e "mirai::daemon('tcp://10.75.32.70:5555')"
print(cmds)
```

## 7. Compute Profiles

### Multiple Independent Profiles

``` r
# Create CPU profile
daemons(4, .compute = "cpu")

# Create GPU profile
daemons(2, .compute = "gpu")

# Direct tasks to specific profile
m_cpu <- mirai(heavy_compute(), .compute = "cpu")
m_gpu <- mirai(gpu_task(), .compute = "gpu")

# Reset specific profile
daemons(0, .compute = "cpu")
```

### Scoped Profiles

``` r
# Temporarily use profile
with_daemons("gpu", {
  model <- mirai(train_model())
})

# Set profile for scope
local_daemons("cpu")
m <- mirai(task())  # Uses "cpu" profile
```

## 8. Common Patterns

### Temporary Daemons

``` r
with(daemons(4), {
  m1 <- mirai(task1())
  m2 <- mirai(task2())
  c(m1[], m2[])
})
# Daemons auto-reset on exit
```

### Mixed Local/Remote Resources

``` r
daemons(url = host_url())
launch_local(2)             # 2 local daemons
launch_remote(4, ssh_config("ssh://remote"))  # 4 remote
```

### Dynamic Scaling

``` r
daemons(url = host_url())   # Start listening
launch_local(2)   # Add 2 daemons
# Later...
# Add 2 more (automatically exit after idle for 60 secs)
launch_local(2, idletime = 60000)
```

## 9. mirai_map - Parallel Map

### Basic Usage

``` r
daemons(4)

# Simple map
results <- mirai_map(1:10, sqrt)[]

# With additional arguments
results <- mirai_map(
  1:10,
  rnorm,
  .args = list(mean = 5, sd = 2)
)[]

# With helper functions
results <- mirai_map(
  1:100,
  function(x) transform(x, helper),
  helper = my_helper_func
)[]
```

### Collection Options

``` r
# Flatten to vector
results <- mirai_map(1:10, rnorm, .args = list(n = 1))[.flat]

# Progress bar
results <- mirai_map(1:100, slow_func)[.progress]

# Early stopping on error
results <- mirai_map(data_list, process)[.stop]

# Combine options
results <- mirai_map(1:100, task)[.stop, .progress]
```

### Multiple Map (over DataFrame/Matrix)

``` r
# Map over dataframe rows
df <- data.frame(x = 1:10, y = 11:20)
mirai_map(df, function(x, y) x + y)[.flat]

# Map over matrix rows
mat <- matrix(1:6, nrow = 3, dimnames = list(c("a","b","c"), c("x","y")))
mirai_map(mat, function(x, y) x * y)[]
```

## 10. Error Handling

``` r
m <- mirai(stop("error"))
m[]

# Test error types
is_mirai_error(m$data)      # Execution error
is_mirai_interrupt(m$data)  # User interrupt
is_error_value(m$data)      # Any error (catch-all)

# Access error details
m$data$stack.trace          # Full stack trace
m$data$condition.class      # Original error classes
m$data$message              # Error message
```

## 11. Monitoring and Status

``` r
status()                    # Detailed status
info()                      # Concise statistics

daemons_set()               # Check if daemons exist
require_daemons()           # Error if not set
```

## 12. Advanced Features

### Timeouts

``` r
# Per-mirai timeout (requires dispatcher for auto-cancellation)
m <- mirai(Sys.sleep(10), .timeout = 1000)  # 1 second
m[]  # Returns errorValue 5 (timed out)
```

### Cancellation

``` r
# Cancel mirai (requires dispatcher)
m <- mirai(Sys.sleep(100))
stop_mirai(m)  # Attempts cancellation
m$data         # errorValue 20 (canceled)
```

### Evaluation Everywhere

``` r
# Load package on all daemons
everywhere(library(data.table))

# Export variables to all daemons
everywhere(config <<- list(threads = 4))

# Export variables to all daemons
everywhere({}, db_conn = my_conn, api_key = key)
```

### Random Seeds (Reproducible)

``` r
# Statistically-sound but non-reproducible (default)
daemons(4, seed = NULL)

# Reproducible RNG (seed per mirai call)
daemons(4, seed = 123)
```

### Custom Serialization

``` r
# For torch tensors, Arrow tables, Polars objects
daemons(
  4,
  serial = serial_config(
    "torch_tensor",
    sfunc = torch::torch_serialize,
    ufunc = torch::torch_load
  )
)

# Global registration
register_serial("torch_tensor", torch::torch_serialize, torch::torch_load)
daemons(4)  # Auto-applies registered configs
```

### TLS Configuration

``` r
# Auto TLS (zero-config certificates)
daemons(url = host_url(tls = TRUE))

# Custom certificate
daemons(
  url = host_url(tls = TRUE),
  tls = "/path/to/cert.pem",
  pass = function() askpass::askpass()
)
```

## 13. Dispatcher vs. Direct

| Feature       | With Dispatcher (default) | Direct (dispatcher=FALSE) |
|---------------|---------------------------|---------------------------|
| Scheduling    | Optimal FIFO              | Round-robin               |
| Timeouts      | ✓                         | No auto-cancellation      |
| Cancellation  | ✓                         | ✗                         |
| Serialization | ✓                         | ✗                         |
| Overhead      | Slightly higher           | Minimal                   |
| Use case      | Variable task times       | Similar task times        |

## 14. Quick Decision Tree

    ┌─ Need async in R?
    │
    ├─ Single task → mirai()
    │  └─ No daemons set? → ephemeral (auto-creates process)
    │
    ├─ Map operation → mirai_map()
    │  └─ Requires daemons() to be set first
    │
    └─ Multiple tasks → Set up daemons
       │
       ├─ Local only
       │  └─ daemons(n)
       │
       ├─ Remote with open ports
       │  └─ daemons(url = host_url(), remote = ssh_config(..., tunnel = FALSE))
       │
       ├─ Remote with firewall/blocked ports
       │  └─ daemons(url = local_url(tcp = TRUE), remote = ssh_config(..., tunnel = TRUE))
       │
       └─ HPC cluster (Slurm/SGE/PBS/LSF)
          └─ daemons(url = host_url(), remote = cluster_config(...))

## 15. Common Gotchas

``` r
# Expression Evaluation
mirai(pkg::func(x), x = data)
# Namespace functions OR library() inside expression
mirai(func(x), func = my_func, x = data)
# Pass dependencies explicitly via ... or .args

# Dispatcher Required For
stop_mirai(m)                           # Cancellation
mirai(task(), .timeout = 1000)          # Timeout cancellation
daemons(4, serial = serial_config(...)) # Custom serialization

# SSH Tunnelling
daemons(url = local_url(tcp = TRUE), remote = ssh_config(..., tunnel = TRUE))
# Must use 127.0.0.1 (not external IP) + tunnel = TRUE

# TLS
host_url(tls = TRUE)                    # Auto TLS (zero-config, just works)
# Custom certs: provide cert path + optional passphrase function

# Remote Prerequisites
# - SSH key-based auth configured beforehand
# - SSH direct: host port open to inbound connections
# - HPC: correct module load commands and scheduler directives
```
