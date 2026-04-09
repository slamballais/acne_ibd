#!/bin/bash
# 13_spredixcan_merge_ss_imputation.sh

# Load all variables and functions
  source "$(dirname "$0")/00_config.sh"
  
# Load right env
  module purge
  module load Miniconda3/24.7.1
  
  conda init
  eval "$(conda shell.bash hook)"
  conda activate imlabtools2
  
# Merge imputed summary stats
  for trait in ibd uc cd acne ; do
    sbatch \
      --parsable \
      --job-name="postprocess_${trait}" \
      --output="${d_logs}/%x.out" \
      "${d_scripts}/ss_postprocess.sh" \
        "$trait" \
        "$d_software" \
        "${d_spredixcan_harmonized}/${trait}.txt.gz" \
        "${d_spredixcan_imputed}/${trait}" \
        "${d_spredixcan_imputed}/${trait}_imputed_FULL.txt.gz"
  done
