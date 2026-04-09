#!/usr/bin/env Rscript
# run_placo_for_spredixcan.R: specifically rerun placo on the imputed summary stats

# Arguments
  library(optparse)
  
  option_list <- list(
    make_option("--d_scripts", type = "character", help = "path to scripts"),
    make_option("--in1", type = "character", help = "ss1 path"),
    make_option("--in2", type = "character", help = "ss2 path"),
    make_option("--out1", type = "character", help = "out path concordant"),
    make_option("--out2", type = "character", help = "out path discordant"),
    make_option("--n_cores", type = "numeric", help = "number of cores for placo")
  )
  
  opt <- parse_args(OptionParser(option_list = option_list))
  attach(opt)

# Packages
  library(data.table)
  source(file.path(d_scripts, "PLACO.R")) # placo
  setDTthreads(n_cores)

# Functions
  parallel_placo <- function(zz, n_cores, abs_tol) {
    cl <- parallel::makeForkCluster(n_cores)
    doParallel::registerDoParallel(cl)
    on.exit(parallel::stopCluster(cl))
    out <- parallel::parLapply(cl, zz, function(x) integrate(.pdfx, x, Inf, abs.tol = abs_tol)$value)
    parallel::stopCluster(cl)
    on.exit()
    return(2 * as.double(unlist(out)))
  }
  
  run_placo <- function(z1, z2, varz, n_cores, abs_tol = .Machine$double.eps^0.8) {
    z12 <- abs(z1 * z2)
    z12_s1 <- z12 / sqrt(varz[1])
    z12_s2 <- z12 / sqrt(varz[2])
    
    p1 <- parallel_placo(z12_s1, n_cores, abs_tol)
    p2 <- parallel_placo(z12_s2, n_cores, abs_tol)
    p0 <- parallel_placo(z12, n_cores, abs_tol)
    pcomp <- p1 + p2 - p0
    
    return(pcomp)
  }

# Main

  # Load
  ss1 <- fread(in1)
  ss2 <- fread(in2)
  
  clean <- ss1[, c("variant_id", "panel_variant_id", "chromosome", "position", "effect_allele", "non_effect_allele", "current_build")]
  clean[, z1 := ss1$zscore]
  clean[, z2 := ss2$zscore]
  
  # Run Placo
  varz <- var.placo(cbind(ss1$zscore, ss2$zscore), cbind(ss1$pvalue, ss2$pvalue))
  clean[, placo := run_placo(ss1$zscore, ss2$zscore, varz, n_cores)]
  
  # Postprocessing
  clean[, z_temp := qnorm(1 - placo / 2)]
  clean[, concordant := sign(z1) == sign(z2)]
  clean[, zscore := z_temp * sign(z1)]
  
  concordant <- clean[concordant == TRUE]
  discordant <- clean[concordant == FALSE]
  
  # Save concordant and discordant SNPs separately
  fwrite(concordant, out1, sep = "\t", quote = FALSE, row.names = FALSE)
  fwrite(discordant, out2, sep = "\t", quote = FALSE, row.names = FALSE)
