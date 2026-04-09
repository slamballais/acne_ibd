#!/usr/bin/env Rscript
# prepare_scdrs.R: Convert the MAGMA results to scDRS input

# Packages
  library(data.table)
  setDTthreads(8)

# Arguments
  args <- commandArgs(trailingOnly = TRUE)
  p_magma <- args[1]
  p_out <- args[2]
  trait_name <- args[3]

# Main
  magma_dt <- fread(p_magma)
  zscore_dt <- magma_dt[, .(GENE, ZSTAT)]
  setnames(zscore_dt, "ZSTAT", trait_name)
  fwrite(zscore_dt, p_out, sep = "\t")