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

  the character URL or vector of URLs to SSH into, using the 'ssh://'
  scheme and including the port open for SSH connections (defaults to 22
  if not specified), e.g. 'ssh://10.75.32.90:22' or 'ssh://nodename'.

- tunnel:

  logical value, whether to use SSH tunnelling. If TRUE, requires the
  [`daemons()`](https://mirai.r-lib.org/dev/reference/daemons.md) `url`
  hostname to be '127.0.0.1'. See the 'SSH Tunnelling' section below for
  further details.

- timeout:

  maximum time in seconds allowed for connection setup.

- command:

  the command used to effect the daemon launch on the remote machine as
  a character string (e.g. `"ssh"`). Defaults to `"ssh"` for
  `ssh_config`, although may be substituted for the full path to a
  specific SSH application. The default NULL for `remote_config` does
  not carry out any launches, but causes
  [`launch_remote()`](https://mirai.r-lib.org/dev/reference/launch_local.md)
  to return the shell commands for manual deployment on remote machines.

- rscript:

  filename of the R executable. Use the full path of the Rscript
  executable on the remote machine if necessary. If launching on
  Windows, `"Rscript"` should be replaced with `"Rscript.exe"`.

## Value

A list in the required format to be supplied to the `remote` argument of
[`daemons()`](https://mirai.r-lib.org/dev/reference/daemons.md) or
[`launch_remote()`](https://mirai.r-lib.org/dev/reference/launch_local.md).

## SSH Direct Connections

The simplest use of SSH is to execute the daemon launch command on a
remote machine, for it to dial back to the host / dispatcher URL.

It is assumed that SSH key-based authentication is already in place. The
relevant port on the host must also be open to inbound connections from
the remote machine, and is hence suitable for use within trusted
networks.

## SSH Tunnelling

Use of SSH tunnelling provides a convenient way to launch remote daemons
without requiring the remote machine to be able to access the host.
Often firewall configurations or security policies may prevent opening a
port to accept outside connections.

In these cases SSH tunnelling offers a solution by creating a tunnel
once the initial SSH connection is made. For simplicity, this SSH
tunnelling implementation uses the same port on both host and daemon.
SSH key-based authentication must already be in place, but no other
configuration is required.

To use tunnelling, set the hostname of the
[`daemons()`](https://mirai.r-lib.org/dev/reference/daemons.md) `url`
argument to be '127.0.0.1'. Using
[`local_url()`](https://mirai.r-lib.org/dev/reference/host_url.md) with
`tcp = TRUE` also does this for you. Specifying a specific port to use
is optional, with a random ephemeral port assigned otherwise. For
example, specifying 'tcp://127.0.0.1:5555' uses the local port '5555' to
create the tunnel on each machine. The host listens to '127.0.0.1:5555'
on its machine and the remotes each dial into '127.0.0.1:5555' on their
own respective machines.

This provides a means of launching daemons on any machine you are able
to access via SSH, be it on the local network or the cloud.

## See also

[`cluster_config()`](https://mirai.r-lib.org/dev/reference/cluster_config.md)
for cluster resource manager launch configurations, or
[`remote_config()`](https://mirai.r-lib.org/dev/reference/remote_config.md)
for generic configurations.

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
