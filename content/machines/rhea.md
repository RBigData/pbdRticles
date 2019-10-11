# R and pbdR on Rhea

## Background

Before proceeding, you should familiareize yourself with the [OLCF User Documentation](https://docs.olcf.ornl.gov/), specifically the [Rhea User Guide](https://docs.olcf.ornl.gov/systems/rhea_user_guide.html). Most questions about Rhea that you have are covered in the user guide.

Also, if you are not familiar with MPI or running R scripts in batch, then we strongly recommend reading our [MPI tutorial](../pbdR/mpi.md) first.

Finally, if you want to use R and/or pbdR on Rhea, please feel free to contact us directly:

* Mike Matheson - mathesonma AT ornl DOT gov
* George Ostrouchov - ostrouchovg AT ornl DOT gov
* Drew Schmidt - schmidtda AT ornl DOT gov

We are happy to provide various levels of support and collaboration. You can also put in a ticket with the OLCF help system [help@olcf.ornl.gov](mailto:help@olcf.ornl.gov) if you prefer.



## Loading R

If you have logged in with the default modules, then you need to load the appropriate version of gcc first:

```bash
module load gcc/6.2.0
module load r/3.5.2-py3
```

If we do that and launch R, then we see:

```r
version
## platform       x86_64-pc-linux-gnu         
## arch           x86_64                      
## os             linux-gnu                   
## system         x86_64, linux-gnu           
## status                                     
## major          3                           
## minor          5.2                         
## year           2018                        
## month          12                          
## day            20                          
## svn rev        75870                       
## language       R                           
## version.string R version 3.5.2 (2018-12-20)
## nickname       Eggshell Igloo              

sessionInfo()
## R version 3.5.2 (2018-12-20)
## Platform: x86_64-pc-linux-gnu (64-bit)
## Running under: Red Hat Enterprise Linux Server 7.6 (Maipo)
## 
## Matrix products: default
## BLAS: /autofs/nccs-svm1_sw/rhea/.swci/0-core/opt/spack/20180914/linux-rhel7-x86_64/## gcc-6.2.0/r-3.5.2-n4hthlj5mpcbde72cpin5gpbi5trgouk/rlib/R/lib/libRblas.so
## LAPACK: /autofs/nccs-svm1_sw/rhea/.swci/0-core/opt/spack/20180914/linux-rhel7-x86_64/gcc-6.2.0/r-3.5.2-n4hthlj5mpcbde72cpin5gpbi5trgouk/rlib/R/lib/libRlapack.so
## 
## locale:
##  [1] LC_CTYPE=en_US.UTF-8       LC_NUMERIC=C              
##  [3] LC_TIME=en_US.UTF-8        LC_COLLATE=en_US.UTF-8    
##  [5] LC_MONETARY=en_US.UTF-8    LC_MESSAGES=en_US.UTF-8   
##  [7] LC_PAPER=en_US.UTF-8       LC_NAME=C                 
##  [9] LC_ADDRESS=C               LC_TELEPHONE=C            
## [11] LC_MEASUREMENT=en_US.UTF-8 LC_IDENTIFICATION=C       
## 
## attached base packages:
## [1] stats     graphics  grDevices utils     datasets  methods   base     
## 
## loaded via a namespace (and not attached):
## [1] compiler_3.5.2
```



## How to Run an R Script

TODO



## Hello World Example

We will run a slight modification of the hello world example from our [MPI tutorial](../pbdR/mpi.md) to show how this works. The R code is:

```r
suppressMessages(library(pbdMPI))

msg = paste0("Hello from rank ", comm.rank(), " (local rank ", comm.localrank(), ") of ", comm.size())
comm.print(msg, all.rank=TRUE, quiet=TRUE)

finalize()
```

Save this in a file `hw.r`, ...

TODO
