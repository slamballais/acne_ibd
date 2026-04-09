#!/bin/bash
# 08_process_placo.sh: process placo results and create figure 3

# Load all variables and functions
  source "$(dirname "$0")/00_config.sh"
  
# Load R
  module purge
  module load R/4.4.2
  
# process placo
  Rscript "${d_scripts}/report_ss.R" \
    --col_acne_ibd "placo_acne_ibd" \
    --col_acne_uc "placo_acne_uc" \
    --col_acne_cd "placo_acne_cd" \
    --rds_path "${d_output}/placo.rds" \
    --out_path "${d_output}/placo_numbers.rds"
    
  sbatch_r "plot_fig3" \
    Rscript "${d_scripts}/make_fig3.R" \
      --p_placo "${d_output}/placo.rds" \
      --p_out "${d_figures}/figure_3.png"