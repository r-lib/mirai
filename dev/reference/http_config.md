# HTTP Remote Launch Configuration

Generates a remote configuration for launching daemons via HTTP API. By
default, automatically configures for Posit Workbench using environment
variables.

## Usage

``` r
http_config(
  url = posit_workbench_url,
  method = "POST",
  headers = posit_workbench_headers,
  data = posit_workbench_data,
  ...,
  cookie = NULL,
  token = NULL
)
```

## Arguments

- url:

  (character or function) URL endpoint for the launch API. May be a
  function returning the URL value.

- method:

  (character) HTTP method, typically `"POST"`.

- headers:

  (named character vector or function) HTTP headers sent with the
  request, supplying any required authentication (e.g. session cookie,
  bearer token, API key) as well as other API metadata. May be a
  function returning a named character vector.

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

- cookie:

  (character or function) convenience argument that, if non-NULL,
  appends a `Cookie: <value>` entry to `headers`. May be a function
  returning the cookie value.

- token:

  (character or function) convenience argument that, if non-NULL,
  appends an `Authorization: Bearer <value>` entry to `headers`. May be
  a function returning the token value.

## Value

A list in the required format to be supplied to the `remote` argument of
[`daemons()`](https://mirai.r-lib.org/dev/reference/daemons.md) or
[`launch_remote()`](https://mirai.r-lib.org/dev/reference/launch_local.md).

## Details

Arguments accepting either a value or a function (`url`, `headers`,
`data`, `cookie`, `token`) may be supplied as a function to defer
evaluation until the time of launch. This is the recommended way to
supply credentials, so that they are fetched lazily when needed rather
than captured when the configuration is created.

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
#> pwb_url()
#> <bytecode: 0x55c9e21c5eb8>
#> <environment: namespace:mirai>
#> 
#> $method
#> [1] "POST"
#> 
#> $headers
#> function () 
#> pwb_headers()
#> <bytecode: 0x55c9e21c57b8>
#> <environment: namespace:mirai>
#> 
#> $data
#> function (...) 
#> pwb_data(...)
#> <bytecode: 0x55c9e21c5048>
#> <environment: namespace:mirai>
#> 
#> $dots
#> list()
#> 
#> $cookie
#> NULL
#> 
#> $token
#> NULL
#> 

# Custom HTTP configuration example:
http_config(
  url = "https://api.example.com/launch",
  method = "POST",
  headers = function() c(
    Authorization = sprintf("Bearer %s", Sys.getenv("MY_API_KEY")),
    `X-API-Version` = "2"
  ),
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
#> $headers
#> function () 
#> c(Authorization = sprintf("Bearer %s", Sys.getenv("MY_API_KEY")), 
#>     `X-API-Version` = "2")
#> <environment: 0x55c9e21b7ac8>
#> 
#> $data
#> [1] "{\"command\": \"%s\"}"
#> 
#> $dots
#> list()
#> 
#> $cookie
#> NULL
#> 
#> $token
#> NULL
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
