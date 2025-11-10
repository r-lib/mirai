# Generic Remote Launch Configuration

Provides a flexible generic framework for generating the shell commands
to deploy daemons remotely.

## Usage

``` r
remote_config(
  command = NULL,
  args = c("", "."),
  rscript = "Rscript",
  quote = FALSE
)
```

## Arguments

- command:

  the command used to effect the daemon launch on the remote machine as
  a character string (e.g. `"ssh"`). Defaults to `"ssh"` for
  `ssh_config`, although may be substituted for the full path to a
  specific SSH application. The default NULL for `remote_config` does
  not carry out any launches, but causes
  [`launch_remote()`](https://mirai.r-lib.org/dev/reference/launch_local.md)
  to return the shell commands for manual deployment on remote machines.

- args:

  (optional) arguments passed to `command`, as a character vector that
  must include `"."` as an element, which will be substituted for the
  daemon launch command. Alternatively, a list of such character vectors
  to effect multiple launches (one for each list element).

- rscript:

  filename of the R executable. Use the full path of the Rscript
  executable on the remote machine if necessary. If launching on
  Windows, `"Rscript"` should be replaced with `"Rscript.exe"`.

- quote:

  logical value whether or not to quote the daemon launch command (not
  required for Slurm `"srun"` for example, but required for Slurm
  `"sbatch"` or `"ssh"`).

## Value

A list in the required format to be supplied to the `remote` argument of
[`daemons()`](https://mirai.r-lib.org/dev/reference/daemons.md) or
[`launch_remote()`](https://mirai.r-lib.org/dev/reference/launch_local.md).

## See also

[`ssh_config()`](https://mirai.r-lib.org/dev/reference/ssh_config.md)
for SSH launch configurations, or
[`cluster_config()`](https://mirai.r-lib.org/dev/reference/cluster_config.md)
for cluster resource manager launch configurations.

## Examples

``` r
# Slurm srun example
remote_config(
  command = "srun",
  args = c("--mem 512", "-n 1", "."),
  rscript = file.path(R.home("bin"), "Rscript")
)
#> $command
#> [1] "srun"
#> 
#> $args
#> [1] "--mem 512" "-n 1"      "."        
#> 
#> $rscript
#> [1] "/opt/R/4.5.2/lib/R/bin/Rscript"
#> 
#> $quote
#> [1] FALSE
#> 
#> $tunnel
#> [1] FALSE
#> 

# SSH requires 'quote = TRUE'
remote_config(
  command = "/usr/bin/ssh",
  args = c("-fTp 22 10.75.32.90", "."),
  quote = TRUE
)
#> $command
#> [1] "/usr/bin/ssh"
#> 
#> $args
#> [1] "-fTp 22 10.75.32.90" "."                  
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

# can be used to start local daemons with special configurations
remote_config(
  command = "Rscript",
  rscript = "--default-packages=NULL --vanilla"
)
#> $command
#> [1] "Rscript"
#> 
#> $args
#> [1] ""  "."
#> 
#> $rscript
#> [1] "--default-packages=NULL --vanilla"
#> 
#> $quote
#> [1] FALSE
#> 
#> $tunnel
#> [1] FALSE
#> 
```
