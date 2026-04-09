#!/bin/bash
# 20_scdrs_process.sh

# Load all variables and functions
  source "$(dirname "$0")/00_config.sh"
  
# Load right env
  module purge
  module load Miniconda3/24.7.1
  module load R/4.4.2
  
# Run
  Rscript "${d_scripts}/scdrs_process_downstream.R" \
    "${d_scdrs_out}/blood/acne_ibd.scdrs_group.cell_type" \
    "${d_scdrs_out}/blood/acne_cd.scdrs_group.cell_type" \
    "${d_scdrs_out}/blood/acne_uc.scdrs_group.cell_type" \
    "${d_scdrs_out}/spleen/acne_ibd.scdrs_group.cell_type" \
    "${d_scdrs_out}/spleen/acne_cd.scdrs_group.cell_type" \
    "${d_scdrs_out}/spleen/acne_uc.scdrs_group.cell_type" \
    "${d_scdrs_out}/all_results.xlsx"
    
  # make umap
  for tissue in blood spleen ; do
    sbatch_conda "scdrs_plot_${tissue}" 16 "6gb" \
      python "${d_scripts}/scdrs_umap.py" \
        --tissue "${tissue}" \
        --atlas "${d_ss}/tabula_sapiens_${tissue}.h5ad" \
        --score_ibd "${d_scdrs_out}/${tissue}/acne_ibd.full_score.gz" \
        --score_cd "${d_scdrs_out}/${tissue}/acne_cd.full_score.gz" \
        --score_uc "${d_scdrs_out}/${tissue}/acne_uc.full_score.gz" \
        --out "${d_scdrs_out}/${tissue}/composite_umap_${tissue}.png"
  done
  
  