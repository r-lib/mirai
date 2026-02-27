# URL Constructors

`host_url()` constructs a valid host URL (at which daemons may connect)
based on the computer's IP address. This may be supplied directly to the
`url` argument of
[`daemons()`](https://mirai.r-lib.org/dev/reference/daemons.md).

`local_url()` constructs a URL suitable for local daemons, or for use
with SSH tunnelling. This may be supplied directly to the `url` argument
of [`daemons()`](https://mirai.r-lib.org/dev/reference/daemons.md).

## Usage

``` r
host_url(tls = FALSE, port = 0)

local_url(tcp = FALSE, port = 0)
```

## Arguments

- tls:

  (logical) whether to use TLS (scheme 'tls+tcp://').

- port:

  (integer) port number. `0` assigns a free ephemeral port. For
  `host_url()`, must be open to daemon connections. For `local_url()`,
  only used when `tcp = TRUE`.

- tcp:

  (logical) whether to use TCP. Required for SSH tunnelling.

## Value

A character vector (comprising a valid URL or URLs), named for
`host_url()`.

## Details

`host_url()` will return a vector of URLs if multiple network adapters
are in use, and each will be named by the interface name (adapter
friendly name on Windows). If this entire vector is passed to the `url`
argument of functions such as
[`daemons()`](https://mirai.r-lib.org/dev/reference/daemons.md), the
first URL is used. If no suitable IP addresses are detected, the
computer's hostname will be used as a fallback.

`local_url()` generates a random URL for the platform's default
inter-process communications transport: abstract Unix domain sockets on
Linux, Unix domain sockets on MacOS, Solaris and other POSIX platforms,
and named pipes on Windows.

## Examples

``` r
host_url()
#>                 eth0              docker0 
#> "tcp://10.1.0.204:0" "tcp://172.17.0.1:0" 
host_url(tls = TRUE)
#>                     eth0                  docker0 
#> "tls+tcp://10.1.0.204:0" "tls+tcp://172.17.0.1:0" 
host_url(tls = TRUE, port = 5555)
#>                        eth0                     docker0 
#> "tls+tcp://10.1.0.204:5555" "tls+tcp://172.17.0.1:5555" 

local_url()
#> [1] "abstract://81c106b78532fd0e82cdd928"
local_url(tcp = TRUE)
#> [1] "tcp://127.0.0.1:0"
local_url(tcp = TRUE, port = 5555)
#> [1] "tcp://127.0.0.1:5555"
```
