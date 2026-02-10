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
  data = posit_workbench_data
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

## Value

A list in the required format to be supplied to the `remote` argument of
[`daemons()`](https://mirai.r-lib.org/dev/reference/daemons.md) or
[`launch_remote()`](https://mirai.r-lib.org/dev/reference/launch_local.md).

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
#> posit_workbench_get("url")
#> <bytecode: 0x55eafc1e3a88>
#> <environment: namespace:mirai>
#> 
#> $method
#> [1] "POST"
#> 
#> $cookie
#> function () 
#> posit_workbench_get("cookie")
#> <bytecode: 0x55eafc1e33c0>
#> <environment: namespace:mirai>
#> 
#> $token
#> NULL
#> 
#> $data
#> function (rscript = "Rscript") 
#> posit_workbench_get("data", rscript)
#> <bytecode: 0x55eafc1e2c88>
#> <environment: namespace:mirai>
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
#> <environment: 0x55eafc1d5158>
#> 
#> $token
#> function () 
#> Sys.getenv("MY_API_KEY")
#> <environment: 0x55eafc1d5158>
#> 
#> $data
#> [1] "{\"command\": \"%s\"}"
#> 

if (FALSE) { # \dontrun{
# Launch 2 daemons using http config default (for Posit Workbench):
daemons(n = 2, url = host_url(), remote = http_config())
} # }
```
