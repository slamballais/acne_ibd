#!/usr/bin/env Rscript
# make_fig2.R: Combine the Venn diagrams

# Arguments
  library(optparse)
  option_list <- list(
    make_option("--p_acne_ibd", type = "character", help = "path to venn diagram of acne and ibd"),
    make_option("--p_acne_cd",  type = "character", help = "path to venn diagram of acne and cd"),
    make_option("--p_acne_uc",  type = "character", help = "path to venn diagram of acne and uc"),
    make_option("--p_out",      type = "character", help = "path to output image")
  )
  opt <- parse_args(OptionParser(option_list = option_list))
  attach(opt)
  
# Packages
  library(cowplot)
  library(magick)

# Load images
  p_images <- c(p_acne_ibd, p_acne_cd, p_acne_uc)
  images <- lapply(p_images, function(x) {
    image <- magick::image_read(x)
    magick::image_ggplot(image)
  })

# Assemble
  png(p_out, height = 3, width = 12, units = "in", res = 600, type = "cairo-png")
  plot_grid(plotlist = images,
            nrow = 1,
            labels = LETTERS[1:3])
  dev.off()
