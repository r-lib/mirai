
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
for R <br /><br /> Designed for simplicity, a ‘mirai’ evaluates an R
expression asynchronously in a parallel process, locally or distributed
over the network. The result is automatically available upon completion.

Modern networking and concurrency, built on
[nanonext](https://github.com/r-lib/nanonext/) and
[NNG](https://nng.nanomsg.org/) (Nanomsg Next Gen), ensures reliable and
efficient scheduling over fast inter-process communications or TCP/IP
secured by TLS. Distributed computing can launch remote resources via
SSH or cluster managers.

An inherently queued architecture handles many more tasks than available
processes, and requires no storage on the file system. Innovative
features include support for otherwise non-exportable reference objects,
event-driven promises, and asynchronous parallel map. <br /><br />

### Quick Start

Use `mirai()` to evaluate an expression asynchronously in a separate,
clean R process.

The following mimics an expensive calculation that eventually returns a
vector of random values.

``` r
library(mirai)

m <- mirai({Sys.sleep(n); rnorm(n, mean)}, n = 5L, mean = 7)
```

> The mirai expression is evaluated in another process and hence must be
> self-contained, not referring to variables that do not already exist
> there. Above, the variables `n` and `mean` are passed as part of the
> `mirai()` call.

A ‘mirai’ object is returned immediately - creating a mirai never blocks
the session.

``` r
m
#> < mirai [] >
```

Whilst the async operation is ongoing, attempting to access a mirai’s
data yields an ‘unresolved’ logical NA.

``` r
m$data
#> 'unresolved' logi NA
```

To check whether a mirai remains unresolved (yet to complete):

``` r
unresolved(m)
#> [1] TRUE
```

To wait for and collect the return value, use the mirai’s `[]` method:

``` r
m[]
#> [1] 5.974919 7.819678 6.149700 7.227810 7.350235
```

As a mirai represents an async operation, it is never necessary to wait
for it. Once it completes, the return value is automatically available
at `$data`.

``` r
while (unresolved(m)) {
  # do work here that does not depend on `m`
}
m$data
#> [1] 5.974919 7.819678 6.149700 7.227810 7.350235
```

#### Daemons

📡️️
[Daemons](https://mirai.r-lib.org/articles/v1-daemons.html#local-daemons)
are persistent background processes for receiving mirai requests, and
are created as easily as:

``` r
daemons(6)
#> [1] 6
```

🌐️️ Daemons may also be deployed
[remotely](https://mirai.r-lib.org/articles/v1-daemons.html#remote-daemons)
for distributed computing over the network.

🛰️️
[Launchers](https://mirai.r-lib.org/articles/v1-daemons.html#launching-remote-daemons)
can start daemons via (tunnelled) SSH or a cluster resource manager.

🔐 [Secure TLS
connections](https://mirai.r-lib.org/articles/v1-daemons.html#tls-secure-connections)
can be used for remote daemon connections, with zero configuration
required.

#### Async Parallel Map

`mirai_map()` maps a function over a list or vector, with each element
processed in a separate parallel process. It also performs multiple map
over the rows of a dataframe or matrix.

``` r
df <- data.frame(
  fruit = c("melon", "grapes", "coconut"),
  price = c(3L, 5L, 2L)
)
m <- mirai_map(df, \(...) sprintf("%s: $%d", ...))
```

A ‘mirai_map’ object is returned immediately, and is always
non-blocking.

Its value may be retrieved at any time using its `[]` method to return a
list, just like `purrr::map()`. The `[]` method also provides options
for flatmap, early stopping and/or progress indicators.

``` r
m
#> < mirai map [3/3] >
m[.flat]
#> [1] "melon: $3"   "grapes: $5"  "coconut: $2"
```

> All errors are returned as ‘errorValues’, facilitating recovery from
> partial failure. There are further
> [advantages](https://mirai.r-lib.org/articles/v2-map.html) over
> alternative map implementations.

### Design Concepts

mirai is designed from the ground up to provide a production-grade
experience.

- 🚀 Fast
  - 1,000x more responsive vs. common alternatives
    [<sup>\[1\]</sup>](https://github.com/r-lib/mirai/pull/142#issuecomment-2457589563)
  - Built for low-latency applications: real time inference & Shiny apps
- ✨ Reliable
  - No reliance on global options or variables -\> consistent behaviour
  - Explicit evaluation -\> transparent and predictable results
- 📈 Scalable
  - Launch millions of tasks over thousands of connections
  - Proven track record for heavy-duty workloads in the life sciences
    industry

[<img alt="Joe Cheng on mirai with Shiny" src="https://img.youtube.com/vi/GhX0PcEm3CY/hqdefault.jpg" width = "300" height="225" />](https://youtu.be/GhX0PcEm3CY?t=1740)
 
[<img alt="Will Landau on mirai in clinical trials" src="https://img.youtube.com/vi/cyF2dzloVLo/hqdefault.jpg" width = "300" height="225" />](https://youtu.be/cyF2dzloVLo?t=5127)

> *mirai パッケージを試してみたところ、かなり速くて驚きました*

### Powering the Ecosystem

mirai features the following core integrations, with usage examples in
the linked vignettes:

[<img alt="R parallel" src="https://www.r-project.org/logo/Rlogo.png" width="40" height="31" />](https://mirai.r-lib.org/articles/v5-parallel.html)
  Provides the first official alternative communications backend for R,
implementing a new parallel cluster type, a feature request by R-Core at
R Project Sprint 2023.

[<img alt="purrr" src="https://purrr.tidyverse.org/logo.png" width="40" height="46" />](https://purrr.tidyverse.org)
  Powers the (in development) implementation of parallel map for the
purrr functional programming toolkit, one of the core tidyverse
packages.

[<img alt="promises" src="https://solutions.posit.co/images/brand/posit-icon-fullcolor.svg" width="40" height="36" />](https://mirai.r-lib.org/articles/v3-promises.html)
  Implements the next generation of completely event-driven promises.
‘mirai’ and ‘mirai_map’ objects may be used interchangeably with
‘promises’, including with the promise pipe `%...>%`.

[<img alt="Shiny" src="https://github.com/rstudio/shiny/raw/main/man/figures/logo.png" width="40" height="46" />](https://mirai.r-lib.org/articles/v3-promises.html)
  Asynchronous parallel / distributed backend, supporting the next level
of responsiveness and scalability within Shiny, with native support for
ExtendedTask.

[<img alt="Plumber" src="https://rstudio.github.io/cheatsheets/html/images/logo-plumber.png" width="40" height="46" />](https://mirai.r-lib.org/articles/v3-promises.html)
  Asynchronous parallel / distributed backend for scaling Plumber
applications in production.

[<img alt="torch" src="https://torch.mlverse.org/css/images/hex/torch.png" width="40" height="46" />](https://mirai.r-lib.org/articles/v4-serialization.html)
  Allows Torch tensors and complex objects such as models and optimizers
to be used seamlessly across parallel processes.

[<img alt="Arrow" src="https://arrow.apache.org/img/arrow-logo_hex_black-txt_white-bg.png" width="40" height="46" />](https://mirai.r-lib.org/articles/v4-serialization.html)
  Allows queries using the Apache Arrow format to be handled seamlessly
over ADBC database connections hosted in background processes.

[<img alt="targets" src="https://github.com/ropensci/targets/raw/main/man/figures/logo.png" width="40" height="46" />](https://docs.ropensci.org/targets/)
  Targets, a make-like pipeline tool, has adopted crew as its default
high-performance computing backend. Crew is a distributed
worker-launcher extending mirai to different distributed computing
platforms, from traditional clusters including LFS, PBS/TORQUE, SGE and
Slurm to cloud services such as AWS Batch.

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

[Henrik Bengtsson](https://github.com/HenrikBengtsson/) for valuable
insights leading to the interface accepting broader usage patterns.

[Daniel Falbel](https://github.com/dfalbel/) for discussion around an
efficient solution to serialization and transmission of torch tensors.

[Kirill Müller](https://github.com/krlmlr/) for discussion on using
parallel processes to host Arrow database connections.

[<img alt="R Consortium" src="https://r-consortium.org/images/RConsortium_Horizontal_Pantone.webp" width="100" height="22" />](https://r-consortium.org/) 
for funding work on the TLS implementation in nanonext, used to provide
secure connections in mirai.

### Installation

Install the latest release from CRAN:

``` r
install.packages("mirai")
```

The current development version is available from R-universe:

``` r
install.packages("mirai", repos = "https://r-lib.r-universe.dev")
```

### Links & References

◈ mirai R package: <https://mirai.r-lib.org/> <br /> ◈ nanonext R
package: <https://nanonext.r-lib.org/>

mirai is listed in CRAN High Performance Computing Task View: <br />
<https://cran.r-project.org/view=HighPerformanceComputing>

–

Please note that this project is released with a [Contributor Code of
Conduct](https://mirai.r-lib.org/CODE_OF_CONDUCT.html). By participating
in this project you agree to abide by its terms.
