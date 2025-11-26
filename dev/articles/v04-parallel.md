# mirai - Communications Backend for R

### 1. Mirai Parallel Clusters

mirai provides an alternative communications backend for R, developed to
fulfill an R Core request at R Project Sprint 2023.

‘miraiCluster’ is an official cluster type in R 4.5, created via
`parallel::makeCluster(type = "MIRAI")`. This calls
[`make_cluster()`](https://mirai.r-lib.org/dev/reference/make_cluster.md),
which can also create ‘miraiCluster’ directly.

- Specify ‘n’ to launch local nodes
- Specify ‘url’ to receive remote node connections
- Optionally specify ‘remote’ to launch remote daemons using
  configurations from
  [`ssh_config()`](https://mirai.r-lib.org/dev/reference/ssh_config.md),
  [`cluster_config()`](https://mirai.r-lib.org/dev/reference/cluster_config.md)
  or
  [`remote_config()`](https://mirai.r-lib.org/dev/reference/remote_config.md)

Use clusters with any `parallel` package function
([`clusterApply()`](https://rdrr.io/r/parallel/clusterApply.html),
[`parLapply()`](https://rdrr.io/r/parallel/clusterApply.html),
[`parLapplyLB()`](https://rdrr.io/r/parallel/clusterApply.html), etc.):

``` r
library(parallel)
library(mirai)

cl <- makeCluster(6, type = "MIRAI")
cl
#> < miraiCluster | ID: `6` nodes: 6 active: TRUE >
parLapply(cl, iris, mean)
#> $Sepal.Length
#> [1] 5.843333
#> 
#> $Sepal.Width
#> [1] 3.057333
#> 
#> $Petal.Length
#> [1] 3.758
#> 
#> $Petal.Width
#> [1] 1.199333
#> 
#> $Species
#> [1] NA
```

Call [`status()`](https://mirai.r-lib.org/dev/reference/status.md) on a
‘miraiCluster’ to query connected nodes:

``` r
status(cl)
#> $connections
#> [1] 6
#> 
#> $daemons
#> [1] "abstract://5a335f57a7147dfa61e2a2e1"
stopCluster(cl)
```

Specifying ‘url’ without ‘remote’ prints shell commands for manual node
deployment:

``` r
cl <- make_cluster(n = 2, url = host_url())
#> Shell commands for deployment on nodes:
#> 
#> [1]
#> Rscript -e 'mirai::daemon("tcp://192.168.1.71:32813",dispatcher=FALSE,cleanup=FALSE,rs=c(10407,-2017547658,214728319,548191924,-1363682779,426938530,-1028125765))'
#> 
#> [2]
#> Rscript -e 'mirai::daemon("tcp://192.168.1.71:32813",dispatcher=FALSE,cleanup=FALSE,rs=c(10407,-1867685510,-159147708,-691588212,540247216,961983403,-147487023))'
stop_cluster(cl)
```

### 2. Foreach Support

Register ‘miraiCluster’ with
[`doParallel`](https://cran.r-project.org/package=doParallel) for use
with [`foreach`](https://cran.r-project.org/package=foreach).

Parallel `foreach()` examples:

``` r
library(doParallel)
library(foreach)

cl <- makeCluster(6, type = "MIRAI")
registerDoParallel(cl)

# normalize the rows of a matrix
m <- matrix(rnorm(9), 3, 3)
foreach(i = 1:nrow(m), .combine = rbind) %dopar%
  (m[i, ] / mean(m[i, ]))
#>                 [,1]      [,2]        [,3]
#> result.1 -46.2302113 70.803471 -21.5732593
#> result.2  -5.8061198  6.682595   2.1235251
#> result.3   0.8150484  1.465484   0.7194677

# simple parallel matrix multiply
a <- matrix(1:16, 4, 4)
b <- t(a)
foreach(b = iterators::iter(b, by='col'), .combine = cbind) %dopar%
  (a %*% b)
#>      [,1] [,2] [,3] [,4]
#> [1,]  276  304  332  360
#> [2,]  304  336  368  400
#> [3,]  332  368  404  440
#> [4,]  360  400  440  480

stopCluster(cl)
```
