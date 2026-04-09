#!/bin/bash
# 18_scdrs_compute_score.sh

# Load all variables and functions
  source "$(dirname "$0")/00_config.sh"
  
# Load right env
  module purge
  module load Miniconda3/24.7.1
  
# Run
  for tissue in blood spleen ; do
    for traits in acne_ibd acne_cd acne_uc ; do
      mkdir -p "${d_scdrs_out}/${tissue}"
      sbatch_conda "scdrs_score_${traits}_${tissue}" 32 "6gb" \
        scdrs compute-score \
          --h5ad_file "${d_ss}/tabula_sapiens_${tissue}.h5ad" \
          --h5ad_species "human" \
          --gs_file "${d_scdrs_out}/${traits}.gs" \
          --gs_species "human" \
          --out_folder "${d_scdrs_out}/${tissue}"
    done
  done