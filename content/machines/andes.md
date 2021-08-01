# R and pbdR on Andes

## Background

Before proceeding, you should familiareize yourself with the [OLCF User Documentation](https://docs.olcf.ornl.gov/), specifically the [Andes User Guide](https://docs.olcf.ornl.gov/systems/andes_user_guide.html). Most questions about Andes that you have are covered in the user guide.

Also, if you are not familiar with MPI or running R scripts in batch, then we strongly recommend reading our [MPI tutorial](../pbdR/mpi.md) first.

Finally, if you want to use R and/or pbdR on Andes, please feel free to contact us directly:

* Mike Matheson - mathesonma AT ornl DOT gov
* George Ostrouchov - ostrouchovg AT ornl DOT gov
* Drew Schmidt - schmidtda AT ornl DOT gov

We are happy to provide various levels of support and collaboration. You can also put in a ticket with the OLCF help system [help@olcf.ornl.gov](mailto:help@olcf.ornl.gov) if you prefer.



## Loading R

If you have logged in with the default modules, then you need to load the appropriate version of gcc first:

```bash
module load gcc/9.3.0
module load r/4.0.3-py3
```

If we do that and launch R, then we see:

```r
version
##                _                           
## platform       x86_64-pc-linux-gnu         
## arch           x86_64                      
## os             linux-gnu                   
## system         x86_64, linux-gnu           
## status                                     
## major          4                           
## minor          0.3                         
## year           2020                        
## month          10                          
## day            10                          
## svn rev        79318                       
## language       R                           
## version.string R version 4.0.3 (2020-10-10)
## nickname       Bunny-Wunnies Freak Out     

sessionInfo()
## R version 4.0.3 (2020-10-10)
## Platform: x86_64-pc-linux-gnu (64-bit)
## Running under: Red Hat Enterprise Linux 8.3 (Ootpa)

## Matrix products: default
## BLAS:   /autofs/nccs-svm1_sw/andes/spack-envs/base/opt/linux-rhel8-x86_64/gcc-8.3.1/r-4.0.3-kpe33prl3c57rthmc2hgib4kxife7eln/rlib/R/lib/libRblas.so
## LAPACK: /autofs/nccs-svm1_sw/andes/spack-envs/base/opt/linux-rhel8-x86_64/gcc-8.3.1/r-4.0.3-kpe33prl3c57rthmc2hgib4kxife7eln/rlib/R/lib/libRlapack.so

## locale:
##  [1] LC_CTYPE=en_US.UTF-8       LC_NUMERIC=C              
##  [3] LC_TIME=en_US.UTF-8        LC_COLLATE=en_US.UTF-8    
##  [5] LC_MONETARY=en_US.UTF-8    LC_MESSAGES=en_US.UTF-8   
##  [7] LC_PAPER=en_US.UTF-8       LC_NAME=C                 
##  [9] LC_ADDRESS=C               LC_TELEPHONE=C            
## [11] LC_MEASUREMENT=en_US.UTF-8 LC_IDENTIFICATION=C       

## attached base packages:
## [1] stats     graphics  grDevices utils     datasets  methods   base     

## loaded via a namespace (and not attached):
## [1] compiler_4.0.3
```


## Hello World Example R script

We will run a slight modification of the hello world example from our [MPI tutorial](../pbdR/mpi.md) to show how this works. The R code is:

```r
suppressMessages(library(pbdMPI))

msg = paste0("Hello from rank ", comm.rank(), " of ", comm.size())
comm.print(msg, all.rank=TRUE, quiet=TRUE)

finalize()
```
Save this in a file `hw.r` and prepare the submssion script next.

Andes uses the Slurm workload manager to allocate, run, and manage jobs. The first thing is to write a batch submission script. Here is a simple example:
```sh
#!/bin/sh
#SBATCH -A abc123
#SBATCH -J your_script_name
#SBATCH -N 2
#SBATCH -t 0:10:00

module load gcc/9.3.0
module load r/4.0.3-py3
  
srun -n 4 Rscript hw.R
```
where
* `abc123` is replaced with your project account
* `your_script_name` is a name you pick
* `-N 2` requests two nodes for your job
* `-t h:mm:ss` specifies a time limit for the run
* `srun -n 4 Rscript hw.R` runs four instances of your hw.R Rscript on two nodes

Save this script in a file `test.andes` and submit the batch job with:

```sh
sbatch test.andes
```

The output from your job will be saved in files `slurm-######.out` and `slurm-######.err`.
