# URL Constructors

`host_url()` constructs a valid host URL (at which daemons may connect)
based on the computer's IP address. This may be supplied directly to the
`url` argument of
[`daemons()`](https://mirai.r-lib.org/reference/daemons.md).

`local_url()` constructs a URL suitable for local daemons, or for use
with SSH tunnelling. This may be supplied directly to the `url` argument
of [`daemons()`](https://mirai.r-lib.org/reference/daemons.md).

## Usage

``` r
host_url(tls = FALSE, port = 0)

local_url(tcp = FALSE, port = 0)
```

## Arguments

- tls:

  logical value whether to use TLS. If TRUE, the scheme used will be
  'tls+tcp://'.

- port:

  numeric port to use. `0` is a wildcard value that automatically
  assigns a free ephemeral port. For `host_url`, this port should be
  open to connections from the network addresses the daemons are
  connecting from. For `local_url`, is only taken into account if
  `tcp = TRUE`.

- tcp:

  logical value whether to use a TCP connection. This must be TRUE for
  use with SSH tunnelling.

## Value

A character vector (comprising a valid URL or URLs), named for
`host_url()`.

## Details

`host_url()` will return a vector of URLs if multiple network adapters
are in use, and each will be named by the interface name (adapter
friendly name on Windows). If this entire vector is passed to the `url`
argument of functions such as
[`daemons()`](https://mirai.r-lib.org/reference/daemons.md), the first
URL is used. If no suitable IP addresses are detected, the computer's
hostname will be used as a fallback.

`local_url()` generates a random URL for the platform's default
inter-process communications transport: abstract Unix domain sockets on
Linux, Unix domain sockets on MacOS, Solaris and other POSIX platforms,
and named pipes on Windows.

## Examples

``` r
host_url()
#>                 eth0              docker0 
#> "tcp://10.1.0.105:0" "tcp://172.17.0.1:0" 
host_url(tls = TRUE)
#>                     eth0                  docker0 
#> "tls+tcp://10.1.0.105:0" "tls+tcp://172.17.0.1:0" 
host_url(tls = TRUE, port = 5555)
#>                        eth0                     docker0 
#> "tls+tcp://10.1.0.105:5555" "tls+tcp://172.17.0.1:5555" 

local_url()
#> [1] "abstract://49897acd89205a10272f1b76"
local_url(tcp = TRUE)
#> [1] "tcp://127.0.0.1:0"
local_url(tcp = TRUE, port = 5555)
#> [1] "tcp://127.0.0.1:5555"
```
