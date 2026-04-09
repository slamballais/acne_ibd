#!/bin/bash
# 01_setup.sh: set up all the tools needed (and some of the data)

# Load all variables and functions
  source "$(dirname "$0")/00_config.sh"

# Load R
  module purge
  module load R/4.4.2

# Create directories
  mkdir -p "$d_ss" "$d_figures" "$d_mixer" \
    "$d_ref" "$d_logs" "$d_output" \
    "$d_ldsc_out" "$d_mixer_out" \
    "$d_snp2gene" "$d_gene2func" \
    "$d_spredixcan_out" "$d_smultixcan_out" "$d_scdrs_out"

## Install/download R packages if needed
  Rscript "${d_scripts}/setup_r_packages.R"

  wget "https://github.com/RayDebashree/PLACO/blob/master/PLACO_v0.1.1.R?raw=TRUE" \
    -O "${d_scripts}/PLACO.R"

## Set up git lfs / ldsc / mixer / python convert
  wget "https://github.com/git-lfs/git-lfs/releases/download/v3.6.1/git-lfs-linux-amd64-v3.6.1.tar.gz" \
    -O "${d_software}/git-lfs-linux-amd64-v3.6.1.tar.gz"
  
  tar xzf "${d_software}/git-lfs-linux-amd64-v3.6.1.tar.gz" -C "$d_software"
  "${d_software}/git-lfs-3.6.1/install.sh" --local
  PATH="$PATH:${d_software}/git-lfs-3.6.1/"
  
  git clone --depth 1 "https://github.com/comorment/mixer.git" "${d_software}/mixer"
  cd "${d_software}/mixer"
  git-lfs pull
  
  git clone https://github.com/comorment/ldsc.git "${d_software}/ldsc"
  cd "${d_software}/ldsc"
  git-lfs pull

# Get reference file from PleioFDR
  wget "https://precimed.s3-eu-west-1.amazonaws.com/pleiofdr/9545380.ref" \
    -O "${d_ref}/9545380.ref"
    
# S-predixcan / s-multixcan

  git clone "https://github.com/hakyimlab/MetaXcan.git" "${d_software}/MetaXcan"
  git clone "https://github.com/hakyimlab/summary-gwas-imputation.git" "${d_software}/summary-gwas-imputation"
  
  conda env create -f "${d_software}/MetaXcan/software/conda_env.yaml"
  conda env create -f "${d_software}/summary-gwas-imputation/src/conda_env.yaml" -n "imlabtools2"

  # download : https://predictdb.org/post/2024/11/11/twas-inflation-corrected-models/
  # put in: ${d_software}/MetaXcan
  unzip "${d_software}/MetaXcan/elastic-net-with-phi.zip"
  
  pip install zenodo-get
  mkdir -p "${d_software}/MetaXcan/reference"
  temp_cd_dir="$(pwd)"
  cd "${d_software}/MetaXcan/reference"
  zenodo_get 3657902
  tar -xvf "sample_data.tar"
  cd "$temp_cd_dir"
  
# scDRS

  conda create -n scdrs_env python=3.9 -y
  conda activate scdrs_env
  pip install scdrs==1.0.2
  pip install pandas scanpy
  conda deactivate

  wget "https://datasets.cellxgene.cziscience.com/b225ee37-5e06-4e49-9c25-c3d7b5008dab.h5ad" \
    -O "${d_ss}/tabula_sapiens_blood.h5ad"
    
  wget "https://datasets.cellxgene.cziscience.com/d1966cc6-4082-43ec-a633-72e56f7c8a9a.h5ad" \
    -O "${d_ss}/tabula_sapiens_spleen.h5ad"
    
# Get the GWAS summary statistics

  # AV
  wget_teder="http://ftp.ebi.ac.uk/pub/databases/gwas/summary_statistics/GCST90245001-GCST90246000/GCST90245818/GCST90245818_buildGRCh37.tsv"
  wget -P "$d_ss" "$wget_teder" --no-check-certificate
  gzip -cf "${d_ss}/GCST90245818_buildGRCh37.tsv" > "$p_teder_raw"
  rm "${d_ss}/GCST90245818_buildGRCh37.tsv"

  # IBD/UC/CD
  # Download from https://drive.google.com/drive/folders/1MbjKuYp77SQEb1Q06nQG2Asq7gt6kGLO
  # put in: $d_ss
  mv "${d_ss}/ibd_EAS_EUR_SiKJEF_meta_IBD.TBL.txt.gz" "$p_ibd_raw"
  mv "${d_ss}/ibd_EAS_EUR_SiKJEF_meta_CD.TBL.txt.gz" "$p_uc_raw"
  mv "${d_ss}/ibd_EAS_EUR_SiKJEF_meta_UC.TBL.txt.gz" "$p_cd_raw"
    
    
    
    
    
