#!/usr/bin/env Rscript
# report_ss.R: Quick calculation of the number of overlapping loci across the three cross-trait associations

# Arguments
  library(optparse)
  
  option_list <- list(
    make_option("--col_acne_ibd", type = "character", help = "column name for acne and ibd"),
    make_option("--col_acne_uc",  type = "character", help = "column name for acne and uc"),
    make_option("--col_acne_cd",  type = "character", help = "column name for acne and cd"),
    make_option("--rds_path",     type = "character", help = "path to sumrank ss in .rds file"),
    make_option("--out_path",     type = "character", help = "path where to store the results")
  )
  
  opt <- parse_args(OptionParser(option_list = option_list))
  attach(opt)

# Packages
  library(data.table)
  setDTthreads(2)

# Functions

  # find which unique loci there are
  find_loci <- function(ss, chr = "CHR", bp = "BP", distance = 250000) {
    ss[, diff_bp := c(0, diff(get(bp)))]
    ss[, diff_chr := c(0, diff(get(chr)))]
    1 + diffinv(ss$diff_chr | (ss$diff_bp > distance))[-1]
  }
  
  # include only loci that have at least 2 SNPs
  true_locus <- function(ss, locus = "locus", minimum = 2) {
    tab <- table(ss[, locus, with = FALSE])
    true_loci <- as.numeric(names(tab)[which(tab >= minimum)])
    unlist(ss[, locus, with = FALSE]) %in% true_loci
  }

# Main
ss <- readRDS(rds_path)

acne <- subset(ss, get(col_acne_ibd) < 5E-8 | get(col_acne_uc) < 5E-8 | get(col_acne_cd) < 5E-8)
acne$locus <- find_loci(acne)
acne$true_locus <- true_locus(acne)

acne_summary <- acne[true_locus == TRUE, list(snps = .N, chr = first(CHR), min = min(BP), max = max(BP), dist = max(BP) - min(BP), p_acne = min(p_acne), p_acne_ibd = min(get(col_acne_ibd)), p_acne_uc = min(get(col_acne_uc)), p_acne_cd = min(get(col_acne_cd))), by = locus]

out <- list(acne_summary = acne_summary)
saveRDS(out, out_path)



