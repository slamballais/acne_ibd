#!/usr/bin/env Rscript
# fuma.R: contains a lot of postprocessing for fuma results (figures etc)

###############################################
#### SETUP SCRIPT #############################
###############################################

# Arguments
  library(optparse)
  option_list <- list(
    make_option("--d_snp2gene", type = "character", help = "path to snp2gene dir"),
    make_option("--d_gene2func", type = "character", help = "path to gene2func dir"),
    make_option("--pleio_rds", type = "character", help = "path to .rds file with results")
  )
  opt <- parse_args(OptionParser(option_list = option_list))
  attach(opt)

# Packages

  library(cowplot)
  library(data.table)
  library(dplyr)
  library(GenomicRanges)
  library(ggplot2)
  library(ggsci)
  library(IRanges)
  library(openxlsx)
  library(stringr)
  library(UpSetR)
  library(VennDiagram)
  setDTthreads(2)
  
# Functions

  addSheetWithData <- function(wb, df, sheetName) {
    openxlsx::addWorksheet(wb, sheetName)
    openxlsx::writeData(wb, sheetName, df)
  }

  is_the_locus_new <- function(old, new, pattern) {
    x1 <- grepl(pattern, old, fixed = TRUE)
    x2 <- grepl(pattern, new, fixed = TRUE)
    
    res <- rep(NA, length(x1))
    res[!x1 & !x2] <- ""
    res[x1 & !x2] <- ""
    res[!x1 & x2] <- "NEW"
    res[x1 & x2] <- "old"
    res
  }

###############################################
#### INIT #####################################
###############################################

# Definitions

  names_acne <- c("acne_ibd", "acne_uc", "acne_cd")

  folders <- c(names_acne)
  snp2gene_files <- c("IndSigSNPs.txt", "leadSNPs.txt", 
                  "snps.txt", "genes.txt", "annov.stats.txt", 
                  "GenomicRiskLoci.txt", "magma_exp_gtex_v8_ts_avg_log2TPM.gsa.out")
  gene2func_files <- c("geneIDs.txt", "GS.txt", "summary.txt")

# Load

  # snp2gene
  snp2gene <- lapply(names_acne, function(x) {
    out <- lapply(snp2gene_files, function(y) {
      temp_path <- file.path(d_snp2gene, x, y)
      temp_cmd <- paste("grep -v '^#'", temp_path) # we use grep because of magma_exp_gtex*
      fread(cmd = temp_cmd)
    })
    names(out) <- snp2gene_files
    out
  })

  names(snp2gene) <- names_acne
  snp2gene_acne <- snp2gene[names_acne]
  
  # gene2func
  gene2func <- lapply(names_acne, function(x) {
    
    out <- lapply(gene2func_files, function(y) {
      temp_path <- file.path(d_gene2func, x, y)
      fread(temp_path)
    })
    names(out) <- gene2func_files
    out
  })
  names(gene2func) <- names_acne
  
  # Summary stats
  ss <- readRDS(pleio_rds)
  
###############################################
#### MAGMA TISSUE SPECIFICITY #################
###############################################

  df_ibd <- data.frame(
    snp2gene[[1]]$magma_exp_gtex_v8_ts_avg_log2TPM.gsa.out,
    Analysis = "Acne & IBD"
  )
  names(df_ibd)[names(df_ibd) == "FULL_NAME"] <- "Tissue"
  
  df_uc <- data.frame(
    snp2gene[[2]]$magma_exp_gtex_v8_ts_avg_log2TPM.gsa.out,
    Analysis = "Acne & UC"
  )
  names(df_uc)[names(df_uc) == "FULL_NAME"] <- "Tissue"
  
  df_cd <- data.frame(
    snp2gene[[3]]$magma_exp_gtex_v8_ts_avg_log2TPM.gsa.out,
    Analysis = "Acne & CD"
  )
  names(df_cd)[names(df_cd) == "FULL_NAME"] <- "Tissue"
  
  mts <- rbind(df_ibd, df_uc, df_cd)
  mts$Tissue <- gsub("_", " ", fixed = TRUE, mts$Tissue)
  mts$Analysis <- factor(mts$Analysis, levels = c("Acne & IBD", "Acne & UC", "Acne & CD"))
  tissue_order <- subset(mts, Analysis == "Acne & IBD") %>%
    {arrange(., P)$Tissue}
  
  mts$Tissue <- factor(mts$Tissue, levels = tissue_order)
  
  bonferroni <- 0.05 / length(tissue_order) # 54
  
  mts$log10p <- -log10(mts$P)
  mts$Significance <- with(mts, ifelse(P < bonferroni, "Significant", "Not Significant"))
  
  p <- ggplot(mts, aes(x = log10p, y = Tissue, fill = Significance)) +
    geom_bar(stat = "identity", width = 0.8) +
    geom_vline(xintercept = -log10(bonferroni), linetype = "dashed", color = "red") +
    facet_wrap(~ Analysis, nrow = 1) + 
    scale_fill_manual(values = c("Significant" = "#F8766D", "Not Significant" = "grey30")) +
    labs(
      x = expression(-log[10](P)),
      y = NULL,
      fill = "Significance"
    ) +
    theme_bw() + 
    theme(
      legend.position = "bottom",
      axis.text.y = element_text(size = 7), 
      strip.background = element_rect(fill = "white", color = "black"),
      strip.text = element_text(face = "bold", size = 10),
      plot.margin = margin(t = 5.5, r = 5.5, b = 5.5, l = 20, unit = "pt") 
    )
  ggsave(file.path(d_snp2gene, "tissue_plot.png"), p, width = 12, height = 8)

