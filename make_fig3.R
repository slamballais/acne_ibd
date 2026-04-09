#!/usr/bin/env Rscript
# make_fig3.R: Make the Manhattan plot

# Arguments
  library(optparse)
  option_list <- list(
    make_option("--p_placo", type = "character", help = "path to placo results .rds"),
    make_option("--p_out",   type = "character", help = "path to output image")
  )
  opt <- parse_args(OptionParser(option_list = option_list))
  attach(opt)
  
# Packages
  library(cowplot)
  library(data.table)
  library(dplyr)
  library(ggplot2)
  library(ggsci)

# Main

  # Load
  placo <- readRDS(p_placo)
  
  # Modify
  placo[, BP2 := seq_along(BP)] 
  placo[, BP3 := seq_along(BP) + 100000 * (CHR - 1)]
  
  mp <- placo %>%
    group_by(CHR) %>%
    summarize(center = (max(BP3) + min(BP3) ) / 2)
    
  # Make long format
  long_vars <- c("SNP", "CHR", "BP", "BP2", "BP3")
  temp_placo <- lapply(c("placo_acne_ibd", "placo_acne_uc", "placo_acne_cd"), function(x) placo[, c(long_vars, x), with = FALSE])
  temp_placo <- lapply(temp_placo, function(x) {names(x) <- c(long_vars, "p"); x})
  temp_placo[[1]][, gwas := "ibd"]
  temp_placo[[2]][, gwas := "uc"]
  temp_placo[[3]][, gwas := "cd"]

  long_placo <- do.call("rbind", temp_placo)
  rm(temp_placo)
  
  # Plot figure
  acne_gwas <- ggplot(long_placo, 
                      aes(x = BP3, y = -log10(p), group = gwas, color = gwas)
                      ) +

  geom_point(data = subset(long_placo, p > 5E-8/2), alpha = 0.9, aes(y = -log10(p)), size = 0.05, shape = 1) +
  geom_point(data = subset(long_placo, p < 5E-8/2), alpha = 0.9, aes(y = -log10(p)), size = 1, shape = 1) + 
  scale_colour_manual(breaks = c("ibd", "cd", "uc"),
                      values = setNames(ggsci::pal_npg()(4)[-3], c("ibd", "cd", "uc")),
                      labels = c("Acne & IBD", "Acne & CD", "Acne & UC")) +
  guides(color=guide_legend("Cross-trait")) +
  
  geom_hline(yintercept = -log10(5E-8/2), color = "brown2", linetype = "dashed") +
  
  scale_x_continuous(label = mp$CHR, breaks = mp$center, expand = c(0.05, 0.05)) +
  scale_y_continuous(expand = c(0, 0), limits = c(3, 25)) +  
  xlab("Chromosome") + 
  ylab("-log10 p-value") +

  theme_classic() +
  theme(
    panel.grid.major.x = element_blank(),
    panel.grid.minor.x = element_blank()
  )

  # Save
  png(p_out, width = 8, height = 4, unit = "in", res = 600, type = "cairo-png")
  acne_gwas
  dev.off()