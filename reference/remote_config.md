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

  (character) shell command for launching daemons (e.g. `"ssh"`). `NULL`
  returns shell commands for manual deployment without launching.

- args:

  (character vector) arguments to `command`, must include `"."` as
  placeholder for the daemon launch command. May be a list of vectors
  for multiple launches.

- rscript:

  (character) Rscript executable. Use full path if needed, or
  `"Rscript.exe"` on Windows.

- quote:

  (logical) whether to quote the daemon launch command. Required for
  `"sbatch"` and `"ssh"`, not for `"srun"`.

## Value

A list in the required format to be supplied to the `remote` argument of
[`daemons()`](https://mirai.r-lib.org/reference/daemons.md) or
[`launch_remote()`](https://mirai.r-lib.org/reference/launch_local.md).

## See also

[`ssh_config()`](https://mirai.r-lib.org/reference/ssh_config.md),
[`cluster_config()`](https://mirai.r-lib.org/reference/cluster_config.md)
and [`http_config()`](https://mirai.r-lib.org/reference/http_config.md)
for other types of remote configuration.

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