###############################################
#### OVERLAP IN LOCI ##########################
###############################################

  acne_regions <- lapply(snp2gene_acne, `[[`, "GenomicRiskLoci.txt")
  acne_region_ranges <- lapply(acne_regions, function(x) 
    GRanges(
      seqnames = x$chr,
      IRanges(start = x$start, end = x$end))
  )
  
  acne_regions_overlap <- Reduce(union, acne_region_ranges)
  acne_n_regions <- length(acne_regions_overlap@seqnames)
  
  acne_ll <- lapply(acne_region_ranges, function(x) which(acne_regions_overlap %in% x))
  table(unlist(acne_ll))
  
###############################################
#### SNPS #####################################
###############################################

  acne_snps <- lapply(snp2gene, `[[`, "snps.txt")
  acne_gws_snps <- lapply(acne_snps, function(x) sum(x$gwasP < 5E-8, na.rm = TRUE))
  acne_usnps <- do.call("rbind", acne_snps)$rsID
  
###############################################
#### GENES ####################################
###############################################

  # Prep
  genes <- lapply(snp2gene, `[[`, "genes.txt")
  symbols <- lapply(genes, `[[`, "symbol")
  usymbols <- sort(unique(unname(unlist(symbols))))
  upset_data <- data.frame(usymbols = usymbols) 
  upset_data <- cbind(upset_data, t(sapply(usymbols, function(x) 0 + sapply(symbols, function(y) x %in% y))))
  
  # Venn diagram
  venn.diagram(symbols, file = file.path(d_snp2gene, "jid_acne_test.jpg"), disable.logging = TRUE)
  
  # Upset plot
  png(file.path(d_snp2gene, "jid_upset.png"), width = 2000, height = 2000, res = 300, type = "cairo-png")
  
    upset(upset_data, 
          nsets = 6, 
          sets = names(upset_data)[-1], 
          keep.order = TRUE, 
          nintersects = NA,
          order.by = "freq")
        
  dev.off()
  
  # Find common genes
  subset(upset_data, acne_cd & acne_uc & acne_ibd)[, 1]

###############################################
#### GENE SETS ################################
###############################################

  # Prep
  gs <- lapply(gene2func, `[[`, "GS.txt")
  gssym <- lapply(gs, `[[`, "GeneSet")
  gobp <- lapply(gssym, grep, pattern = "^(GOBP|GOMF)+.*", value = TRUE)
  ugobp <- sort(unique(unname(unlist(gobp))))
  gobp_upset_data <- data.frame(ugobp = ugobp) 
  gobp_upset_data <- cbind(gobp_upset_data, t(sapply(ugobp, function(x) 0 + sapply(gobp, function(y) x %in% y))))
  
  # Venn diagram
  venn.diagram(gobp, file = file.path(d_gene2func, "jid_acne_test_gs.jpg"), disable.logging = TRUE)
  
  # Upset plot
  png(file.path(d_gene2func, "jid_gobp_upset.png"), width = 2000, height = 2000, res = 300, type = "cairo-png")
  
    upset(gobp_upset_data, 
          nsets = 6, 
          sets = names(gobp_upset_data)[-1], 
          keep.order = TRUE, 
          nintersects = NA,
          order.by = "freq")
        
  dev.off()
  
  # Find common gene sets
  shared_ac_ai <- subset(gobp_upset_data, acne_cd & acne_ibd)[, 1]
  shared_au_ai <- subset(gobp_upset_data, acne_uc & acne_ibd)[, 1]
  shared_ac_au_ai <- subset(gobp_upset_data, acne_cd & acne_uc & acne_ibd & rowSums(gobp_upset_data[, -1]) == 3)[, 1]
  
  gspp <- lapply(gs, function(x) x[grepl(x$GeneSet, pattern = "^(GOBP|GOMF)+.*")])
  gspp2 <- lapply(gspp, function(x) x[order(x$adjP), ])
  gs_excel <- file.path(d_gene2func, "jid_gobp_overview.xlsx")
  
  # Save
  wb <- openxlsx::createWorkbook()

  for (i in seq_along(gspp2)) {
    addSheetWithData(wb, gspp2[[i]], names(gspp2)[i])
  }

  addSheetWithData(wb, shared_ac_ai, "shared_a_cd&a_ibd")
  addSheetWithData(wb, shared_au_ai, "shared_a_uc&a_ibd")
  addSheetWithData(wb, shared_ac_au_ai, "shared_a_cd&a_uc&a_ibd")

  openxlsx::saveWorkbook(wb, gs_excel, overwrite = TRUE)

