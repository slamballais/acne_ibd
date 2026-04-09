#!/bin/bash
# 00_config.sh: configuration for the rest of the pipeline

#### MODIFY THIS PART
wd="/project/acne" # working directory for whole project
d_scripts="${wd}/scripts" # contains all the scripts
d_software="${wd}/software" # needed for the apptainer containers

#### DO NOT MODIFY FROM HERE
    
## Main paths
d_ss="${wd}/summary_stats"
d_figures="${wd}/figures"
d_mixer="${wd}/mixer"
d_ref="${wd}/ref"
d_logs="${wd}/logs"
d_output="${wd}/output"
d_ldsc_out="${d_output}/ldsc"
d_mixer_out="${d_output}/mixer"
d_snp2gene="${wd}/snp2gene"
d_gene2func="${wd}/gene2func"
d_spredixcan_out="${d_output}/metaxcan"
d_smultixcan_out="${d_output}/smultixcan"
d_scdrs_out="${d_output}/scdrs"

d_spredixcan_harmonized="${d_software}/MetaXcan/harmonized_gwas"
d_spredixcan_imputed="${d_software}/MetaXcan/imputed_gwas"
d_spredixcan_ref="${d_software}/MetaXcan/reference/data"
d_mashr="${d_software}/MetaXcan/reference/data/models/eqtl/mashr"

## Set a bunch of names (raw names, clean names)
p_ibd_raw="${d_ss}/ibd_hg19_raw.txt.gz"
p_uc_raw="${d_ss}/uc_hg19_raw.txt.gz"
p_cd_raw="${d_ss}/cd_hg19_raw.txt.gz"
p_teder_raw="${d_ss}/teder_hg19_raw.txt.gz"

ibd_gwas="ibd_clean"
uc_gwas="uc_clean"
cd_gwas="cd_clean"
teder_gwas="teder_clean"
arr_name=("$ibd_gwas" "$uc_gwas" "$cd_gwas" "$teder_gwas")

p_ibd_temp="${d_ss}/${ibd_gwas}_temp.txt.gz"
p_uc_temp="${d_ss}/${uc_gwas}_temp.txt.gz"
p_cd_temp="${d_ss}/${cd_gwas}_temp.txt.gz"
p_teder_temp="${d_ss}/${teder_gwas}_temp.txt.gz"

p_ibd_clean="${d_ss}/${ibd_gwas}.txt.gz"
p_uc_clean="${d_ss}/${uc_gwas}.txt.gz"
p_cd_clean="${d_ss}/${cd_gwas}.txt.gz"
p_teder_clean="${d_ss}/${teder_gwas}.txt.gz"
arr_ss=("$p_ibd_clean" "$p_uc_clean" "$p_cd_clean" "$p_teder_clean")

# snp2gene/gene2func
snp2gene_prefix="snp2gene_"
gene2func_prefix="gene2func_"

## Alias
sbatch_r() {
    local name="$1"
    shift
    sbatch \
      --time=24:00:00 \
      --cpus-per-task=64 \
      --output="${d_logs}/%x.out" \
      --job-name="$name" \
      --wrap="$*"
}

sbatch_conda() {

    local name="$1"
    local cpus="$2"
    local mem="$3"
    shift 3
    local wrap_cmd="source \$(conda info --base)/etc/profile.d/conda.sh && conda activate scdrs_env && $*"

    sbatch \
      --time=24:00:00 \
      --cpus-per-task="$cpus" \
      --mem-per-cpu="$mem" \
      --output="${d_logs}/%x.out" \
      --job-name="$name" \
      --wrap="$wrap_cmd"
}
