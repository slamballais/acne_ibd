#!/usr/bin/env Rscript
# run_placo.R

# Arguments
  library(optparse)
  
  option_list <- list(
    make_option("--d_scripts", type = "character", help = "path to scripts"),
    make_option("--ibd_path",  type = "character", help = "path to ibd cleaned ss"),
    make_option("--uc_path",   type = "character", help = "path to uc cleaned ss"),
    make_option("--cd_path",   type = "character", help = "path to cd cleaned ss"),
    make_option("--acne_path", type = "character", help = "path to acne cleaned ss"),
    make_option("--p_out_rds", type = "character", help = "path to .rds output file"),
    make_option("--p_out_gz",  type = "character", help = "path to .tsv.gz output file"),
    make_option("--n_cores",   type = "numeric",   help = "number of cores for placo")
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
  ss_paths  <- c(ibd_path, uc_path, cd_path, acne_path)
  ss        <- lapply(ss_paths, fread)
  vars      <- c("ibd", "uc", "cd", "acne")
  names(ss) <- vars
  
  clean          <- ss[["ibd"]][, c("SNP", "CHR", "BP")]
  clean$p_ibd    <- ss[["ibd"]]$PVAL
  clean$p_uc     <- ss[["uc"]]$PVAL
  clean$p_cd     <- ss[["cd"]]$PVAL
  clean$p_acne   <- ss[["acne"]]$PVAL
  
  # Run Placo
  varz_acne <- lapply(1:3, function(i) var.placo(cbind(ss[[i]]$Z, ss[["acne"]]$Z), 
                                                 cbind(ss[[i]]$P, ss[["acne"]]$P)))
  
  clean$placo_acne_ibd <- run_placo(ss[["ibd"]]$Z, ss[["acne"]]$Z, varz_acne[[1]], n_cores)
  clean$placo_acne_uc  <- run_placo(ss[["uc"]]$Z,  ss[["acne"]]$Z, varz_acne[[2]], n_cores)
  clean$placo_acne_cd  <- run_placo(ss[["cd"]]$Z,  ss[["acne"]]$Z, varz_acne[[3]], n_cores)
  
  # Save
  saveRDS(clean, p_out_rds)
  fwrite(clean, p_out_gz, sep = "\t", quote = FALSE, row.names = FALSE)