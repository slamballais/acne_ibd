#!/usr/bin/env Rscript
# clean_ss_teder.R: cleans the summary statistics of the acne GWAS

#### PACKAGES
library(data.table)
setDTthreads(8)

#### ARGUMENTS
args <- commandArgs(trailingOnly = TRUE)
p_old <- args[1]
p_new <- args[2]
n_con <- as.numeric(args[3])
n_case <- as.numeric(args[4])
p_ref <- args[5]

#### LOAD + PREP SS
ss <- fread(p_old)
ss <- subset(ss, chromosome != "X")
ss[, chromosome := as.numeric(chromosome)]
ss[, variant_id := paste0(chromosome, ":", base_pair_location, ":", other_allele, ":", effect_allele)]
ss <- ss[, c(1, 3:6, 8, 9, 2)]

# set names
old_names <- c("variant_id", "chromosome", "base_pair_location", "effect_allele", "other_allele", "effect_allele_frequency",
               "beta", "standard_error", "p_value")          
new_names <- c("marker1", "CHR", "BP", "A1", "A2", "AF", "BETA", "SE", "PVAL")
setnames(ss, old_names, new_names)

# align with REF
ref <- fread(p_ref)
ref[, marker1 := paste0(CHR, ":", BP, ":", A2, ":", A1)]
ref[, marker2 := paste0(CHR, ":", BP, ":", A1, ":", A2)]

m1 <- match(ss$marker1, ref$marker1)
m2 <- match(ss$marker1, ref$marker2)

new_snp <- ss$marker1
new_snp[] <- NA
new_snp[!is.na(m1)] <- ref$SNP[m1[!is.na(m1)]]
new_snp[!is.na(m2)] <- ref$SNP[m2[!is.na(m2)]]

ss[, SNP := new_snp]
ss[, marker1 := NULL]
ss <- subset(ss, !is.na(SNP))

# calculate Z score
ss[, Z := BETA / SE]

# add effective n
ss[, N := 4 / (1 / n_con + 1 / n_case)]

# filter MHC region
ss <- ss[!(CHR == 6 & BP >= 25119106 & BP <= 33854733)]

# set order of columns to match normal mixer input + sort
setcolorder(ss, c("SNP", "CHR", "BP", "PVAL", "A1", "A2", "Z", "BETA", "SE", "N", "AF"))
setorder(ss, CHR, BP)

#### WRITE OUTPUT
fwrite(ss, p_new, quote = FALSE, row.names = FALSE, sep = "\t")
