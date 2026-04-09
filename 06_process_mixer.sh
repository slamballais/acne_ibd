#!/bin/bash
# 06_process_mixer.sh: take the mixer results and make the figures

## NOTE: THIS REQUIRES THE USER TO RUN PART OF IT BY HAND!

# Load all variables and functions
  source "$(dirname "$0")/00_config.sh"
  
# Load R
  module purge
  module load R/4.4.2
  module load ImageMagick/7.1.1

# Init
  ctrait1="${ibd_gwas}_${teder_gwas}"
  ctrait2="${uc_gwas}_${teder_gwas}"
  ctrait3="${cd_gwas}_${teder_gwas}"
  
  combined=("$ctrait1" "$ctrait2" "$ctrait3")
  trait_first=("IBD" "UC" "CD")
  trait_second=("ACNE" "ACNE" "ACNE")
  
  for i in $(seq 0 $((${#combined[@]}-1))) ; do
    sbatch \
      --job-name="mixer-plot" \
      --output="${d_logs}/%x.out" \
      "${d_scripts}/mixer_plot_docker.sh" \
        "$d_software" \
        "$d_mixer_out" \
        "${combined[$i]}" \
        "${trait_first[$i]}" \
        "${trait_second[$i]}"
  done
  
# Extract
  Rscript "${d_scripts}/extract_mixer.R" \
    "${d_mixer_out}/${teder_gwas}_combined.tsv" \
    "${d_mixer_out}/${ctrait1}.test.json" \
    "${d_mixer_out}/${ctrait2}.test.json" \
    "${d_mixer_out}/${ctrait3}.test.json"
    
##### MANUALLY RUN eulerr_input.R via https://eulerr.co/ and store images in /figures 
##### MANUALLY RUN eulerr_input.R via https://eulerr.co/ and store images in /figures
##### MANUALLY RUN eulerr_input.R via https://eulerr.co/ and store images in /figures
##### MANUALLY RUN eulerr_input.R via https://eulerr.co/ and store images in /figures

# color: #FEC982,#77B4D4
# pointsize: 15
# show quantities: check
# size: 6x4 inch
# save plot as png

# Plot
  Rscript "${d_scripts}/make_fig2.R" \
    --p_acne_ibd "${d_figures}/jid_acne_ibd.png" \
    --p_acne_cd "${d_figures}/jid_acne_cd.png" \
    --p_acne_uc "${d_figures}/jid_acne_uc.png" \
    --p_out "${d_figures}/figure_2.png"
