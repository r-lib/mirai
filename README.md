
<!-- README.md is generated from README.Rmd. Please edit that file -->

# mirai <a href="https://mirai.r-lib.org/" alt="mirai"><img src="man/figures/logo.png" alt="mirai logo" align="right" width="120"/></a>

<!-- badges: start -->

[![CRAN
status](https://www.r-pkg.org/badges/version/mirai)](https://CRAN.R-project.org/package=mirai)
[![R-universe
status](https://r-lib.r-universe.dev/badges/mirai)](https://r-lib.r-universe.dev/mirai)
[![R-CMD-check](https://github.com/r-lib/mirai/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/r-lib/mirai/actions/workflows/R-CMD-check.yaml)
[![Codecov test
coverage](https://codecov.io/gh/r-lib/mirai/graph/badge.svg)](https://app.codecov.io/gh/r-lib/mirai)
[![DOI](https://zenodo.org/badge/459341940.svg)](https://zenodo.org/badge/latestdoi/459341940)
<!-- badges: end -->

### ミライ

<br /> みらい 未来 <br /><br /> Minimalist Async Evaluation Framework
for R <br /><br />

mirai is a comprehensive solution for performing
computationally-intensive tasks efficiently.

→ Run R code in parallel in the background, without blocking your
session

→ Distribute workloads across local or remote machines

→ Execute tasks on different compute resources based on requirements

→ Perform actions as soon as tasks complete via promises

<br />

### Installation

``` r
install.packages("mirai")
```

### Quick Start

→ `mirai()`: Evaluate an R expression asynchronously in a parallel
process.

→ `daemons()`: Set and launch persistent background processes, local or
remote, on which to run mirai tasks.

``` r
library(mirai)
daemons(5)

m <- mirai({
  Sys.sleep(1)
  100 + 42
})

mp <- mirai_map(1:9, \(x) {
  Sys.sleep(1)
  x^2
})

m
#> < mirai [] >
m[]
#> [1] 142

mp
#> < mirai map [4/9] >
mp[.flat]
#> [1]  1  4  9 16 25 36 49 64 81

daemons(0)
```

### Design Concepts

mirai is designed from the ground up to provide a production-grade
experience.

→ Modern

- Current technologies built on
  [nanonext](https://github.com/r-lib/nanonext/) and
  [NNG](https://nng.nanomsg.org/)
- Communications layer supports IPC (Inter-Process Communication),
  TCP/IP and TLS

→ Efficient

- 1,000x more responsive vs. other alternatives
  [<sup>\[1\]</sup>](https://github.com/r-lib/mirai/pull/142#issuecomment-2457589563)
- Ideal for low-latency applications e.g. real time inference & Shiny
  apps

→ Reliable

- No reliance on global options or variables for consistent behaviour
- Explicit evaluation for transparent and predictable results

→ Scalable

- Capacity for millions of tasks over thousands of connections
- Proven track record for heavy-duty workloads in the life sciences
  industry

### Key Features

→ Distributed Execution: Run tasks across networks and clusters using
various deployment methods (SSH, HPC clusters using Slurm, SGE, Torque,
PBS, LSF, etc.)

→ Compute Profiles: Manage different sets of daemons independently,
allowing tasks with different requirements to be executed on appropriate
resources.

→ Promises Integration: An event-driven implementation performs actions
on returned values as soon as tasks complete, ensuring minimal latency.

→ Serialization Support: Native serialization support for reference
objects such as Arrow Tables, Polars DataFrames or torch tensors.

→ Error Handling: Robust error handling and reporting, with full stack
traces for debugging.

→ RNG Management: L’Ecuyer-CMRG RNG streams for reproducible random
number generation in parallel execution.

### Powering the Ecosystem

mirai serves as a foundation for asynchronous and parallel computing in
the R ecosystem:

[<img alt="R parallel" src="https://www.r-project.org/logo/Rlogo.png" width="40" height="31" />](https://mirai.r-lib.org/articles/v04-parallel.html)
  Implements the first official alternative communications backend for R
— the ‘MIRAI’ parallel cluster — fulfilling a feature request by R-Core
at R Project Sprint 2023.

[<img alt="purrr" src="https://purrr.tidyverse.org/logo.png" width="40" height="46" />](https://purrr.tidyverse.org)
  Powers parallel map for the purrr functional programming toolkit, a
core tidyverse package.

[<img alt="promises" src="https://solutions.posit.co/images/brand/posit-icon-fullcolor.svg" width="40" height="36" />](https://mirai.r-lib.org/articles/v02-promises.html)
  Promises for ‘mirai’ and ‘mirai_map’ objects are event-driven,
providing the lowest latency and highest responsiveness for
performance-critical applications.

[<img alt="Shiny" src="https://github.com/rstudio/shiny/raw/main/man/figures/logo.png" width="40" height="46" />](https://mirai.r-lib.org/articles/v02-promises.html)
  The primary async backend for Shiny, with full ExtendedTask support,
providing the next level of responsiveness and scalability for Shiny
apps.

[<img alt="plumber2" src="https://github.com/posit-dev/plumber2/raw/main/man/figures/logo.svg" width="40" height="46" />](https://mirai.r-lib.org/articles/v02-promises.html)
  The built-in async evaluator behind the `@async` tag in plumber2; also
provides an async backend for Plumber.

[<img alt="torch" src="https://torch.mlverse.org/css/images/hex/torch.png" width="40" height="46" />](https://mirai.r-lib.org/articles/v03-serialization.html)
  Allows Torch tensors and complex objects such as models and optimizers
to be used seamlessly across parallel processes.

[<img alt="Arrow" src="https://arrow.apache.org/img/arrow-logo_hex_black-txt_white-bg.png" width="40" height="46" />](https://mirai.r-lib.org/articles/v03-serialization.html)
  Allows queries using the Apache Arrow format to be handled seamlessly
over ADBC database connections hosted in background processes.

[<img alt="Polars" src="https://github.com/pola-rs/polars-static/raw/master/logos/polars_logo_blue.svg" width="40" height="46" />](https://mirai.r-lib.org/articles/v03-serialization.html)
  R Polars is a pioneer of mirai’s serialization registration mechanism,
which allows transparent use of Polars objects across parallel
processes, with no user setup required.

[<img alt="targets" src="https://github.com/ropensci/targets/raw/main/man/figures/logo.png" width="40" height="46" />](https://docs.ropensci.org/targets/)
  Targets, a make-like pipeline tool, uses crew as its default
high-performance computing backend. Crew is a distributed worker
launcher extending mirai to different computing platforms, from
traditional clusters to cloud services.

### Thanks

We would like to thank in particular:

[Will Landau](https://github.com/wlandau/) for being instrumental in
shaping development of the package, from initiating the original request
for persistent daemons, through to orchestrating robustness testing for
the high performance computing requirements of crew and targets.

[Joe Cheng](https://github.com/jcheng5/) for integrating the ‘promises’
method to work seamlessly within Shiny, and prototyping event-driven
promises.

[Luke Tierney](https://github.com/ltierney/) of R Core, for discussion
on L’Ecuyer-CMRG streams to ensure statistical independence in parallel
processing, and making it possible for mirai to be the first
‘alternative communications backend for R’.

[Travers Ching](https://github.com/traversc) for a novel idea in
extending the original custom serialization support in the package.

[Hadley Wickham](https://github.com/hadley) for original implementations
of the scoped helper functions, on which ours are based.

[Henrik Bengtsson](https://github.com/HenrikBengtsson/) for valuable
insights leading to the interface accepting broader usage patterns.

[Daniel Falbel](https://github.com/dfalbel/) for discussion around an
efficient solution to serialization and transmission of torch tensors.

[Kirill Müller](https://github.com/krlmlr/) for discussion on using
parallel processes to host Arrow database connections.

### Links & References

◈ mirai R package: <https://mirai.r-lib.org/> <br /> ◈ nanonext R
package: <https://nanonext.r-lib.org/>

mirai is listed in CRAN High Performance Computing Task View: <br />
<https://cran.r-project.org/view=HighPerformanceComputing>

–

Please note that this project is released with a [Contributor Code of
Conduct](https://mirai.r-lib.org/CODE_OF_CONDUCT.html). By participating
in this project you agree to abide by its terms.
