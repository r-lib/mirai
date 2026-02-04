# mirai

### ミライ

*moving already*  
  
[![Ask
DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/r-lib/mirai)  
  
Minimalist Async Evaluation Framework for R  
  

→ Run R code in parallel while keeping your session free

→ Scale seamlessly from your laptop to cloud servers or HPC clusters

→ Automate actions as soon as tasks complete

  

### Installation

``` r
install.packages("mirai")
```

### Quick Start

[`mirai()`](https://mirai.r-lib.org/dev/reference/mirai.md) evaluates an
R expression asynchronously in a parallel process.

[`daemons()`](https://mirai.r-lib.org/dev/reference/daemons.md) sets up
*daemons*: persistent background processes that receive and execute
tasks.

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

### Architecture

[`mirai()`](https://mirai.r-lib.org/dev/reference/mirai.md) sends tasks
to daemons for parallel execution.

A *compute profile* is a pool of connected daemons. Multiple profiles
can coexist, directing tasks to different resources.

*Hub architecture*: host listens at a URL, daemons connect to it — add
or remove daemons at any time. Launch locally or remotely via different
methods, and mix freely:

``` R
                            ┌ Compute Profile ┐
  launch_local() ···········│▸ Daemon ──┐     │
                            │           │     │
  ssh_config() ·············│▸ Daemon ──┼─────┼──▸ Host
                            │           │     │    daemons(url = host_url())
  cluster_config() ·········│▸ Daemon ──┤     │
                            │           │     │
  http_config() ············│▸ Daemon ──┘     │
                            └─────────────────┘
                            ┌ Compute Profile ┐
                            │  Daemon ──┐     │
                            │           ├─────┼──▸ Host
                            │  Daemon ──┘     │    daemons(2)
                            └─────────────────┘
```

### Design Philosophy

**⚡ Dynamic Architecture** — scale on demand

- Hub architecture — host listens, daemons connect — enables true
  dynamic scaling
- Optimal load balancing through efficient FIFO dispatcher scheduling
- Event-driven promises complete with zero latency (and no polling
  overhead)

**⚙️ Modern Foundation** — built for speed

- Built on [NNG](https://nng.nanomsg.org/) via
  [nanonext](https://nanonext.r-lib.org/), scales reliably to millions
  of tasks / thousands of processes
- High performance, with round-trip times measured in microseconds, not
  milliseconds
- Native support for IPC, TCP, and zero-config TLS with automatic
  certificate generation

**🏭 Production First** — reliable by design

- Clear evaluation model with explicit dependencies prevents surprises
  from hidden state
- Serialization support for cross-language data formats (torch tensors,
  Arrow tables)
- OpenTelemetry integration for observability across distributed
  processes

**🌐 Deploy Everywhere** — laptop to cluster

- Local, network / cloud (via SSH, SSH tunnelling) or HPC (via Slurm,
  SGE, PBS, LSF)
- Modular compute profiles direct tasks to the most suitable resources
- Combine local, remote, and HPC resources in a single compute profile

### Powers the R Ecosystem

mirai serves as a foundation for asynchronous, parallel and distributed
computing in the R ecosystem.

[![R
parallel](https://www.r-project.org/logo/Rlogo.png)](https://mirai.r-lib.org/articles/v04-parallel.html)
  The first official alternative communications backend for R, the
‘MIRAI’ parallel cluster, a feature request by R-Core.

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
  R Polars leverages mirai’s serialization registration mechanism for
transparent use of Polars objects.

[![targets](https://github.com/ropensci/targets/raw/main/man/figures/logo.png)](https://docs.ropensci.org/targets/)
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

- [mirai](https://mirai.r-lib.org/)
- [nanonext](https://nanonext.r-lib.org/)
- [CRAN HPC Task
  View](https://cran.r-project.org/view=HighPerformanceComputing)

–

Please note that this project is released with a [Contributor Code of
Conduct](https://mirai.r-lib.org/CODE_OF_CONDUCT.html). By participating
in this project you agree to abide by its terms.
