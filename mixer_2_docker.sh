#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --time=24:00:00
#SBATCH --cpus-per-task=48

# args
d_software=$1
d_ss=$2
d_out=$3
trait1=$4
trait1_file=$5
trait2=$6
trait2_file=$7

file_1="$(basename "$trait1_file")"
file_2="$(basename "$trait2_file")"
ctrait="${trait1}_${trait2}"

export OMP_NUM_THREADS="$SLURM_CPUS_PER_TASK"
export APPTAINER_BIND="${d_software}/mixer/reference:/REF:ro,${d_out}:${d_out},${d_ss}:${d_ss}"
export SIF="${d_software}/mixer/singularity"
export MIXER_COMMON_ARGS="--ld-file /REF/ldsc/1000G_EUR_Phase3_plink/1000G.EUR.QC.@.run4.ld --bim-file /REF/ldsc/1000G_EUR_Phase3_plink/1000G.EUR.QC.@.bim"
export REP="rep${SLURM_ARRAY_TASK_ID}"
export EXTRACT="--extract /REF/ldsc/1000G_EUR_Phase3_plink/1000G.EUR.QC.prune_maf0p05_rand2M_r2p8.${REP}.snps"
export PYTHON="apptainer exec --home=${d_ss}:/home ${SIF}/mixer.sif python"

$PYTHON "/tools/mixer/precimed/mixer.py" fit2 \
  "$MIXER_COMMON_ARGS" \
  "$EXTRACT" \
  --trait1-file "${d_ss}/${file_1}" \
  --trait2-file "${d_ss}/${file_2}" \
  --trait1-params-file "${d_out}/${trait1}.fit.${REP}.json" \
  --trait2-params-file "${d_out}/${trait2}.fit.${REP}.json" \
  --out "${d_out}/${ctrait}.fit.${REP}"

$PYTHON "/tools/mixer/precimed/mixer.py" test2 \
  "$MIXER_COMMON_ARGS" \
  --trait1-file "${d_ss}/${file_1}" \
  --trait2-file "${d_ss}/${file_2}" \
  --load-params-file "${d_out}/${ctrait}.fit.${REP}.json" \
  --out "${d_out}/${ctrait}.test.${REP}"
