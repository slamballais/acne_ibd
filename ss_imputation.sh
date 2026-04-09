#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --time=24:00:00
#SBATCH --cpus-per-task=48

trait=$1
d_software=$2
gwas_file=$3
output_dir=$4
data_dir=$5

module purge
module load Miniconda3/24.7.1

eval "$(conda shell.bash hook)"
conda activate imlabtools2
export PYTHONNOUSERSITE=1
unset PYTHONPATH

chr="$SLURM_ARRAY_TASK_ID"

mkdir -p "$output_dir"

for batch in {0..9}; do  
    python "${d_software}/summary-gwas-imputation/src/gwas_summary_imputation.py" \
    -by_region_file "${data_dir}/eur_ld.bed.gz" \
    -gwas_file "${gwas_file}" \
    -parquet_genotype "${data_dir}/reference_panel_1000G/chr${chr}.variants.parquet" \
    -parquet_genotype_metadata "${data_dir}/reference_panel_1000G/variant_metadata.parquet" \
    -window 100000 \
    -parsimony 7 \
    -chromosome "$chr" \
    -regularization 0.1 \
    -frequency_filter 0.01 \
    -sub_batches 10 \
    -sub_batch "$batch" \
    --standardise_dosages \
    -output "${output_dir}/${trait}_imputed_chr${chr}_sb${batch}.txt.gz"
done