###############################################
#### LOCI IN ORIGINAL GWASs ###################
###############################################

  all_regions <- lapply(snp2gene, function(x) {
    subset(x[["GenomicRiskLoci.txt"]], nGWASSNPs >= 5)
  })

  all_region_ranges <- lapply(all_regions, function(x) 
    GRanges(
      seqnames = x$chr,
      IRanges(start = x$start, end = x$end))
  )
  
  all_regions_overlap <- Reduce(union, all_region_ranges)
  all_n_regions <- length(all_regions_overlap@seqnames)

  all_chr <- as.vector(all_regions_overlap@seqnames)
  all_starts <- start(all_regions_overlap)
  all_ends <- end(all_regions_overlap)
  
  gwas_loci_overlap <- do.call("rbind", lapply(seq_along(all_chr), function(i) {
    ss_temp <- subset(ss, CHR == all_chr[i] & BP >= all_starts[i] & BP <= all_ends[i])
    as.numeric(c(all_chr[i], all_starts[i], all_ends[i],
      sapply(ss_temp[, -(1:3)], min)
    ))
  }))
  gwas_loci_overlap <- as.data.frame(gwas_loci_overlap)
  names(gwas_loci_overlap) <- c("CHR", "start", "end", names(ss)[-(1:3)])
  
  xx <- gwas_loci_overlap[, -(1:3)]
  xxl <- apply(xx < 5E-8, 1, function(x) names(xx)[x], simplify = FALSE)
  
  # Old and new traits associated with each locus
  gwas_loci_overlap$old <- sapply(xxl, function(x) paste(sub("p_", "", grep("p_", x, fixed = TRUE, value = TRUE)), collapse = ","))
  gwas_loci_overlap$new <- sapply(xxl, function(x) paste(sub("placo_", "", grep("placo_", x, fixed = TRUE, value = TRUE)), collapse = ","))
  
  # Per trait
  gwas_loci_overlap$ibd  <- with(gwas_loci_overlap, is_the_locus_new(old, new, "ibd"))
  gwas_loci_overlap$uc   <- with(gwas_loci_overlap, is_the_locus_new(old, new, "uc"))
  gwas_loci_overlap$cd   <- with(gwas_loci_overlap, is_the_locus_new(old, new, "cd"))
  gwas_loci_overlap$acne <- with(gwas_loci_overlap, is_the_locus_new(old, new, "acne"))
  
  # New loci for any
  gwas_loci_overlap$new_acne_gi <- with(gwas_loci_overlap, old == "" & grepl("acne_ibd|acne_uc|acne_cd", new))
  
  # Genes per locus
  for (i in seq_along(genes)) {
    tt <- strsplit(as.character(genes[[i]]$GenomicLocus), ":", fixed = TRUE)
    tt <- lapply(tt, as.numeric)
    
    n_loci <- max(all_regions[[i]]$GenomicLocus)
    all_regions[[i]]$matched_genes <- lapply(all_regions[[i]]$GenomicLocus, function(x) {
      genes[[i]]$symbol[sapply(tt, function(y) x %in% y)]
    })
    
    temp_name <- paste0("genes_", names(all_regions)[i])
    
    gwas_loci_overlap[, temp_name] <- list(rep(list(), nrow(gwas_loci_overlap)))
    all_regions[[i]]$overlapping_region_code <- NA
    for (j in seq_len(nrow(all_regions[[i]]))) {
      hit <- which(with(gwas_loci_overlap, 
                          CHR == all_regions[[i]][j, ]$chr & 
                          start <= all_regions[[i]][j, ]$pos & 
                          end >= all_regions[[i]][j, ]$pos
                        )
                   )
      if (length(hit) == 1) all_regions[[i]]$overlapping_region_code[j] <- hit
    }
    
    temp_col <- rep("", nrow(gwas_loci_overlap))
    temp_col[all_regions[[i]]$overlapping_region_code] <- all_regions[[i]]$matched_genes
    gwas_loci_overlap[[temp_name]] <- temp_col
  }
  
  gwas_loci_overlap$unique_genes <- lapply(1:nrow(gwas_loci_overlap), 
                                           function(i) {
                                             temp_cols <- paste0("genes_", names(all_regions))
                                             gwas_loci_overlap[i, temp_cols] %>%
                                               unlist %>%
                                               unique %>%
                                               sort
                                           })
  gwas_loci_overlap$unique_genes <- lapply(gwas_loci_overlap$unique_genes, function(x) x[x != ""])
  
  # Convert to right format, write to xlsx
  gene_cols <- c(paste0("genes_", names(all_regions)), "unique_genes")
  for (n in gene_cols) {
    gwas_loci_overlap[, n] <- sapply(gwas_loci_overlap[, n], paste, collapse = ", ")
  }
  write.xlsx(gwas_loci_overlap, file.path(d_snp2gene, "jid_gwas_loci_genes.xlsx"), sheetName = "overview")

