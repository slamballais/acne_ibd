## Before running

* The code in this repository has been modified after analysis to improve readability and remove sensitive information. This may have led to typos.
* The code requires slurm, R, miniforge3, and more. Please carefully review the scripts first.
* Ensure your `00_config.sh` (or main script) points to the right paths on your system before executing the pipeline!

## Manual FUMA

Script 09 requires manual running of FUMA.

## Manual Data Downloads

Before running the pipeline, you need to manually download a few required datasets that cannot be fetched automatically via the command line. 

Please download the files below and place them in their respective directories within your project workspace.

### 1. IBD / UC / CD Summary Statistics
The raw GWAS summary statistics for Inflammatory Bowel Disease (IBD), Ulcerative Colitis (UC), and Crohn's Disease (CD) must be downloaded from the consortium's Google Drive.
* **Link:** [IBD Meta-Analysis Google Drive](https://drive.google.com/drive/folders/1MbjKuYp77SQEb1Q06nQG2Asq7gt6kGLO)
* **Action:** Download the following three files:
  * `ibd_EAS_EUR_SiKJEF_meta_IBD.TBL.txt.gz`
  * `ibd_EAS_EUR_SiKJEF_meta_UC.TBL.txt.gz`
  * `ibd_EAS_EUR_SiKJEF_meta_CD.TBL.txt.gz`
* **Destination:** Place all three files into your `$d_ss` directory.

### 2. TWAS Inflation-Corrected Models (PredictDB)
The S-Predixcan steps require the updated inflation-corrected models.
* **Link:** [PredictDB: TWAS Inflation-Corrected Models (Nov 2024)](https://predictdb.org/post/2024/11/11/twas-inflation-corrected-models/)
* **Action:** Download the Elastic Net zip archive (`elastic-net-with-phi.zip`)
* **Destination:** Place the `.zip` file directly into your `${d_software}/MetaXcan/` directory. *(Note: The pipeline script will handle the unzipping).*
