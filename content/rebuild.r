#!/usr/bin/env Rscript
library(rmarkdown)

outdir = "build"
fmts = "md_document" # c("md_document", "html_document")


setroot = function()
{
  while (!file.exists(".projroot"))
  {
    setwd("..")
    if (getwd() == "/")
      stop("could not find project root; please run script from somewhere in the project directory")
  }
}

rmdir = function(path)
{
  if (dir.exists(path))
    unlink(path, recursive = TRUE)
}

build = function(files, formats, outdir)
{
  for (f in files)
  {
    prepath = dirname(f)
    filename = sub(basename(f), pattern="[.][Rr]md", replacement="")
    outfiles = c()
    
    cachefiles = paste0(prepath, "/", filename, "_files")
    cachefiles_outdir = paste0(outdir, "/", filename, "_files")
    rmdir(cachefiles_outdir)
    
    for (fmt in formats)
    {
      rmarkdown::render(f, output_format=fmt)
      
      ext = eval(parse(text=fmt))()$pandoc$ext
      outfiles = c(outfiles, paste0(prepath, "/", filename, ext))
    }
    
    check = file.copy(from=cachefiles, to=outdir, recursive=TRUE)
    if (!isTRUE(check))
      stop(paste("could not move knitr cache files:", cachefiles))
    else
      rmdir(cachefiles)
    
    for (of in outfiles)
    {
      of_outdir = paste0(outdir, "/", filename, ext)
      file.remove(of_outdir)
      
      check = file.copy(from=of, to=outdir)
      if (!isTRUE(check))
        stop(paste("could not move generated outputfile:", of))
      else
        file.remove(of)
    }
  }
}

find_rmd_files = function(path)
{
  dir(path, full.names=TRUE, pattern="*.rmd", ignore.case=TRUE)
}



setroot()

content_r = find_rmd_files("content/R")
build(files=content_r, formats=fmts, outdir=outdir)

content_pbdr = find_rmd_files("content/pbdR")
build(files=content_pbdr, formats=fmts, outdir=outdir)
