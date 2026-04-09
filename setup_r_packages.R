#!/usr/bin/env Rscript
# setup_r_packages.R: All kinds of packages that were used at some point

r_packages <- c("BiocManager", "cowplot", "doParallel", "data.table", "dplyr", "ggplot2", "ggsci", "magick", "magrittr", "optparse", "openxlsx", "stringr", "UpSetR", "VennDiagram", "yaml")
bioc_packages <- c("liftOver", "GenomicRanges", "IRanges")

for (n in r_packages) 
  if (!require(n, quietly = TRUE, character.only = TRUE))
    install.packages(n, repos = "https://cran.us.r-project.org")

for (n in bioc_packages)
  if (!require(n, quietly = TRUE, character.only = TRUE))
    BiocManager::install(n, ask = FALSE)
