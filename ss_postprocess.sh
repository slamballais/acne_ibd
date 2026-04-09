#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --time=24:00:00

trait=$1
d_software=$2

module purge
module load Miniconda3/24.7.1

eval "$(conda shell.bash hook)"
conda activate imlabtools2
export PYTHONNOUSERSITE=1
unset PYTHONPATH

gwas_file="${d_software}/MetaXcan/harmonized_gwas/${trait}.txt.gz"
input_folder="${d_software}/MetaXcan/imputed_gwas/${trait}"
output_file="${d_software}/MetaXcan/imputed_gwas/${trait}_imputed_FULL.txt.gz"

python "${d_software}/summary-gwas-imputation/src/gwas_summary_imputation_postprocess.py" \
-gwas_file "$gwas_file" \
-folder "$input_folder" \
-pattern "${trait}_imputed_chr.*" \
-parsimony 7 \
-output "${output_file}"
