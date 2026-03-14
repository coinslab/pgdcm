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
#'   The \code{prior_sims} and \code{post_sims} arguments control the number of simulated datasets drawn
#'   during Prior and Posterior Predictive Checking respectively. Passing \code{NULL} disables these checks entirely.
#'   Defaults to \code{list(niter = 1000, nburnin = 100, chains = 2, prior_sims = NULL, post_sims = NULL)}.
#' @param prefix Character. Descriptor prefix used for saving generated reports. Defaults to a timestamped string based on the model type.
#'
#' @return A comprehensive list containing the raw \code{mcmc_out}, \code{samples} (cleaned), \code{prior_ppc}, and \code{post_ppc} objects.
#' @export
run_pgdcm_auto <- function(config,
                           estimation_config = list(niter = 1000, nburnin = 100, chains = 2, prior_sims = NULL, post_sims = NULL),
                           prefix = NULL) {
    if (is.null(prefix)) {
        prefix <- paste0(config$type, "_", format(Sys.time(), "%Y%m%d_%H%M%S"))
    }
    source(config$code_file)
    model_code <- get(config$model_object)

    prior_res <- NULL
    if (!is.null(estimation_config$prior_sims) && estimation_config$prior_sims > 0) {
        print("\n--- 1. Running Prior Predictive Check ---")
        prior_res <- run_predictive_check(config, config$data$X, posterior_samples = NULL, n_sim = estimation_config$prior_sims, prefix = prefix, title = "PriorPPC")
    } else {
        print("\n--- 1. Skipping Prior Predictive Check ---")
    }

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

    mapped_results <- NULL
    extra_tables <- list(skill_profiles = NULL, item_parameters = NULL)
    tryCatch(
        {
            mcmc_summ <- MCMCsummary(object = res_clean)
            print(head(mcmc_summ))

            print("Mapping parameters to human-readable names...")
            mapped_results <- map_pgdcm_parameters(summary_mx = mcmc_summ, config_obj = config)
            mapped_csv_file <- paste0(prefix, "_mapped_parameters.csv")
            write.csv(mapped_results, file = mapped_csv_file, row.names = FALSE)
            print(paste("Mapped parameters saved to:", mapped_csv_file))

            print("Generating skill profiles and item parameters...")
            extra_tables <- generate_summary_tables(mapped_results = mapped_results, config_obj = config)
            
            skill_csv <- paste0(prefix, "_skill_profiles.csv")
            write.csv(extra_tables$skill_profiles, file = skill_csv, row.names = TRUE)
            print(paste("Skill profiles saved to:", skill_csv))
            
            item_csv <- paste0(prefix, "_item_parameters.csv")
            write.csv(extra_tables$item_parameters, file = item_csv, row.names = FALSE)
            print(paste("Item parameters saved to:", item_csv))

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

    post_res <- NULL
    if (!is.null(estimation_config$post_sims) && estimation_config$post_sims > 0) {
        print("\n--- 4. Running Posterior Predictive Check ---")
        post_res <- run_predictive_check(config, config$data$X, posterior_samples = res_clean, n_sim = estimation_config$post_sims, prefix = prefix, title = "PosteriorPPC")
    } else {
        print("\n--- 4. Skipping Posterior Predictive Check ---")
    }

    print("\nPipeline Complete!")
    return(list(
        mcmc_out = mcmc.out,
        samples = res_clean,
        mapped_parameters = mapped_results,
        skill_profiles = extra_tables$skill_profiles,
        item_parameters = extra_tables$item_parameters,
        prior_ppc = prior_res,
        post_ppc = post_res,
        WAIC = mcmc.out$WAIC
    ))
}
