# mirai

### ミライ

*moving already*  
  
Minimalist Async Evaluation Framework for R  
  

→ Event-driven core with microsecond round-trips

→ Hub architecture — scale dynamically from laptop to HPC and cloud

→ Production-ready distributed tracing, custom serialization, and Shiny
integration

  
  
[![Ask
DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/r-lib/mirai)  

### Installation

``` r
install.packages("mirai")
```

### Quick Start

[`mirai()`](https://mirai.r-lib.org/reference/mirai.md) evaluates an R
expression asynchronously in a parallel process.

[`daemons()`](https://mirai.r-lib.org/reference/daemons.md) sets up
*daemons*: persistent background processes that receive and execute
tasks.

``` r
library(mirai)

# Set up 5 background processes
daemons(5)

# Send work -- non-blocking, returns immediately
m <- mirai({
  Sys.sleep(1)
  100 + 42
})
m
#> < mirai [] >

# Map work across daemons in parallel
mp <- mirai_map(1:9, \(x) {
  Sys.sleep(1)
  x^2
})
mp
#> < mirai map [0/9] >

# Collect results when ready
m[]
#> [1] 142
mp[.flat]
#> [1]  1  4  9 16 25 36 49 64 81

# Shut down
daemons(0)
```

See the [quick reference](https://mirai.r-lib.org/articles/mirai.html)
for a full introduction.

### Architecture

[`mirai()`](https://mirai.r-lib.org/reference/mirai.md) sends tasks to
daemons for parallel execution.

A *compute profile* is a set of connected daemons. Multiple profiles can
coexist, directing tasks to different resources.

*Hub architecture*: host listens at a URL, daemons connect to it — add
or remove daemons at any time. Launch locally or remotely via different
methods, and mix freely:

![Hub architecture diagram showing compute profiles with daemons
connecting to host](reference/figures/architecture.svg)

### Design Philosophy

> **Dynamic Architecture** — *scale on demand*
>
> - Host listens, daemons connect — true dynamic scaling
> - Optimal load balancing via efficient FIFO scheduling
> - Event-driven promises with zero-latency completion

> **Modern Foundation** — *built for speed*
>
> - NNG via nanonext — thousands of processes at scale
> - Round-trip times in microseconds, not milliseconds
> - IPC, TCP, and zero-config TLS certificates

> **Production First** — *reliable by design*
>
> - Explicit dependencies prevent hidden-state surprises
> - Cross-language serialization (torch, Arrow, Polars)
> - OpenTelemetry for distributed process observability

> **Deploy Everywhere** — *laptop to cluster*
>
> - Local, SSH, or HPC (Slurm, SGE, PBS, LSF)
> - Compute profiles direct tasks to best-fit resources
> - Mix local, remote, and HPC in a single profile

### Powers the R Ecosystem

mirai serves as a foundation for asynchronous, parallel and distributed
computing in the R ecosystem.

[![R
parallel](https://www.r-project.org/logo/Rlogo.png)](https://mirai.r-lib.org/articles/v04-parallel.html)
  The first official alternative communications backend for R, a
parallel cluster type.

[![purrr](https://purrr.tidyverse.org/logo.png)](https://purrr.tidyverse.org)
  Powers parallel map for purrr, a core tidyverse package.

[![Shiny](https://github.com/rstudio/shiny/raw/main/man/figures/logo.png)](https://mirai.r-lib.org/articles/v02-promises.html)
  Primary async backend for Shiny with full ExtendedTask support.

[![plumber2](https://github.com/posit-dev/plumber2/raw/main/man/figures/logo.svg)](https://mirai.r-lib.org/articles/v02-promises.html)
  Built-in async evaluator enabling the `@async` tag in plumber2.

[![tidymodels](https://www.tidymodels.org/images/tidymodels.png)](https://tune.tidymodels.org/)
  Core parallel processing infrastructure provider for tidymodels.

[![torch](https://torch.mlverse.org/css/images/hex/torch.png)](https://mirai.r-lib.org/articles/v03-serialization.html)
  Seamless use of torch tensors, models and optimizers across parallel
processes.

[![Arrow](https://arrow.apache.org/img/arrow-logo_hex_black-txt_white-bg.png)](https://mirai.r-lib.org/articles/v03-serialization.html)
  Query databases over ADBC connections natively in the Arrow data
format.

[![Polars](https://github.com/pola-rs/polars-static/raw/master/logos/polars_logo_blue.svg)](https://mirai.r-lib.org/articles/v03-serialization.html)
  Transparent use of Polars objects across parallel processes.

[![targets](https://github.com/ropensci/targets/raw/main/man/figures/logo.png)](https://docs.ropensci.org/targets/)
  Powers targets pipelines via crew, a distributed worker launcher built
on mirai.

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

[mirai](https://mirai.r-lib.org/) \|
[nanonext](https://nanonext.r-lib.org/) \| [CRAN HPC Task
View](https://cran.r-project.org/view=HighPerformanceComputing)

–

Please note that this project is released with a [Contributor Code of
Conduct](https://mirai.r-lib.org/CODE_OF_CONDUCT.html). By participating
in this project you agree to abide by its terms.
