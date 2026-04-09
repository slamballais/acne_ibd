#!/bin/bash
# 02_prepare_gwas_data.sh: download, organize, and align the summary statistics

# Load all variables and functions
  source "$(dirname "$0")/00_config.sh"
  
# Load R
  module purge
  module load R/4.4.2

# Clean AV
  sbatch_r "clean_acne" \
    Rscript "${d_scripts}/clean_ss_teder.R" \
      "$p_teder_raw" "$p_teder_temp" \
      "364991" "34422" \
      "${d_ref}/9545380.ref"

# Clean IBD/UC/CD
  sbatch_r "clean_ibd" \
    Rscript "${d_scripts}/clean_ss_ibd.R" \
      "$p_ibd_raw" "$p_ibd_temp" \
      "34915" "25042" "303191" "5671" \
      "${d_ref}/9545380.ref"
    
  sbatch_r "clean_uc" \
    Rscript "${d_scripts}/clean_ss_ibd.R" \
      "$p_uc_raw" "$p_uc_temp" \
      "28072" "12194" "303191" "1307" \
      "${d_ref}/9545380.ref"
  
  sbatch_r "clean_cd" \
    Rscript "${d_scripts}/clean_ss_ibd.R" \
      "$p_cd_raw" "$p_cd_temp" \
      "33609" "12366" "303191" "4024" \
      "${d_ref}/9545380.ref"

# Align all summary statistics
  sbatch_r "align" \
    Rscript "${d_scripts}/align_ss.R" \
      "$p_ibd_temp" "$p_ibd_clean" \
      "$p_uc_temp" "$p_uc_clean" \
      "$p_cd_temp" "$p_cd_clean" \
      "$p_teder_temp" "$p_teder_clean"
    
  rm "$p_ibd_temp" "$p_uc_temp" "$p_cd_temp" "$p_teder_temp"
