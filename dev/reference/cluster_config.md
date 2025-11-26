# Cluster Remote Launch Configuration

Generates a remote configuration for launching daemons using an HPC
cluster resource manager such as Slurm sbatch, SGE and Torque/PBS qsub
or LSF bsub.

## Usage

``` r
cluster_config(command = "sbatch", options = "", rscript = "Rscript")
```

## Arguments

- command:

  filename of executable e.g. "sbatch" for Slurm. Replace with "qsub"
  for SGE / Torque / PBS, or "bsub" for LSF. See examples below.

- options:

  options as would be supplied inside a script file passed to `command`,
  e.g. "#SBATCH –mem=16G", each separated by a new line. See examples
  below.  
  Other shell commands e.g. to change working directory may also be
  included.  
  For certain setups, "module load R" as a final line is required, or
  for example "module load R/4.5.0" for a specific R version.  
  For the avoidance of doubt, the initial shebang line such as
  "#!/bin/bash" is not required.

- rscript:

  filename of the R executable. Use the full path of the Rscript
  executable on the remote machine if necessary. If launching on
  Windows, `"Rscript"` should be replaced with `"Rscript.exe"`.

## Value

A list in the required format to be supplied to the `remote` argument of
[`daemons()`](https://mirai.r-lib.org/dev/reference/daemons.md) or
[`launch_remote()`](https://mirai.r-lib.org/dev/reference/launch_local.md).

## See also

[`ssh_config()`](https://mirai.r-lib.org/dev/reference/ssh_config.md)
for SSH launch configurations, or
[`remote_config()`](https://mirai.r-lib.org/dev/reference/remote_config.md)
for generic configurations.

## Examples

``` r
# Slurm Config:
cluster_config(
  command = "sbatch",
  options = "#SBATCH --job-name=mirai
             #SBATCH --mem=16G
             #SBATCH --output=job.out
             module load R/4.5.0",
  rscript = file.path(R.home("bin"), "Rscript")
)
#> $command
#> [1] "/bin/sh"
#> 
#> $args
#> [1] "sbatch<<'EOF'\n#!/bin/sh\n#SBATCH --job-name=mirai\n#SBATCH --mem=16G\n#SBATCH --output=job.out\nmodule load R/4.5.0\n"
#> [2] "."                                                                                                                     
#> [3] "\nEOF"                                                                                                                 
#> 
#> $rscript
#> [1] "/opt/R/4.5.2/lib/R/bin/Rscript"
#> 
#> $quote
#> NULL
#> 

# SGE Config:
cluster_config(
  command = "qsub",
  options = "#$ -N mirai
             #$ -l mem_free=16G
             #$ -o job.out
             module load R/4.5.0",
  rscript = file.path(R.home("bin"), "Rscript")
)
#> $command
#> [1] "/bin/sh"
#> 
#> $args
#> [1] "qsub<<'EOF'\n#!/bin/sh\n#$ -N mirai\n#$ -l mem_free=16G\n#$ -o job.out\nmodule load R/4.5.0\n"
#> [2] "."                                                                                            
#> [3] "\nEOF"                                                                                        
#> 
#> $rscript
#> [1] "/opt/R/4.5.2/lib/R/bin/Rscript"
#> 
#> $quote
#> NULL
#> 

# Torque/PBS Config:
cluster_config(
  command = "qsub",
  options = "#PBS -N mirai
             #PBS -l mem=16gb
             #PBS -o job.out
             module load R/4.5.0",
  rscript = file.path(R.home("bin"), "Rscript")
)
#> $command
#> [1] "/bin/sh"
#> 
#> $args
#> [1] "qsub<<'EOF'\n#!/bin/sh\n#PBS -N mirai\n#PBS -l mem=16gb\n#PBS -o job.out\nmodule load R/4.5.0\n"
#> [2] "."                                                                                              
#> [3] "\nEOF"                                                                                          
#> 
#> $rscript
#> [1] "/opt/R/4.5.2/lib/R/bin/Rscript"
#> 
#> $quote
#> NULL
#> 

# LSF Config:
cluster_config(
  command = "bsub",
  options = "#BSUB -J mirai
             #BSUB -M 16000
             #BSUB -o job.out
             module load R/4.5.0",
  rscript = file.path(R.home("bin"), "Rscript")
)
#> $command
#> [1] "/bin/sh"
#> 
#> $args
#> [1] "bsub<<'EOF'\n#!/bin/sh\n#BSUB -J mirai\n#BSUB -M 16000\n#BSUB -o job.out\nmodule load R/4.5.0\n"
#> [2] "."                                                                                              
#> [3] "\nEOF"                                                                                          
#> 
#> $rscript
#> [1] "/opt/R/4.5.2/lib/R/bin/Rscript"
#> 
#> $quote
#> NULL
#> 

if (FALSE) { # \dontrun{

# Launch 2 daemons using the Slurm sbatch defaults:
daemons(n = 2, url = host_url(), remote = cluster_config())
} # }
```
