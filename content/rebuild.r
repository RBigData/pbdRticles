#!/usr/bin/env Rscript
library(rmarkdown)

outdir = "build"
fmts = "html_document" # c("md_document", "html_document")


setroot = function(){
  while (!file.exists(".projroot"))
  {
    setwd("..")
    if (getwd() == "/")
      stop("could not find project root; please run script from somewhere in the project directory")
  }
}

clean = function(outdir){
  if (dir.exists(outdir))
    unlink(outdir, recursive = TRUE)
  
  dir.create(outdir)
}

build = function(files, formats, outdir){
  for (f in files){
    for (fmt in formats)
      rmarkdown::render(f, output_format=fmt, output_dir=outdir)
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
