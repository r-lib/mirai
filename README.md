
<!-- README.md is generated from README.Rmd. Please edit that file -->

# mirai <a href="https://shikokuchuo.net/mirai/" alt="mirai"><img src="man/figures/logo.png" alt="mirai logo" align="right" width="120"/></a>

<!-- badges: start -->

[![CRAN
status](https://www.r-pkg.org/badges/version/mirai?color=112d4e)](https://CRAN.R-project.org/package=mirai)
[![mirai status
badge](https://shikokuchuo.r-universe.dev/badges/mirai?color=ddcacc)](https://shikokuchuo.r-universe.dev)
[![R-CMD-check](https://github.com/shikokuchuo/mirai/workflows/R-CMD-check/badge.svg)](https://github.com/shikokuchuo/mirai/actions)
<!-- badges: end -->

Minimalist async evaluation framework for R.

未来 みらい mirai is Japanese for ‘future’.

Extremely simple and lightweight method for concurrent / parallel code
execution, built on ‘nanonext’ and ‘NNG’ (Nanomsg Next Gen) technology.

\~\~

Whilst frameworks for parallelisation exist for R, {mirai} is designed
for simplicity.

Use:

-   `mirai()` to create a ‘mirai’ object.

A ‘mirai’ evaluates an arbitrary expression asynchronously.

Initially returns a logical NA value, resolving automatically upon
completion.

\~\~

Demonstrates the capability of {nanonext} in providing a lightweight and
robust cross-platform concurrency framework.

{mirai} has a tiny pure R code base, relying on a single package -
{nanonext}. {nanonext} itself is a lightweight wrapper for the NNG C
library with zero package dependencies.

### Installation

Install the latest release from CRAN:

``` r
install.packages("mirai")
```

or the development version from rOpenSci R-universe:

``` r
options(repos = c(shikokuchuo = 'https://shikokuchuo.r-universe.dev', CRAN = 'https://cloud.r-project.org'))
install.packages("mirai")
```

### Demonstration

Use cases:

-   minimise execution times by performing long-running tasks
    concurrently in separate processes
-   ensure execution flow of the main process is not blocked

``` r
library(mirai)
```

#### Example 1: Compute-intensive Operations

Multiple long computes (model fits etc.) would take more time than if
performed concurrently on available computing cores.

Use `mirai()` to evaluate an expression in a separate R process
asynchronously.

-   All named objects are passed through to a clean environment

A ‘mirai’ object is returned immediately.

``` r
m <- mirai({
  res <- rnorm(n) + m
  res / rev(res)
}, n = 1e8, m = runif(1))
m
#> < mirai >
#>  - $data for evaluated result
m$data
#> 'unresolved' logi NA
```

The ‘mirai’ yields an ‘unresolved’ logical NA value whilst the async
operation is still ongoing.

``` r
# continue running code concurrently...
```

Upon completion, the ‘mirai’ automatically resolves to the evaluated
result.

``` r
m$data |> str()
#> num [1:100000000] 2.263 -2.907 0.365 0.522 -0.229 ...
```

Alternatively, explicitly call and wait for the result (blocking) using
`call_mirai()`.

``` r
call_mirai(m)$data |> str()
#> num [1:100000000] 2.263 -2.907 0.365 0.522 -0.229 ...
```

#### Example 2: I/O-bound Operations

Processing high-frequency real-time data, writing results to
file/database can be slow and potentially disrupt the execution flow.

Cache data in memory and use `mirai()` to perform periodic write
operations in a separate process.

A ‘mirai’ object is returned immediately.

``` r
m <- mirai(write.csv(x, file = file), x = rnorm(1e8), file = tempfile())
```

Auxiliary function `unresolved()` may be used in control flow statements
to perform actions which depend on resolution of the ‘mirai’, both
before and after. This means there is no need to actually wait (block)
for a ‘mirai’ to resolve, as the example below demonstrates.

``` r
# unresolved() queries for resolution itself so no need to use it again within the while loop

while (unresolved(m)) {
  # do stuff before checking resolution again
  cat("while unresolved\n")
}
#> while unresolved
#> while unresolved

# perform actions which depend on the 'mirai' value outside the while loop
m$data
#> NULL
```

Here the resolved value is `NULL`, the expected return value for
`write.csv()`. Now actions which depend on this confirmation may be
processed, for example the next write.

### Links

{mirai} website: <https://shikokuchuo.net/mirai/><br /> {mirai} on CRAN:
<https://cran.r-project.org/package=mirai>

{nanonext} website: <https://shikokuchuo.net/nanonext/><br /> {nanonext}
on CRAN: <https://cran.r-project.org/package=nanonext>

NNG website: <https://nng.nanomsg.org/><br /> NNG documentation:
<https://nng.nanomsg.org/man/tip/><br />
