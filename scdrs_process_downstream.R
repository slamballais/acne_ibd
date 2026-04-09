#!/usr/bin/env Rscript
# scdrs_process_downstream: Prepare the scDRS results for suppl tables

# Packages
  library(data.table)
  library(openxlsx)
  setDTthreads(4)

# Arguments
  args <- commandArgs(trailingOnly = TRUE)
  excel_out <- args[7]

# Functions
  addSheetWithData <- function(wb, df, sheetName) {
    addWorksheet(wb, sheetName)
    writeData(wb, sheetName, df)
  }
  
  process_trait <- function(file_blood, file_spleen) {
  
    dt <- rbind(
      fread(file_blood)[, tissue := "blood"],
      fread(file_spleen)[, tissue := "spleen"]
    )
  
    dt[, `:=`(
      padj          = p.adjust(assoc_mcp, method = "BH"),
      padj_hetero   = p.adjust(hetero_mcp, method = "BH"),
      perc_fdr_0.05 = round(n_fdr_0.05 / n_cell * 100, 2),
      perc_fdr_0.1  = round(n_fdr_0.1 / n_cell * 100, 2),
      perc_fdr_0.2  = round(n_fdr_0.2 / n_cell * 100, 2)
    )]
  
    dt[, n_ctrl := NULL]
    setorder(dt, padj)
    setcolorder(dt, old_cols)
    setnames(dt, old_cols, new_cols)
    
    return(dt)
  }

# Main
  
  # Definitions
  old_cols <- c("tissue", "group", "n_cell", 
                "assoc_mcp", "padj", "assoc_mcz", 
                "hetero_mcp", "padj_hetero", "hetero_mcz", 
                "n_fdr_0.05", "n_fdr_0.1", "n_fdr_0.2",
                "perc_fdr_0.05", "perc_fdr_0.1", "perc_fdr_0.2")
  
  new_cols <- c("Tissue type", "Cell type", "Number of cells", 
                "Cell-type p-value", "Cell-type p-value (adjusted)", "Cell-type z-score", 
                "Heterogeneity p-value", "Heterogeneity p-value (adjusted)", "Heterogeneity z-score", 
                "N cells (FDR=0.05)", "N cells (FDR=0.1)", "N cells (FDR=0.2)",
                "% cells (FDR=0.05)", "% cells (FDR=0.1)", "% cells (FDR=0.2)")

  # Processing
  ibd <- process_trait(args[1], args[4])
  cd  <- process_trait(args[2], args[5])
  uc  <- process_trait(args[3], args[6])

  # Output
  wb <- createWorkbook()
  
  addSheetWithData(wb, ibd, "scDRS AV-IBD")
  addSheetWithData(wb, cd,  "scDRS AV-CD")
  addSheetWithData(wb, uc,  "scDRS AV-UC")
  
  saveWorkbook(wb, excel_out, overwrite = TRUE)