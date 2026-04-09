#!/bin/bash
#SBATCH --time=24:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=64

d_software=$1
trait=$2
d_mashr=$3
d_spredixcan_out=$4
d_spredixcan_imputed=$5
d_smultixcan_out=$6

eval "$(conda shell.bash hook)"
conda activate imlabtools
export PYTHONNOUSERSITE=1
unset PYTHONPATH

python "${d_software}/MetaXcan/software/SMulTiXcan.py" \
  --models_folder "${d_mashr}" \
  --models_name_pattern "mashr_(.*).db" \
  --snp_covariance "${d_software}/MetaXcan/reference/data/models/gtex_v8_expression_mashr_snp_smultixcan_covariance.txt.gz" \
  --metaxcan_folder "${d_spredixcan_out}/${trait}/" \
  --metaxcan_filter "${trait}__PM__(.*).csv" \
  --metaxcan_file_name_parse_pattern "(.*)__PM__(.*).csv" \
  --gwas_file "${d_spredixcan_imputed}/${trait}_imputed_FULL.txt.gz" \
  --snp_column "panel_variant_id" \
  --effect_allele_column "effect_allele" \
  --non_effect_allele_column "non_effect_allele" \
  --zscore_column "zscore" \
  --keep_non_rsid \
  --model_db_snp_key "varID" \
  --cutoff_condition_number 30 \
  --verbosity 7 \
  --throw \
  --output "${d_smultixcan_out}/${trait}_ADDITIVE_smultixcan.txt"
