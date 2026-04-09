#!/usr/bin/env Rscript
# clean_ss_ibd.R: cleans the summary statistics of the IBD GWASs

#### PACKAGES
library(data.table)
library(liftOver)
setDTthreads(0)

#### ARGUMENTS
args <- commandArgs(trailingOnly = TRUE)
p_old <- args[1]
p_new <- args[2]
n_con_nfe <- as.numeric(args[3])
n_case_nfe <- as.numeric(args[4])
n_con_fin <- as.numeric(args[5])
n_case_fin <- as.numeric(args[6])
p_ref <- args[7]

#### LOAD + PREP SS
ss <- fread(p_old)

# drop irrelevant columns already (for compute reasons)
drop_cols <- c("Freq1", "FreqSE", "MinFreq", "MaxFreq", "Effect", 
               "StdErr", "P-value", "Direction", "HetISq", "HetChiSq",
               "HetDf", "HetPVal", "AF_EAS", "BETA_EAS", "SE_EAS", "P_EAS")
ss[, (drop_cols) := NULL]

# keep only those that are relevant for NFE and FIN
ss <- subset(ss, !is.na(BETA_NFE) | !is.na(BETA_FIN))

# recompute BETA, SE, P, and AF
ss[, N_NFE := n_con_nfe + n_case_nfe]
ss[, N_FIN := n_con_fin + n_case_fin]
ss[, W_NFE := 1/(SE_NFE^2)]
ss[, W_FIN := 1/(SE_FIN^2)]

ss[, BETA := ( (W_NFE * BETA_NFE) + (W_FIN * BETA_FIN) ) / (W_NFE + W_FIN)]
ss[, SE := sqrt(1 / (W_NFE + W_FIN))]
ss[, AF := ( (AF_NFE * N_NFE) + (AF_FIN * N_FIN) ) / (N_NFE + N_FIN)]

  # redo where only NFE
  ss[!is.na(BETA_NFE) & is.na(BETA_FIN), `:=`(
    BETA = BETA_NFE,
    SE   = SE_NFE,
    AF   = AF_NFE
  )]

  # redo where only FIN
  ss[is.na(BETA_NFE) & !is.na(BETA_FIN), `:=`(
    BETA = BETA_FIN,
    SE   = SE_FIN,
    AF   = AF_FIN
  )]
  
ss[, Z := BETA / SE]
ss[, PVAL := 2 * pnorm(-abs(Z))]

# set names
old_names <- c("CHR", "BP", "Allele1", "Allele2", "BETA", "SE", "Z", "PVAL", "AF")          
new_names <- c("CHR", "BP", "A2", "A1", "BETA", "SE", "Z", "PVAL", "AF") # note: A2 and A1 are flipped compared to convention
ss <- ss[, ..old_names]
setnames(ss, old_names, new_names, skip_absent = TRUE)

# capitalize A1/A2
ss[, A1 := toupper(A1)]
ss[, A2 := toupper(A2)]

ss[, marker1 := paste0(CHR, ":", BP, ":", A2, ":", A1)]

# liftover
p_chain <- system.file(package = "liftOver", "extdata", "hg38ToHg19.over.chain")
chain <- import.chain(p_chain)

ss2 <- GRanges(seqnames = Rle(paste0("chr", ss$CHR)), 
               ranges = IRanges(start = ss$BP, width = 1))        
ss2$marker1 <- ss$marker1

ss3 <- as.data.table(unlist(liftOver(ss2, chain)))
ss3[, CHR := as.numeric(sub("chr", "", seqnames))]
ss3[, BP := start]
ss3[, c("seqnames", "start", "end", "width", "strand") := NULL]

ss <- merge(subset(ss, select = -c(CHR, BP)), subset(ss3, !is.na(CHR)))

# clean up liftover set
dup_markers <- ss$marker1[duplicated(ss$marker1)]
if (length(dup_markers) > 0) ss <- ss[!ss$marker1 %in% dup_markers]
ss <- ss[, new_names, with = FALSE]
setorder(ss, CHR, BP)
ss[, marker1 := paste0(CHR, ":", BP, ":", A2, ":", A1)]

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

dup_markers <- ss$SNP[duplicated(ss$SNP)]
if (length(dup_markers) > 0) ss <- ss[!ss$SNP %in% dup_markers]

# add effective n
ss[, N := 4 / (1 / (n_con_nfe + n_con_fin) + 1 / (n_case_nfe + n_case_fin))]

# filter MHC region
ss <- ss[!(CHR == 6 & BP >= 25119106 & BP <= 33854733)]

# set order of columns to match normal mixer input + sort
setcolorder(ss, c("SNP", "CHR", "BP", "PVAL", "A1", "A2", "Z", "BETA", "SE", "N", "AF"))
setorder(ss, CHR, BP)

#### WRITE OUTPUT
fwrite(ss, p_new, quote = FALSE, row.names = FALSE, sep = "\t")
