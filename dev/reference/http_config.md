# HTTP Remote Launch Configuration

Generates a remote configuration for launching daemons via HTTP API. By
default, automatically configures for Posit Workbench using environment
variables.

## Usage

``` r
http_config(
  url = posit_workbench_url,
  method = "POST",
  cookie = posit_workbench_cookie,
  token = NULL,
  data = posit_workbench_data,
  ...
)
```

## Arguments

- url:

  (character or function) URL endpoint for the launch API. May be a
  function returning the URL value.

- method:

  (character) HTTP method, typically `"POST"`.

- cookie:

  (character or function) session cookie value. May be a function
  returning the cookie value. Set to `NULL` if not required for
  authentication.

- token:

  (character or function) authentication bearer token. May be a function
  returning the token value. Set to `NULL` if not required for
  authentication.

- data:

  (character or function) JSON or formatted request body containing the
  daemon launch command. May be a function returning the data value.
  Should include a placeholder `"%s"` where the
  [`mirai::daemon()`](https://mirai.r-lib.org/dev/reference/daemon.md)
  call will be inserted at launch time.

- ...:

  additional arguments passed to `data` when it is a function. See the
  Posit Workbench Options section for those accepted by the default
  value of `data`.

## Value

A list in the required format to be supplied to the `remote` argument of
[`daemons()`](https://mirai.r-lib.org/dev/reference/daemons.md) or
[`launch_remote()`](https://mirai.r-lib.org/dev/reference/launch_local.md).

## Posit Workbench Options

When using the default value of `data`, the following arguments may be
supplied via `...` to customise the launched job:

- `rscript` (character) Rscript executable path. Default `"Rscript"`.

- `job_name` (character) base name for launched jobs. Default
  `"mirai_daemon"`.

- `cluster` (character) name of the cluster to use. Default uses the
  first available cluster.

- `resource_profile` (character) named resource profile (e.g.
  `"rstudio"`). Default uses the first profile available on the chosen
  cluster.

- `cpus` (integer) number of CPUs for custom resource allocation.
  Specify together with or instead of `memory` to override
  `resource_profile`.

- `memory` (integer) memory in MB for custom resource allocation.
  Specify together with or instead of `cpus` to override
  `resource_profile`.

## See also

[`ssh_config()`](https://mirai.r-lib.org/dev/reference/ssh_config.md),
[`cluster_config()`](https://mirai.r-lib.org/dev/reference/cluster_config.md)
and
[`remote_config()`](https://mirai.r-lib.org/dev/reference/remote_config.md)
for other types of remote configuration.

## Examples

``` r
tryCatch(http_config(), error = identity)
#> $type
#> [1] "http"
#> 
#> $url
#> function () 
#> {
#>     file.path(Sys.getenv("RS_SERVER_ADDRESS"), "api", "launch_job")
#> }
#> <bytecode: 0x5584ff81d5c0>
#> <environment: namespace:mirai>
#> 
#> $method
#> [1] "POST"
#> 
#> $cookie
#> function () 
#> {
#>     is.null(.[["pwb_cookie"]]) || return(.[["pwb_cookie"]])
#>     Sys.getenv("RS_SESSION_RPC_COOKIE")
#> }
#> <bytecode: 0x5584ff81cd00>
#> <environment: namespace:mirai>
#> 
#> $token
#> NULL
#> 
#> $data
#> function (rscript = "Rscript", job_name = "mirai_daemon", cluster = NULL, 
#>     resource_profile = NULL, cpus = NULL, memory = NULL) 
#> {
#>     requireNamespace("secretbase", quietly = TRUE) || stop(._[["secretbase"]])
#>     url <- Sys.getenv("RS_SERVER_ADDRESS")
#>     cookie <- Sys.getenv("RS_SESSION_RPC_COOKIE")
#>     nzchar(url) && nzchar(cookie) || stop(._[["posit_api"]])
#>     envs <- ncurl(file.path(url, "api", "get_compute_envs"), 
#>         headers = c(Cookie = cookie, `X-RS-Session-Server-RPC-Cookie` = cookie), 
#>         timeout = .limit_short)
#>     if (envs[["status"]] != 200L) {
#>         envs <- posit_workbench_fetch("api/get_compute_envs")
#>         envs[["status"]] == 200L || stop(._[["posit_api"]])
#>         .$pwb_cookie <- envs[["cookie"]]
#>     }
#>     clusters <- secretbase::jsondec(envs[["data"]])[["result"]][["clusters"]]
#>     if (is.null(cluster)) {
#>         cluster_obj <- clusters[[1L]]
#>     }
#>     else {
#>         cluster_names <- vapply(clusters, `[[`, character(1L), 
#>             "name")
#>         cluster %in% cluster_names || stop(sprintf("cluster '%s' not found. Available: %s", 
#>             cluster, paste(cluster_names, collapse = ", ")))
#>         cluster_obj <- clusters[[which(cluster_names == cluster)]]
#>     }
#>     lp <- sprintf(".libPaths(c(%s))", paste(sprintf("\"%s\"", 
#>         .libPaths()), collapse = ","))
#>     job <- list(cluster = cluster_obj[["name"]], container = list(image = cluster_obj[["defaultImage"]]), 
#>         name = job_name, exe = rscript, args = c("-e", sprintf("{%s;%%s}", 
#>             lp)))
#>     if (!is.null(resource_profile)) {
#>         profiles <- cluster_obj[["resourceProfiles"]]
#>         profile_names <- vapply(profiles, `[[`, character(1L), 
#>             "name")
#>         resource_profile %in% profile_names || stop(sprintf("resource profile '%s' not found. Available: %s", 
#>             resource_profile, paste(profile_names, collapse = ", ")))
#>         job[["resourceProfile"]] <- resource_profile
#>     }
#>     else if (!is.null(cpus) || !is.null(memory)) {
#>         if (is.null(cpus)) {
#>             cpus <- 1L
#>         }
#>         if (is.null(memory)) {
#>             memory <- 512L
#>         }
#>         job[["resources"]] <- list(cpus = cpus, memory = memory)
#>     }
#>     else {
#>         job[["resourceProfile"]] <- cluster_obj[["resourceProfiles"]][[1L]][["name"]]
#>     }
#>     secretbase::jsonenc(list(method = "launch_job", kwparams = list(job = job)))
#> }
#> <bytecode: 0x5584ff81fef0>
#> <environment: namespace:mirai>
#> 
#> $dots
#> list()
#> 

# Custom HTTP configuration example:
http_config(
  url = "https://api.example.com/launch",
  method = "POST",
  cookie = function() Sys.getenv("MY_SESSION_COOKIE"),
  token = function() Sys.getenv("MY_API_KEY"),
  data = '{"command": "%s"}'
)
#> $type
#> [1] "http"
#> 
#> $url
#> [1] "https://api.example.com/launch"
#> 
#> $method
#> [1] "POST"
#> 
#> $cookie
#> function () 
#> Sys.getenv("MY_SESSION_COOKIE")
#> <environment: 0x5584ff80ede0>
#> 
#> $token
#> function () 
#> Sys.getenv("MY_API_KEY")
#> <environment: 0x5584ff80ede0>
#> 
#> $data
#> [1] "{\"command\": \"%s\"}"
#> 
#> $dots
#> list()
#> 

if (FALSE) { # \dontrun{
# Launch 2 daemons using http config default (for Posit Workbench):
daemons(n = 2, url = host_url(), remote = http_config())

# Customise the default Posit Workbench launch (named cluster and profile):
daemons(
  n = 2,
  url = host_url(),
  remote = http_config(cluster = "Kubernetes", resource_profile = "rstudio")
)

# Or specify custom resources (4 CPUs, 8 GB memory):
daemons(
  n = 2,
  url = host_url(),
  remote = http_config(cluster = "Kubernetes", cpus = 4, memory = 8192)
)
} # }
```
