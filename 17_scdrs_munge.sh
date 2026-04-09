#!/bin/bash
# 17_scdrs_munge.sh

# Load all variables and functions
  source "$(dirname "$0")/00_config.sh"
  
# Load right env
  module purge
  module load Miniconda3/24.7.1
  module load R/4.4.2
  
# Run
  for traits in acne_ibd acne_cd acne_uc ; do
    Rscript "${d_scripts}/prepare_scdrs.R" \
      "${d_snp2gene}/${traits}/magma.genes.out" \
      "${d_scdrs_out}/${traits}_zscore.tsv" \
      "$traits"
    
    sbatch_conda "scdrs_munge_${traits}" 32 "6gb" \
      scdrs munge-gs \
        --out-file "${d_scdrs_out}/${traits}.gs" \
        --zscore-file "${d_scdrs_out}/${traits}_zscore.tsv" \
        --weight "zscore" \
        --n-max 1000
  done