#!/bin/bash
# 10_process_fuma.sh: process results from fuma (see script 09!!!!!)

# Load all variables and functions
  source "$(dirname "$0")/00_config.sh"
  
# Load R
  module purge
  module load R/4.4.2
  
# Prepare results
  unzip -o "${d_snp2gene}/${snp2gene_prefix}teder_ibd.zip" -d "${d_snp2gene}/acne_ibd"
  unzip -o "${d_snp2gene}/${snp2gene_prefix}teder_uc.zip" -d "${d_snp2gene}/acne_uc"
  unzip -o "${d_snp2gene}/${snp2gene_prefix}teder_cd.zip" -d "${d_snp2gene}/acne_cd"
  
  unzip -o "${d_gene2func}/${gene2func_prefix}teder_ibd.zip" -d "${d_gene2func}/acne_ibd"
  unzip -o "${d_gene2func}/${gene2func_prefix}teder_uc.zip" -d "${d_gene2func}/acne_uc"
  unzip -o "${d_gene2func}/${gene2func_prefix}teder_cd.zip" -d "${d_gene2func}/acne_cd"
  
# extract all information, create all figures
  Rscript "$d_scripts/fuma.R" \
    --d_snp2gene="$d_snp2gene" \
    --d_gene2func="$d_gene2func" \
    --pleio_rds="${d_output}/placo.rds"