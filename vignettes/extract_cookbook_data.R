res_IRT <- readRDS("/Users/Athul/Downloads/pgdcm/vignettes/IRT_results.rds")
res_DCM <- readRDS("/Users/Athul/Downloads/pgdcm/vignettes/DCM_results.rds")
res_AH <- readRDS("/Users/Athul/Downloads/pgdcm/vignettes/AH_DCM_results.rds")
res_HO <- readRDS("/Users/Athul/Downloads/pgdcm/vignettes/HO_DCM_results.rds")

extract_res <- function(res) {
  if (is.null(res)) return(NULL)
  
  waic <- res$WAIC
  
  if (!is.null(res$mcmc_out$summary$all.chains)) {
    cols <- colnames(res$mcmc_out$summary$all.chains)
    mean_col <- cols[tolower(cols) == "mean"]
    if (length(mean_col) > 0) {
      summary_mean <- res$mcmc_out$summary$all.chains[, mean_col[1], drop=FALSE]
      # Let's standardize the column name to "mean" to fix Cookbook.qmd without needing to change it, or we change Cookbook.qmd.
      # Actually Cookbook.qmd uses "mean".
      # But let's rename it to "mean" in our lighter object.
      colnames(summary_mean) <- "mean"
    } else {
      summary_mean <- res$mcmc_out$summary$all.chains[, 1, drop=FALSE]
      colnames(summary_mean) <- "mean"
    }
  } else {
    summary_mean <- NULL
  }
  
  list(
    WAIC = waic,
    mcmc_out = list(
      summary = list(
        all.chains = summary_mean
      )
    )
  )
}

cookbook_data <- list(
  IRT = extract_res(res_IRT),
  DCM = extract_res(res_DCM),
  AH = extract_res(res_AH),
  HO = extract_res(res_HO)
)

saveRDS(cookbook_data, "/Users/Athul/Downloads/pgdcm/vignettes/cookbook_data.rds")
