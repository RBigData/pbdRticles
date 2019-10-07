#!/usr/bin/env Rscript
library(rmarkdown)

outdir = "build"
fmts = "md_document" # c("md_document", "html_document")


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


setroot()
clean(outdir)

content_r = dir("content/R", full.names=TRUE)
build(files=content_r, formats=fmts, outdir=outdir)

content_pbdr = dir("content/pbdR", full.names=TRUE)
build(files=content_pbdr, formats=fmts, outdir=outdir)
