#!/bin/bash
# 11_spredixcan_ss_harmonization.sh

# Load all variables and functions
  source "$(dirname "$0")/00_config.sh"
  
# Load right env
  module purge
  module load Miniconda3/24.7.1
  
  conda init
  eval "$(conda shell.bash hook)"
  conda activate imlabtools2
  
# Run harmonization
  for trait in ibd uc cd acne ; do
      
      case "$trait" in
        ibd)
          p_in="$p_ibd_clean"
          p_out="${d_spredixcan_harmonized}/${trait}.txt.gz"
          n_sample=368819
          n_cases=30713
          ;;
        uc)
          p_in="$p_uc_clean"
          p_out="${d_spredixcan_harmonized}/${trait}.txt.gz"
          n_sample=353190
          n_cases=16390
          ;;
        cd)
          p_in="$p_cd_clean"
          p_out="${d_spredixcan_harmonized}/${trait}.txt.gz"
          n_sample=344764
          n_cases=13501
          ;;
        acne)
          p_in="$p_teder_clean"
          p_out="${d_spredixcan_harmonized}/${trait}.txt.gz"
          n_sample=399413
          n_cases=34422
          ;;
      esac
    
      sbatch \
        --job-name="harmonize_${trait}" \
        --output="${d_logs}/%x.out" \
        "${d_scripts}/spredixcan_harmonization.sh" \
        "$d_software" \
        "$p_in" \
        "$p_out" \
        "$n_sample" \
        "$n_cases"
        
  done