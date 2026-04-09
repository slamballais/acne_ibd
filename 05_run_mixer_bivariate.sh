#!/bin/bash
# 05_run_mixer_bivariate.sh: run bivariate mixer on all cross-traits

# Load all variables and functions
  source "$(dirname "$0")/00_config.sh"

# Run MiXeR

  for i in $(seq 0 2) ; do
  
    temp_name="mixer_2_${arr_name[$i]}_${arr_name[3]}"

    sbatch \
      --job-name="$temp_name" \
      --output="${d_logs}/%x.out" \
      --array=1-20 \
      "${d_scripts}/mixer_2_docker.sh" \
        "$d_software" \
        "$d_ss" \
        "$d_mixer_out" \
        "${arr_name[$i]}" \
        "${arr_ss[$i]}" \
        "${arr_name[3]}" \
        "${arr_ss[3]}"
  done
