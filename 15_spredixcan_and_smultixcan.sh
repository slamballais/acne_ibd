#!/bin/bash
# 15_spredixcan_and_smultixcan.sh

# Load all variables and functions
  source "$(dirname "$0")/00_config.sh"
  
# Load right env
  module purge
  module load Miniconda3/24.7.1
  
  conda activate imlabtools
  export PYTHONNOUSERSITE=1
  unset PYTHONPATH

# Run
  for trait in ibd uc cd ; do
    for direction in concordant discordant ; do
    
      combined_trait="acne_${trait}_${direction}"

      # s-predixcan
      for db_file in "${d_mashr}"/*.db; do
      
        db_filename="$(basename "$db_file")"
        db_base="${db_filename%.db}"
        tissue_name="${db_base#mashr_}"
        cov_file="${db_file%.db}.txt.gz"
        
        mkdir -p "${d_spredixcan_out}/${combined_trait}"
        out_file="${d_spredixcan_out}/${combined_trait}/${combined_trait}__PM__${tissue_name}.csv"
  
        python "${d_software}/MetaXcan/software/SPrediXcan.py" \
          --gwas_file "${d_spredixcan_imputed}/${combined_trait}_imputed_FULL.txt.gz" \
          --snp_column "panel_variant_id" \
          --effect_allele_column "effect_allele" \
          --non_effect_allele_column "non_effect_allele" \
          --zscore_column "zscore" \
          --model_db_path "$db_file" \
          --covariance "$cov_file" \
          --keep_non_rsid \
          --additional_output \
          --model_db_snp_key "varID" \
          --throw \
          --output_file "$out_file"
        
      done
      
      # s-multixcan
      sbatch \
        --job-name="smultixcan_${combined_trait}" \
        "${d_scripts}/smultixcan.sh" \
          "$d_software" \
          "$combined_trait" \
          "$d_mashr" \
          "$d_spredixcan_out" \
          "$d_spredixcan_imputed" \
          "$d_smultixcan_out"
  
    done
  done