# SSH Remote Launch Configuration

Generates a remote configuration for launching daemons over SSH, with
the option of SSH tunnelling.

## Usage

``` r
ssh_config(
  remotes,
  tunnel = FALSE,
  timeout = 10,
  command = "ssh",
  rscript = "Rscript"
)
```

## Arguments

- remotes:

  (character) URL(s) to SSH into using scheme 'ssh://', e.g.
  'ssh://10.75.32.90:22' or 'ssh://nodename'. Port defaults to 22.

- tunnel:

  (logical) whether to use SSH tunnelling. Requires `url` hostname
  '127.0.0.1' (use
  [`local_url()`](https://mirai.r-lib.org/reference/host_url.md) with
  `tcp = TRUE`). See SSH Tunnelling section.

- timeout:

  (integer) maximum seconds for connection setup.

- command:

  (character) shell command for launching daemons (e.g. `"ssh"`). `NULL`
  returns shell commands for manual deployment without launching.

- rscript:

  (character) Rscript executable. Use full path if needed, or
  `"Rscript.exe"` on Windows.

## Value

A list in the required format to be supplied to the `remote` argument of
[`daemons()`](https://mirai.r-lib.org/reference/daemons.md) or
[`launch_remote()`](https://mirai.r-lib.org/reference/launch_local.md).

## SSH Direct Connections

The simplest use of SSH is to execute the daemon launch command on a
remote machine, for it to dial back to the host / dispatcher URL.

SSH key-based authentication must already be in place. The relevant port
on the host must be open to inbound connections from the remote machine.
This approach is suited to trusted networks.

## SSH Tunnelling

SSH tunnelling launches remote daemons without requiring the remote
machine to access the host directly. Often firewall configurations or
security policies may prevent opening a port to accept outside
connections.

A tunnel is created once the initial SSH connection is made. For
simplicity, this SSH tunnelling implementation uses the same port on
both host and daemon. SSH key-based authentication must already be in
place, but no other configuration is required.

To use tunnelling, set the hostname of the
[`daemons()`](https://mirai.r-lib.org/reference/daemons.md) `url`
argument to be '127.0.0.1'. Using
[`local_url()`](https://mirai.r-lib.org/reference/host_url.md) with
`tcp = TRUE` also does this for you. Specifying a specific port to use
is optional, with a random ephemeral port assigned otherwise. For
example, specifying 'tcp://127.0.0.1:5555' uses the local port '5555' to
create the tunnel on each machine. The host listens to '127.0.0.1:5555'
on its machine and the remotes each dial into '127.0.0.1:5555' on their
own respective machines.

Daemons can be launched on any machine accessible via SSH, whether on
the local network or in the cloud.

## See also

[`cluster_config()`](https://mirai.r-lib.org/reference/cluster_config.md),
[`http_config()`](https://mirai.r-lib.org/reference/http_config.md) and
[`remote_config()`](https://mirai.r-lib.org/reference/remote_config.md)
for other types of remote configuration.

## Examples

``` r
# direct SSH example
ssh_config(c("ssh://10.75.32.90:222", "ssh://nodename"), timeout = 5)
#> $command
#> [1] "ssh"
#> 
#> $args
#> $args[[1]]
#> [1] "-o ConnectTimeout=5 -fTp 222" "10.75.32.90"                 
#> [3] "."                           
#> 
#> $args[[2]]
#> [1] "-o ConnectTimeout=5 -fTp 22" "nodename"                   
#> [3] "."                          
#> 
#> 
#> $rscript
#> [1] "Rscript"
#> 
#> $quote
#> [1] TRUE
#> 
#> $tunnel
#> [1] FALSE
#> 

# SSH tunnelling example
ssh_config(c("ssh://10.75.32.90:222", "ssh://nodename"), tunnel = TRUE)
#> $command
#> [1] "ssh"
#> 
#> $args
#> $args[[1]]
#> [1] "-o ConnectTimeout=10 -fTp 222" "10.75.32.90"                  
#> [3] "."                            
#> 
#> $args[[2]]
#> [1] "-o ConnectTimeout=10 -fTp 22" "nodename"                    
#> [3] "."                           
#> 
#> 
#> $rscript
#> [1] "Rscript"
#> 
#> $quote
#> [1] TRUE
#> 
#> $tunnel
#> [1] TRUE
#> 

if (FALSE) { # \dontrun{

# launch daemons on the remote machines 10.75.32.90 and 10.75.32.91 using
# SSH, connecting back directly to the host URL over a TLS connection:
daemons(
  n = 1,
  url = host_url(tls = TRUE),
  remote = ssh_config(c("ssh://10.75.32.90:222", "ssh://10.75.32.91:222"))
)

# launch 2 daemons on the remote machine 10.75.32.90 using SSH tunnelling:
daemons(
  n = 2,
  url = local_url(tcp = TRUE),
  remote = ssh_config("ssh://10.75.32.90", tunnel = TRUE)
)
} # }
```
