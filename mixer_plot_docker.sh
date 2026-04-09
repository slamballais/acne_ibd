#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --time=1-00:00:00
#SBATCH --cpus-per-task=32

# args
d_software=$1
d_out=$2
n=$3
trait1=$4
trait2=$5

export OMP_NUM_THREADS="$SLURM_CPUS_PER_TASK"
export SIF="${d_software}/mixer/singularity"
export PYTHON="apptainer exec --home=${d_out}:/home ${SIF}/mixer.sif python"

# combine jsons
$PYTHON "/tools/mixer/precimed/mixer_figures.py" combine \
  --json "/home/${n}.fit.rep@.json" \
  --out "/home/${n}.fit"
  
$PYTHON "/tools/mixer/precimed/mixer_figures.py" combine \
  --json "/home/${n}.test.rep@.json" \
  --out "/home/${n}.test"

# make plot
$PYTHON "/tools/mixer/precimed/mixer_figures.py" two \
  --json-fit "/home/${n}.fit.json" \
  --json-test "/home/${n}.test.json" \
  --trait1 "$trait1" \
  --trait2 "$trait2" \
  --statistic mean std \
  --out "/home/${n}"