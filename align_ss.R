#!/usr/bin/env Rscript
# align_ss.R: aligns the cleaned summary statistics so that they include only overlapping SNPs

#### PACKAGES
library(data.table)
setDTthreads(8)

#### ARGUMENTS
args <- as.list(commandArgs(trailingOnly = TRUE))

ss_old <- args[seq(1, length(args), 2)]
ss_new <- args[seq(2, length(args), 2)]

ss <- lapply(ss_old, fread)

overlap <- Reduce(function(x, y) intersect(x, y$SNP), init = ss[[1]]$SNP, ss[-1])
ss <- lapply(ss, function(x) x[SNP %in% overlap])

for (i in seq_along(ss_old)) {
  fwrite(ss[[i]], ss_new[[i]], quote = FALSE, row.names = FALSE, sep = "\t")
}