# Task Parallelism with the tasktools Package


## Background

In our [discussion about MPI with pbdMPI](mpi.md), we discussed task parallelism using the pbdMPI functions `get.jid()`, `pbdLapply()` and `pbdSapply()`. If you have not read that tutorial, or are not familiar with concepts like batch SPDM programming, then we strongly encourage you to read that first.

The [tasktools package](http://github.com/rbigdata/tasktools) takes a different approach to task parallelism than even other pbdR tools, such as those in pbdMPI noted above. This is because it has a slightly different, focused motivation. We have used this in production on some of the largest systems in the world, including [Summit](https://www.olcf.ornl.gov/summit/). There, we used it to drive the simulation of multiple TB of multidimensional images of electron diffraction patterns. Neither tasktools nor R actually performed the simulations, but it enabled us to run the simulations, automatically handling the complicated bookkeeping for us.

In this tutorial, we will discuss how to effectively use the tasktools package for task parallel computing. But before we get to discussions about parallelism, we need to first discuss checkpointing aka "checkpoint/restart".

Checkpointing is a very important topic in HPC that is almost completely alien to the outside world. But the idea itself is simple and familiar to most. It is essentially the process of creating a backup (checkpoint) and then restoring that backup (restart) for a computational code.

One reason this process is important in HPC is because we use "job schedulers" to decide which codes get to run, and for how long. It's very typical to see run windows for no longer than 24 hours. If your code needs to run longer,

It is also a strategy for dealing with hardware errors that are otherwise very hard to guard against. If you are computing on hundreds or thousands of nodes and one of them dies on you in the middle of your computation (it's more common than you probably think!), then you probably don't want to have to completely start over. The simulation scientists have been heavy users of the checkpoint/restart idiom for decades for exactly this reason.

Not every problem is amenable to checkpoint/restart. Fortunately, many of the problems that are of interest to us in the data analytics/modeling space are. One obvious example is deep learning. You just need to dump your weights to disk every n epochs and have a way to read them back in and keep going right where you left off. This gets a little more complicated if you are doing this in a model-parallel way with something like [horovod](https://github.com/horovod/horovod) or [NVIDIA's NCCL](https://developer.nvidia.com/nccl), but the solution is fundamentally the same.

Another easy use-case for checkpoint/restart is when dealing with lots of independent tasks (parallel or otherwise). This is the problem that tasktools primarily deals with. The remainder of this document will discuss how to use the tasktools package to handle these problems.



## Checkpoint/Restart with crlapply()

If you can cast your problem as an `lapply()`, then changing this call to `crlapply()` will automatically handle the checkpoint/restart. Like `lapply()`, this is for serial execution (we'll get to parallel stuff later). For the purposes of demonstration, throughout the remaining we'll use a (fake) "expensive" function for our evaluations:

```r
costly = function(x, waittime)
{
  Sys.sleep(waittime)
  print(paste("iteration:", x))
  
  sqrt(x)
}
```

Consider this function our [slow regular square root](https://en.wikipedia.org/wiki/Fast_inverse_square_root). We can make an `lapply()`-like run in serial with checkpointing via:

```r
ret = crlapply(1:10, costly, FILE="/tmp/cr.rdata", waittime=0.5)
unlist(ret)
```

Note that just like in normal `lapply()` and its many variants (e.g., `parallel::mclapply()`), we can pass additional arguments to the executed function (here `waittime=0.5`).

Next, let's save these R source code listings to the file `crlapply.r`. We can run this script from the command line and kill it a few times to show what the function is actually doing (here `^C` means `ctrl-c` was executed, aka the job was killed):

```bash
Rscript crlapply.r 
## [1] "iteration: 1"
## [1] "iteration: 2"
## [1] "iteration: 3"
^C
Rscript crlapply.r 
## [1] "iteration: 4"
## [1] "iteration: 5"
## [1] "iteration: 6"
## [1] "iteration: 7"
^C
Rscript crlapply.r 
## [1] "iteration: 8"
## [1] "iteration: 9"
## [1] "iteration: 10"
## 
##  [1] 1.000000 1.414214 1.732051 2.000000 2.236068 2.449490 2.645751 2.828427
##  [9] 3.000000 3.162278
```

A complete, ready-to-run version of this example is available in the `crlapply.r` script in the [tasktools examples directory](https://github.com/RBigData/tasktools/tree/master/inst/examples).



## Task Parallelism

Now we'll do checkpoint/restart task-based parallelism in parallel. This is a lot of words and might sound complicated. But if you understand the `tasktools::crlapply()` example for checkpoint/restart, and if you understand how to use `parallel::mclapply()` for parallelism, then this is pretty straightforward. You just combine the two approaches (conceptually, anyway).

Let's continue from the example above. Since we are operating on the integer sequence of values 1 to 10 and each execution is completely independent from the other ones, we can easily parallelize this. We'll use the `mpi_napply()` ("n-apply", or "apply n times") function, which can even distribute the work across multiple nodes:

```r
ret = mpi_napply(10, costly, checkpoint_path="/tmp", waittime=1)
comm.print(unlist(ret))
```

To see exactly what happens during execution, we will modify the print line in the "costly" function to be:

```r
cat(paste("iter", i, "executed on rank", comm.rank(), "\n"))
```

Let's run this with 3 MPI ranks. We can again run and kill it a few times to demonstrate the checkpointing:

```bash
mpirun -np 3 r mpi_napply.r 
## iter 4 executed on rank 1 
## iter 7 executed on rank 2 
## iter 1 executed on rank 0 
^C
## iter 2 executed on rank 0 
## iter 8 executed on rank 2 
## iter 5 executed on rank 1 

mpirun -np 3 r mpi_napply.r 
## iter 9 executed on rank 2 
## iter 3 executed on rank 0 
## iter 6 executed on rank 1 
## iter 10 executed on rank 2 
## 
##  [1] 1.000000 1.414214 1.732051 2.000000 2.236068 2.449490 2.645751 2.828427
##  [9] 3.000000 3.162278
```

Notice that things are executed out of order (if order really mattered, then it wasn't parallel!). But basically, it's a parallel `crlapply()`.

There is also a non-prescheduling variant of `mpi_napply()`. This can be useful if there is a lot of variability in the time your tasks take to complete. To use it, all you have to do is set `preschedule=FALSE`, and the tasks will be executed on a "first come, first serve" basis:

```r
ret = mpi_napply(10, costly, preschedule=FALSE, waittime=1)
comm.print(unlist(ret))
```

Now, it's worth noting that in this case, rank 0 behaves as a manager doling out work (this strategy is sometimes called "manager/worker" or in the older terminology "master/slave"). So here, rank 0 is not used in computation since it needs to be ready at a moment's notice to send tasks to needy workers.

```bash
## iter 1 executed on rank 1 
## iter 2 executed on rank 2 
## iter 3 executed on rank 1 
## iter 4 executed on rank 2 
## iter 5 executed on rank 1 
## iter 6 executed on rank 2 
## iter 7 executed on rank 1 
## iter 8 executed on rank 2 
## iter 9 executed on rank 1 
## iter 10 executed on rank 2 
## 
##  [1] 1.000000 1.414214 1.732051 2.000000 2.236068 2.449490 2.645751 2.828427
##  [9] 3.000000 3.162278
```

Because the manager process (rank 0) was managing, it does not appear in any of the output. Finally, this too supports checkpointing, but hopefully how that works is clear.

A complete, ready-to-run version of this example is available in the `mpi_napply.r` and `mpi_napply_nopreschedule.r` scripts in the [tasktools examples directory](https://github.com/RBigData/tasktools/tree/master/inst/examples).
