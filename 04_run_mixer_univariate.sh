#!/bin/bash
# 04_run_mixer_univariate.sh: run univariate mixer on all traits

# Load all variables and functions
  source "$(dirname "$0")/00_config.sh"

# Run MiXeR

  for i in $(seq 0 3) ; do
  
    temp_name="mixer_1_${arr_name[$i]}"
  
    sbatch \
      --job-name="${temp_name}" \
      --output="${d_logs}/%x.out" \
      --array=1-20 \
      "${d_scripts}/mixer_1_docker.sh" \
        "$d_software" \
        "$d_ss" \
        "$d_mixer_out" \
        "${arr_name[$i]}" \
        "${arr_ss[$i]}"
  done