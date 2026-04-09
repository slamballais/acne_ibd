#!/bin/bash
# 16_process_multixcan.sh

# Load all variables and functions
  source "$(dirname "$0")/00_config.sh"
  
# Load R
  module purge
  module load R/4.4.2
  
# Process
  Rscript "${d_scripts}/process_smultixcan.R" \
    --d_spredixcan_out "$d_spredixcan_out" \
    --d_smultixcan_out "$d_smultixcan_out" \
    --p_out "${d_output}/smultixcan_tables.xlsx"
