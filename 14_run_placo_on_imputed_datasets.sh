#!/bin/bash
# 14_run_placo_on_imputed_datasets.sh: to get spredixcan to work properly, we need to rerun placo on all (imputed) variants

# Load all variables and functions
  source "$(dirname "$0")/00_config.sh"
  
# Load right env
  module purge
  module load Miniconda3/24.7.1
  
  conda activate imlabtools
  export PYTHONNOUSERSITE=1
  unset PYTHONPATH
  module load R/4.4.2
  
# Run placo
  for trait in ibd uc cd ; do
    sbatch_r "spredixcan_placo_${trait}" \
      Rscript "${d_scripts}/run_placo_for_spredixcan.R" \
        --d_scripts "$d_scripts" \
        --in1 "${d_spredixcan_imputed}/acne_imputed_FULL.txt.gz" \
        --in2 "${d_spredixcan_imputed}/${trait}_imputed_FULL.txt.gz" \
        --out1 "${d_spredixcan_imputed}/acne_${trait}_concordant_imputed_FULL.txt.gz" \
        --out2 "${d_spredixcan_imputed}/acne_${trait}_discordant_imputed_FULL.txt.gz" \
        --n_cores 16
  done