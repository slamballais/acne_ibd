#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --time=24:00:00
#SBATCH --cpus-per-task=48

# args
d_software=$1
d_ss=$2
d_out=$3
gwas=$4
gwas_file=$5

file_1="$(basename "$gwas_file")"

export OMP_NUM_THREADS="$SLURM_CPUS_PER_TASK"
export APPTAINER_BIND="${d_software}/mixer/reference:/REF:ro,${d_out}:${d_out},${d_ss}:${d_ss}"
export SIF="${d_software}/mixer/singularity"
export MIXER_COMMON_ARGS="--ld-file /REF/ldsc/1000G_EUR_Phase3_plink/1000G.EUR.QC.@.run4.ld --bim-file /REF/ldsc/1000G_EUR_Phase3_plink/1000G.EUR.QC.@.bim"
export REP="rep${SLURM_ARRAY_TASK_ID}"
export EXTRACT="--extract /REF/ldsc/1000G_EUR_Phase3_plink/1000G.EUR.QC.prune_maf0p05_rand2M_r2p8.${REP}.snps"
export PYTHON="apptainer exec --home=${d_ss}:/home ${SIF}/mixer.sif python"

# run mixer
$PYTHON "/tools/mixer/precimed/mixer.py" fit1 \
  "$MIXER_COMMON_ARGS" \
  "$EXTRACT" \
  --trait1-file "${d_ss}/${file_1}" \
  --out "${d_out}/${gwas}.fit.${REP}"
  
$PYTHON "/tools/mixer/precimed/mixer.py" test1 \
  "$MIXER_COMMON_ARGS" \
  --trait1-file "${d_ss}/${gwas}.txt.gz" \
  --load-params-file "${d_out}/${gwas}.fit.${REP}" \
  --out "${d_out}/${gwas}.test.${REP}"
