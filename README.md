
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

→ Run R code in parallel without blocking your session

→ Distribute workloads across local or remote machines

→ Execute tasks on different compute resources as required

→ Perform actions reactively as soon as tasks complete

<br />

### Installation

``` r
install.packages("mirai")
```

### Quick Start

`mirai()` evaluates an R expression asynchronously in a parallel
process.

`daemons()` sets up persistent background processes for parallel
computations.

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

### Design Philosophy

⚙️ **Modern Foundation**

- Architected on current communication technologies (IPC, TCP, secure
  TLS)
- Professional queueing and scheduling built on
  [nanonext](https://github.com/r-lib/nanonext/) and
  [NNG](https://github.com/nanomsg/nng/)
- Engineered for custom serialization of cross-language data formats
  (e.g. torch, Arrow)

⚡️ **Extreme Performance**

- Scales to millions of tasks across thousands of connections
- Delivers 1,000x greater efficiency and responsiveness over
  alternatives
- Zero-latency, event-driven promises optimized for real-time
  applications

🚀 **Production First**

- Clear evaluation model with clean environment separation and explicit
  object passing
- Transparent and robust operation from minimal complexity and no hidden
  state
- Enhanced observability through OpenTelemetry integration

🌐 **Deploy Everywhere**

- Deploy across local, remote (SSH), and HPC environments (Slurm, SGE,
  PBS, LSF)
- Compute profiles manage independent daemon pools and resource types
- Distribute workload to optimal resources using multiple compute
  profiles

### Powers the R Ecosystem

mirai serves as a foundation for asynchronous and parallel computing in
the R ecosystem:

[<img alt="R parallel" src="https://www.r-project.org/logo/Rlogo.png" width="40" height="31" />](https://mirai.r-lib.org/articles/v04-parallel.html)
  The first official alternative communications backend for R, the
‘MIRAI’ parallel cluster, a feature request by R-Core.

[<img alt="purrr" src="https://purrr.tidyverse.org/logo.png" width="40" height="46" />](https://purrr.tidyverse.org)
  Powers parallel map for purrr, a core tidyverse package.

[<img alt="Shiny" src="https://github.com/rstudio/shiny/raw/main/man/figures/logo.png" width="40" height="46" />](https://mirai.r-lib.org/articles/v02-promises.html)
  Primary async backend for Shiny with full ExtendedTask support.

[<img alt="plumber2" src="https://github.com/posit-dev/plumber2/raw/main/man/figures/logo.svg" width="40" height="46" />](https://mirai.r-lib.org/articles/v02-promises.html)
  Built-in async evaluator enabling the `@async` tag in plumber2.

[<img alt="tidymodels" src="https://www.tidymodels.org/images/tidymodels.png" width="40" height="46" />](https://tune.tidymodels.org/)
  Core parallel processing infrastructure provider for tidymodels.

[<img alt="torch" src="https://torch.mlverse.org/css/images/hex/torch.png" width="40" height="46" />](https://mirai.r-lib.org/articles/v03-serialization.html)
  Seamless use of torch tensors, models and optimizers across parallel
processes.

[<img alt="Arrow" src="https://arrow.apache.org/img/arrow-logo_hex_black-txt_white-bg.png" width="40" height="46" />](https://mirai.r-lib.org/articles/v03-serialization.html)
  Query databases over ADBC connections natively in the Arrow data
format.

[<img alt="Polars" src="https://github.com/pola-rs/polars-static/raw/master/logos/polars_logo_blue.svg" width="40" height="46" />](https://mirai.r-lib.org/articles/v03-serialization.html)
  R Polars leverages mirai’s serialization registration mechanism for
transparent use of Polars objects.

[<img alt="targets" src="https://github.com/ropensci/targets/raw/main/man/figures/logo.png" width="40" height="46" />](https://docs.ropensci.org/targets/)
  Targets uses crew as its default high-performance computing backend.
Crew is a distributed worker launcher extending mirai to different
computing platforms.

### Acknowledgements

[Will Landau](https://github.com/wlandau/) for being instrumental in
shaping development of the package, from initiating the original request
for persistent daemons, through to orchestrating robustness testing for
the high performance computing requirements of crew and targets.

[Joe Cheng](https://github.com/jcheng5/) for integrating the ‘promises’
method to work seamlessly within Shiny, and prototyping event-driven
promises.

[Luke Tierney](https://github.com/ltierney/) of R Core, for discussion
on L’Ecuyer-CMRG streams to ensure statistical independence in parallel
processing, and reviewing mirai’s implementation as the first
‘alternative communications backend for R’.

[Travers Ching](https://github.com/traversc) for a novel idea in
extending the original custom serialization support in the package.

[Hadley Wickham](https://github.com/hadley), [Henrik
Bengtsson](https://github.com/HenrikBengtsson/), [Daniel
Falbel](https://github.com/dfalbel/), and [Kirill
Müller](https://github.com/krlmlr/) for many deep insights and
discussions.

### Links

[mirai](https://mirai.r-lib.org/) •
[nanonext](https://nanonext.r-lib.org/) • [CRAN HPC Task
View](https://cran.r-project.org/view=HighPerformanceComputing)

–

Please note that this project is released with a [Contributor Code of
Conduct](https://mirai.r-lib.org/CODE_OF_CONDUCT.html). By participating
in this project you agree to abide by its terms.
