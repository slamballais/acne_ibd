#!/usr/bin/env Rscript
# process_smultixcan.R: Get all the numbers and tables for s-multixcan

# Arguments
  library(optparse)
  option_list <- list(
    make_option("--d_spredixcan_out", type = "character", help = "path to spredixcan output"),
    make_option("--d_smultixcan_out", type = "character", help = "path to smultixcan output"),
    make_option("--p_out", type = "character", help = "path to output .xlsx")
  )
  opt <- parse_args(OptionParser(option_list = option_list))
  attach(opt)

# Packages
  library(data.table)
  library(magrittr)
  library(openxlsx)
  setDTthreads(2)
  
# Functions
  addSheetWithData <- function(wb, df, sheetName) {
    openxlsx::addWorksheet(wb, sheetName)
    openxlsx::writeData(wb, sheetName, df)
  }
    
# Init
  names_acne <- c("acne_ibd", "acne_uc", "acne_cd")
  names_analyses <- apply(expand.grid(names_acne, c("concordant", "discordant")), 1, paste, collapse = "_")
  
  # s-predixcan
  d_spx <- file.path(d_spredixcan_out, names_analyses)
  p_spx <- lapply(d_spx, function(x) list.files(x, full.names = TRUE))
  spx_tissues <- sub(".*__PM__(.*).csv", "\\1", p_spx[[1]]) %>%
    tolower()

  # s-multixcan
  smx_files <- paste0(names_analyses, "_ADDITIVE_smultixcan.txt")
  p_smx <- file.path(d_smultixcan_out, smx_files)
  smx <- lapply(p_smx, fread)
  
# Process

  # get all spredixcan tissue p-values for the smx genes
  spx_res <- lapply(seq_along(smx), function(i) {
    out <- data.frame(gene = smx[[i]]$gene_name)
    lapply(seq_along(p_spx[[i]]), function(j) {
      temp <- fread(p_spx[[i]][[j]])
      temp$pvalue[match(out$gene, temp$gene_name)]
    }) %>%
      do.call("cbind", .) %>%
      as.data.frame %>%
      `names<-`(spx_tissues) %>%
      cbind(out, .)
  })
  
  # get all spredixcan tissue z-scores for the smx genes
  spx_res_z <- lapply(seq_along(smx), function(i) {
    out <- data.frame(gene = smx[[i]]$gene_name)
    lapply(seq_along(p_spx[[i]]), function(j) {
      temp <- fread(p_spx[[i]][[j]])
      temp$zscore[match(out$gene, temp$gene_name)]
    }) %>%
      do.call("cbind", .) %>%
      as.data.frame %>%
      `names<-`(spx_tissues) %>%
      cbind(out, .)
  })
  
  # number of statistically significant genes
  sum(smx[[1]]$pvalue < 1.25E-6, na.rm = TRUE) # ibd concordant: 41
  sum(smx[[4]]$pvalue < 1.25E-6, na.rm = TRUE) # ibd discordant: 14
  
  sum(smx[[2]]$pvalue < 1.25E-6, na.rm = TRUE) # uc concordant: 30
  sum(smx[[5]]$pvalue < 1.25E-6, na.rm = TRUE) # uc discordant: 18

  sum(smx[[3]]$pvalue < 1.25E-6, na.rm = TRUE) # cd concordant: 34
  sum(smx[[6]]$pvalue < 1.25E-6, na.rm = TRUE) # cd discordant: 8
  
  # number of concordant (ibd, uc, cd) and discordant genes (ibd, uc, cd) in all three tissue classes
  for (i in 1:6) {
    test <- subset(spx_res[[i]], gene %in% with(smx[[i]], gene_name[which(pvalue < 1.25E-6)]))
    i1 <- which(test$skin_not_sun_exposed_suprapubic < 1.25E-6 | test$skin_sun_exposed_lower_leg < 1.25E-6) %T>% {print(length(.))}
    i2 <- which(test$colon_sigmoid < 1.25E-6 | test$colon_transverse < 1.25E-6 | test$small_intestine_terminal_ileum < 1.25E-6 ) %T>% {print(length(.))}
    i3 <- which(test$spleen < 1.25E-6 | test$`cells_ebv-transformed_lymphocytes` < 1.25E-6 | test$whole_blood < 1.25E-6 | test$lung < 1.25E-6) %T>% {print(length(.))}
    print(test$gene[intersect(i1, intersect(i2, i3))])
  }
    
# Save results to .xlsx
  wb <- openxlsx::createWorkbook()
  addSheetWithData(wb, subset(smx[[1]], pvalue < 1.25E-6), "av-ibd concordant")
  addSheetWithData(wb, subset(smx[[4]], pvalue < 1.25E-6), "av-ibd discordant")
  addSheetWithData(wb, subset(smx[[2]], pvalue < 1.25E-6), "av-uc concordant")
  addSheetWithData(wb, subset(smx[[5]], pvalue < 1.25E-6), "av-uc discordant")
  addSheetWithData(wb, subset(smx[[3]], pvalue < 1.25E-6), "av-cd concordant")
  addSheetWithData(wb, subset(smx[[6]], pvalue < 1.25E-6), "av-cd discordant")
  openxlsx::saveWorkbook(wb, p_out, overwrite = TRUE)
