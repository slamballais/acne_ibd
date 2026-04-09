#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --time=24:00:00
#SBATCH --cpus-per-task=48

d_software=$1
p_in=$2
p_out=$3
n_sample=$4
n_cases=$5

module purge
module load Miniconda3/24.7.1
  
conda init
eval "$(conda shell.bash hook)"
conda activate imlabtools2

python "${d_software}/summary-gwas-imputation/src/gwas_parsing.py" \
  -gwas_file "$p_in" \
  -liftover "${d_software}/MetaXcan/reference/data/liftover/hg19ToHg38.over.chain.gz" \
  -snp_reference_metadata "${d_software}/MetaXcan/software/variant_metadata.txt.gz" METADATA \
  -output_column_map SNP "variant_id" \
  -output_column_map A1 "non_effect_allele" \
  -output_column_map A2 "effect_allele" \
  -output_column_map BETA "effect_size" \
  -output_column_map SE "standard_error" \
  -output_column_map Z "zscore" \
  -output_column_map PVAL "pvalue" \
  -output_column_map AF "frequency" \
  -output_column_map CHR "chromosome" \
  -output_column_map BP "position" \
  --chromosome_format \
  --insert_value sample_size "$n_sample" --insert_value n_cases "$n_cases" \
  -output_order variant_id panel_variant_id chromosome position effect_allele non_effect_allele \
    frequency pvalue zscore effect_size standard_error sample_size n_cases \
  -output "$p_out"