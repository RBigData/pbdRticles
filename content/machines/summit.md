# R and pbdR on Summit

## Background

Before proceeding, you should familiareize yourself with the [OLCF User Documentation](https://docs.olcf.ornl.gov/), specifically the [Summit User Guide](https://docs.olcf.ornl.gov/systems/summit_user_guide.html). Most questions about Summit that you have are covered in the user guide.

Also, if you are not familiar with MPI or running R scripts in batch, then we strongly recommend reading our [MPI tutorial](../pbdR/mpi.md) first.



## Loading R

Several versions of R are supported. However, you will need to load the appropriate gcc module before you can load R. Throughout this example, we will be using R version 3.6.1, which is a fairly recent release at the time of writing.

If you have logged in with the default modules, then you need to swap `xl` for `gcc` and the load R:

```bash
module swap xl gcc/6.4.0
module load r/3.6.1
```

If we do that and launch R, then we see:

```r
version
## platform       powerpc64le-unknown-linux-gnu
## arch           powerpc64le                  
## os             linux-gnu                    
## system         powerpc64le, linux-gnu       
## status                                      
## major          3                            
## minor          6.1                          
## year           2019                         
## month          07                           
## day            05                           
## svn rev        76782                        
## language       R                            
## version.string R version 3.6.1 (2019-07-05) 
## nickname       Action of the Toes           

sessionInfo()
## R version 3.6.1 (2019-07-05)
## Platform: powerpc64le-unknown-linux-gnu (64-bit)
## Running under: Red Hat Enterprise Linux Server 7.6 (Maipo)
## 
## Matrix products: default
## BLAS/LAPACK: /autofs/nccs-svm1_sw/summit/r/3.6.1/rhel7.6_gnu6.4.0/lib64/R/lib/libRblas.so
## 
## locale:
## [1] C
## 
## attached base packages:
## [1] stats     graphics  grDevices utils     datasets  methods   base     
## 
## loaded via a namespace (and not attached):
## [1] compiler_3.6.1
```



## Running an R Script

Summit has a node hierarchy that can be very confusing for the uninitiated. The official documentation clarifies this, but here is a very quick summary:

* Login nodes
    - Where you land when you `ssh` to Summit.
    - Shared compute resource - be polite and don't run anything expensive here.
    - No MPI code can run here.
* Launch nodes
    - Where you land when you launch a job on Summit.
    - Shared compute resource - useful for small scale debugging/testing.
    - Processes not launched by MPI will run here.
    - Similar to the service nodes on Titan if you know what that means.
* Compute nodes
    - Summit proper.
    - Isolated compute resource - you own the whole node.
    - Scripts can only run here if they are launched with MPI (even if you don't *really* need to use MPI).

The login nodes are not meant for running your scripts. You can install your R packages there (careful where you put them! more on this in a minute). You *can* run non-MPI tasks there, but you *shouldn't* (unless they're fairly simple/not resource intensive). You also should not run expensive tasks on the launch nodes. For that, you need to use the compute nodes. To run your job on the compute nodes:

* You must have a script that you can run in batch, e.g. with `Rscript` (See our [MPI tutorial](../pbdR/mpi.md) for more information).
* All data that needs to be visible to the R process (including the script) *must be on gpfs (not your home directory!)*.
* You must launch your script from the launch nodes with `jsrun` (Summit's `mpirun`).



## Running an Example R Script

We will run a slight modification of the hello world example from our [MPI tutorial](../pbdR/mpi.md) to show how this works. The R code is:

```r
suppressMessages(library(pbdMPI))

msg = paste0("Hello from rank ", comm.rank(), " (local rank ", comm.localrank(), ") of ", comm.size())
comm.print(msg, all.rank=TRUE, quiet=TRUE)

finalize()
```

Save this in a file `hw.r`, *somewhere on gpfs*. So say your project is `abc123`. You might have `hw.r` in `/gpfs/alpine/abc123/proj-shared/my_hw_path/`.

There are two ways we can run this. One is with an interactive job, and one is with a batch job. The interactive job doesn't provide us with the ability to run interactive R jobs on the compute nodes. However, it allows us to interactively submit tasks to the compute nodes (launched via `jsrun`). This can be useful if you are trying to debug a script that unexpectedly dies, without having to continuously submit jobs to the batch queue (more on that in a moment).

We can start an interactive job with 2 nodes that will run for no more than 10 minutes via:

```bash
bsub -P $PROJECT -nnodes 2 -W 10 -Is $SHELL
```

Note that you need to either set the shell variable `PROJECT` to your project identifier, or replace `$PROJECT` above with the identifier. Once your job begins, you will again be at a shell prompt, but the host should have changed from something like `login1` to `batch1` (numbering may differ). From here, you can launch the hello world script. We will use 2 MPI ranks per node, giving 4 total ranks across the 2 nodes:

```bash
$ jsrun -n4 -r2 Rscript hw.r 
## [1] "Hello from rank 0 (local rank 0) of 4"
## [1] "Hello from rank 1 (local rank 1) of 4"
## [1] "Hello from rank 2 (local rank 0) of 4"
## [1] "Hello from rank 3 (local rank 1) of 4"
```

At this point, we are still running the job and can submit more tasks to the compute nodes if we like. If not, we can end the job by entering `exit` to the terminal.

The other way to run our script is to submit a batch job. To do that, we need to create a batch script:

```bash
#!/bin/bash
#BSUB -P ABC123
#BSUB -W 10
#BSUB -nnodes 2
#BSUB -J rhw

module load gcc/6.4.0
module load r/3.6.1

cd /gpfs/alpine/abc123/proj-shared/my_hw_path/

jsrun -n4 -r2 Rscript hw.r 
```

Before continuing, a few comments. First you need to replace the example project identifiers (`ABC123` above) with your project. Second, load the appropriate modules (here we just need R). Third, make sure that you change directory to the appropriate place on gpfs. Finally, add your `jsrun` call. Optionally, you can change the name of your job from `rhw` to something else by modifying the `#BSUB -J` line.

We need to save this to a file, say `job.bs`. We submit the job to the queue via `bsub job.bs`. Once we do, we have to wait for the job to start, then to run. After however long that takes, I get the output file `rhw.679095`. If I cat that file, I see:

```
[1] "Hello from rank 0 (local rank 0) of 4"
[1] "Hello from rank 1 (local rank 1) of 4"
[1] "Hello from rank 2 (local rank 0) of 4"
[1] "Hello from rank 3 (local rank 1) of 4"

------------------------------------------------------------
Sender: LSF System <lsfadmin@batch2>
Subject: Job 679095: <rhw> in cluster <summit> Done

Job <rhw> was submitted from host <login2> by user <va8> in cluster <summit> at Fri Oct 11 11:06:45 2019
Job was executed on host(s) <1*batch2>, in queue <batch>, as user <va8> in cluster <summit> at Fri Oct 11 11:07:00 2019
                            <42*a32n14>
                            <42*a32n15>
</ccs/home/va8> was used as the home directory.
</gpfs/alpine/stf011/proj-shared/va8> was used as the working directory.
Started at Fri Oct 11 11:07:00 2019
Terminated at Fri Oct 11 11:07:08 2019
Results reported at Fri Oct 11 11:07:08 2019

The output (if any) is above this job summary.
```

The information below the dashes can be occasionally helpful for debugging sometimes, say if there is some kind of hardware problem. But again, we basically see the same output.



## GPU Computing with R

To run on Summit, your code needs to use GPUs. There are some R packages which can use GPUs, such as xgboost. Several pbdR packages support GPU computing. It is also possible to offload some linear algebra computations (specifically matrix-matrix products, and methods which are computationally dominated by them) to the GPU using [NVIDIA's NVBLAS](https://docs.nvidia.com/cuda/nvblas/index.html).

If you want to use R and/or pbdR on Summit, please feel free to contact us directly:

* George Ostrouchov - ostrouchovg AT ornl DOT gov
* Drew Schmidt - schmidtda AT ornl DOT gov

We are happy to provide various levels of support and collaboration. You can also put in a ticket with the OLCF help system [help@olcf.ornl.gov](mailto:help@olcf.ornl.gov) if you prefer.
