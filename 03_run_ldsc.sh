#!/bin/bash
# 03_run_ldsc.sh: set up all the tools needed (and some of the data)

# Load all variables and functions
  source "$(dirname "$0")/00_config.sh"
  
# Setup ldsc
  export OMP_NUM_THREADS=1
  export APPTAINER_BIND="${d_software}/ldsc/reference:/REF:ro,${d_ldsc_out}:${d_ldsc_out},${d_ss}:${d_ss}"
  export SIF="${d_software}/ldsc/containers"
  
  export MUNGE_COMMON_ARGS="--N-col N --p PVAL --signed-sumstats Z,0 --merge-alleles /REF/w_hm3.snplist"
  export LDSC_COMMON_ARGS="--ref-ld-chr /REF/eur_w_ld_chr/ --w-ld-chr /REF/eur_w_ld_chr/"
  
  export MUNGE="apptainer exec --home=${d_ss}:/home ${SIF}/ldsc.sif python2"
  export LDSC="apptainer exec --home=${d_ss}:/home ${SIF}/ldsc.sif python2"
  
# Prepare acne (teder)
  trait2="${arr_name[3]}"
  trait2_file="${arr_ss[3]}"
  file_2="$(basename "$trait2_file")"
  munge_2="${trait2}_munged"
  
  $MUNGE "/tools/ldsc/munge_sumstats.py" \
    "$MUNGE_COMMON_ARGS" \
    --sumstats "${d_ss}/${file_2}" \
    --out "${d_ss}/${munge_2}"
    
  mv "${d_ss}/${munge_2}.sumstats.gz" "${d_ss}/${munge_2}.sumstats"
  gzip "${d_ss}/${munge_2}.sumstats"

# Run ldsc: ibd/uc/cd <-> acne (teder)
  for i in $(seq 0 2) ; do
  
    trait1="${arr_name[$i]}"
    trait1_file="${arr_ss[$i]}"
    
    file_1="$(basename "$trait1_file")"
    munge_1="${trait1}_munged"

    $MUNGE "/tools/ldsc/munge_sumstats.py" \
      "$MUNGE_COMMON_ARGS" \
      --sumstats "${d_ss}/${file_1}" \
      --out "${d_ss}/${munge_1}"

    mv "${d_ss}/${munge_1}.sumstats.gz" "${d_ss}/${munge_1}.sumstats"
    gzip "${d_ss}/${munge_1}.sumstats"
    
    ctrait="${trait1}_${trait2}"
    
    $LDSC "/tools/ldsc/ldsc.py" \
      "$LDSC_COMMON_ARGS" \
      --rg "${d_ss}/${munge_1}.sumstats.gz,${d_ss}/${munge_2}.sumstats.gz" \
      --out "${d_ldsc_out}/${ctrait}"

  done
