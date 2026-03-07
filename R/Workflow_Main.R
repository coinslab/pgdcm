# =============================================================================
# Workflow_Main.R
# Description: Main Bayesian execution MCMC logic loop orchestrator.
# =============================================================================

library(nimble)
library(MCMCvis)

# ── Main Integration Pipeline ────────────────────────────────────────────────
#' Run Integrated Workflow (Prior, MCMC, Posterior)
#'
#' Orchestrates the complete end-to-end Bayesian estimation pipeline for PGDCM and SEM.
#' Computes prior predictive checks, compiles and runs Nimble MCMC, assesses convergence,
#' and generates posterior predictive checks.
#'
#' @param config Model configuration list from \code{build_model_config}.
#' @param estimation_config List of parameters controlling MCMC execution (\code{niter}, \code{nburnin}, \code{chains}, \code{prior_sims}, \code{post_sims}).
#' @param prefix Character. Descriptor prefix used for saving generated reports.
#'
#' @return A comprehensive list containing the raw \code{mcmc_out}, \code{samples} (cleaned), \code{prior_ppc}, and \code{post_ppc} objects.
#' @export
run_pgdcm_auto <- function(config, estimation_config, prefix = "Unified_Pipeline") {
    source(config$code_file)
    model_code <- get(config$model_object)

    print("\n--- 1. Running Prior Predictive Check ---")
    prior_res <- run_predictive_check(config, config$data$X, posterior_samples = NULL, n_sim = estimation_config$prior_sims, prefix = prefix, title = "PriorPPC")

    print("\n--- 2. Executing MCMC Inference ---")
    mcmc.out <- nimbleMCMC(
        code = model_code,
        constants = config$constants,
        data = config$data,
        inits = config$inits,
        nchains = estimation_config$chains,
        niter = estimation_config$niter,
        nburnin = estimation_config$nburnin,
        summary = TRUE,
        monitors = config$monitors,
        samplesAsCodaMCMC = TRUE,
        WAIC = TRUE
    )

    res <- mcmc.list(mcmc.out$samples)

    print("\n--- 3. Removing Structural NAs and Assessing Convergence ---")
    res_clean <- filter_structural_nas(res)

    tryCatch(
        {
            mcmc_summ <- MCMCsummary(object = res_clean)
            print(head(mcmc_summ))

            valid_params <- colnames(res_clean[[1]])
            if (any(grepl("beta_root", valid_params))) MCMCplot(object = res_clean, params = "beta_root", HPD = TRUE, ci = c(50, 90))
            if (any(grepl("theta", valid_params))) MCMCplot(object = res_clean, params = "theta", HPD = TRUE, ci = c(50, 90))
            if (any(grepl("lambda", valid_params))) MCMCplot(object = res_clean, params = "lambda", HPD = TRUE, ci = c(50, 90))
        },
        error = function(e) {
            print(paste("Plotting/Summary Warning:", e$message))
        }
    )

    convergence <- check_mcmc_convergence(res_clean, blocksize = min(50, estimation_config$niter / 10), burninperiod = min(100, estimation_config$nburnin / 2))
    print(paste("MCMC Convergence Estimate (relerrors < 0.1):", convergence$converged))

    print("\n--- 4. Running Posterior Predictive Check ---")
    post_res <- run_predictive_check(config, config$data$X, posterior_samples = res_clean, n_sim = estimation_config$post_sims, prefix = prefix, title = "PosteriorPPC")

    print("\nPipeline Complete!")
    return(list(
        mcmc_out = mcmc.out,
        samples = res_clean,
        prior_ppc = prior_res,
        post_ppc = post_res,
        WAIC = mcmc.out$WAIC
    ))
}
