#### Instructions:
# Go to https://fuma.ctglab.nl and start a SNP2GENE job
# Put for Chromosome: CHR
# Put for Position: BP  
# Put for rsID: SNP
# Put for p-value columns: placo_teder_ibd (IBD), placo_teder_uc (UC), placo_teder_cd (CD)
# Put for sample sizes: 
  # IBD: 237713 [16/(1 / 338106 + 1 / 30713 + 1 / 364991 + 1 / 34422)]
  # UC:  167062 [16/(1 / 336800 + 1 / 16390 + 1 / 364991 + 1 / 34422)]
  # CD:  146953 [16/(1 / 331263 + 1 / 13501 + 1 / 364991 + 1 / 34422)]
# Enable eQTL mapping (GTEx v8) and chromatin mapping
# Once the jobs are done, go to the 3 jobs and press "Download" and "Download files"
# Rename the files to "snp2gene_teder_ibd.zip", "snp2gene_teder_uc.zip", and "snp2gene_teder_cd.zip"
# Put them in $d_snp2gene
# Move to gene2func, do the same, but call them "gene2func_teder_*.zip" and put them in $d_gene2func