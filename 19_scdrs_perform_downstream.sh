#!/bin/bash
# 19_scdrs_perform_downstream.sh

# Load all variables and functions
  source "$(dirname "$0")/00_config.sh"
  
# Load right env
  module purge
  module load Miniconda3/24.7.1
  
# Run
  for tissue in blood spleen ; do
    for traits in acne_ibd acne_cd acne_uc ; do
      sbatch_conda "scdrs_downstream_${traits}_${tissue}" 32 "6gb" \
        scdrs perform-downstream \
          --h5ad_file "${d_ss}/tabula_sapiens_${tissue}.h5ad" \
          --score_file "${d_scdrs_out}/${tissue}/${traits}.full_score.gz" \
          --group_analysis "cell_type" \
          --out_folder "${d_scdrs_out}/${tissue}"
    done
  done