#!/bin/bash
# 07_run_placo.sh: run placo on the cleaned summary statistics

# Load all variables and functions
  source "$(dirname "$0")/00_config.sh"
  
# Load R
  module purge
  module load R/4.4.2
  
# run placo
  sbatch_r "placo_all" \
    Rscript "${d_scripts}/run_placo.R" \
      --d_scripts "$d_scripts" \
      --ibd_path "$p_ibd_clean" \
      --uc_path "$p_uc_clean" \
      --cd_path "$p_cd_clean" \
      --acne_path "$p_teder_clean" \
      --p_out_rds "${d_output}/placo.rds" \
      --p_out_gz "${d_output}/placo.tsv.gz" \
      --n_cores 32
