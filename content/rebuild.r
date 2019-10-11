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

clean = function(outdir)
{
  if (dir.exists(outdir))
    unlink(outdir, recursive = TRUE)
  
  dir.create(outdir)
}

build = function(files, formats, outdir)
{
  for (f in files)
  {
    prepath = dirname(f)
    filename = sub(basename(f), pattern="[.][Rr]md", replacement="")
    outfiles = c()
    
    for (fmt in formats)
    {
      rmarkdown::render(f, output_format=fmt)
      
      ext = eval(parse(text=fmt))()$pandoc$ext
      outfiles = c(outfiles, paste0(prepath, "/", filename, ext))
    }
    
    cachefiles = paste0(prepath, "/", filename, "_files")
    check = file.copy(from=cachefiles, to=outdir, recursive=TRUE)
    if (!isTRUE(check))
      stop(paste("could not move knitr cache files:", cachefiles))
    else
      unlink(cachefiles, recursive = TRUE)
    
    for (of in outfiles)
    {
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
clean(outdir)

content_r = find_rmd_files("content/R")
build(files=content_r, formats=fmts, outdir=outdir)

content_pbdr = find_rmd_files("content/pbdR")
build(files=content_pbdr, formats=fmts, outdir=outdir)
