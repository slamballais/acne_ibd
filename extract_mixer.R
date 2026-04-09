#!/usr/bin/env Rscript
# process_smultixcan.R: Get all the MiXeR results into a table

# Packages
library(magrittr)
library(yaml)

# Functions
extract_trait <- function(x) sub("[0-9_].*", "", basename(x))

# Arguments
args <- commandArgs(trailingOnly = TRUE)
out <- args[[1]]
files <- as.list(args[-1])

# Main
res <- lapply(files, read_yaml) %>%
  lapply(function(x) {
    list(
      trait1   = extract_trait(x$options[[3]]),
      trait2   = extract_trait(x$options[[4]]),
      nc1      = x$ci$"nc1@p9"$mean,
      nc2      = x$ci$"nc2@p9"$mean,
      nc12     = x$ci$"nc12@p9"$mean,
      nc1u     = x$ci$"nc1u@p9"$mean,
      nc2u     = x$ci$"nc2u@p9"$mean,
      nc1_std  = x$ci$"nc1@p9"$std,
      nc2_std  = x$ci$"nc2@p9"$std,
      nc12_std = x$ci$"nc12@p9"$std,
      nc1u_std = x$ci$"nc1u@p9"$std,
      nc2u_std = x$ci$"nc2u@p9"$std,
      dice     = x$ci$dice$mean,
      dice_std = x$ci$dice$std,
      frac     = x$ci$fraction_concordant_within_shared$mean,
      frac_std = x$ci$fraction_concordant_within_shared$std
    )
  }) %>%
    do.call("rbind", .)

res[, -(1:2)] <- lapply(res[, -(1:2)], round, 2)
write.table(res, out, quote = FALSE, row.names = FALSE, sep = "\t")

