# =============================================================================
# Workflow_CV.R
# Description: Cross-validation workflow using NIMBLE's native CV capabilities.
# =============================================================================

#' Run K-Fold Cross Validation for PGDCM Models
#'
#'
#' @param config Model configuration list from \code{build_model_config}.
#' @param k_folds Integer. The number of folds to split the data into. Default is 5.
#' @param lossFunction Character. The loss metric to evaluate predictions against held-out data.
#'   Must be one of \code{"predictive"} (log predictive density) or \code{"MSE"} (Mean Squared Error).
#'   Alternatively, an R function can be provided. Default is \code{"predictive"}.
#' @param estimation_config List of parameters controlling MCMC execution (\code{niter}, \code{nburnin}).
#'   Defaults to \code{list(niter = 1000, nburnin = 100)}.
#' @param nCores Integer. Number of CPU cores to use. Mac/Linux only. Default is 1.
#' @param nBootReps Integer. Number of bootstrap samples for Monte Carlo error estimation. Default is 200.
#'
#' @return A list with cross-validation results:
#' \itemize{
#'   \item \code{CVvalue}: The aggregated CV loss metric.
#'   \item \code{CVstandardError}: Standard error of the CV value.
#'   \item \code{foldCVInfo}: Loss metrics for each individual fold.
#' }
#' @export
run_pgdcm_cv <- function(config,
                         k_folds = 5,
                         lossFunction = "predictive",
                         estimation_config = list(niter = 1000, nburnin = 100),
                         nCores = 1,
                         nBootReps = 200) {
    # 1. Source model definition
    source(config$code_file)
    model_code <- get(config$model_object)

    # 2. Build the NIMBLE model
    print(paste("\n--- 1. Building NIMBLE model for Cross-Validation ( k =", k_folds, ") ---"))
    model <- nimbleModel(
        code = model_code,
        constants = config$constants,
        data = config$data,
        inits = config$inits
    )

    # 3. Configure MCMC tracking exactly what we monitor normally
    mcmc_conf <- configureMCMC(model, monitors = config$monitors)

    # 4. Run native NIMBLE cross-validation
    # By default, foldFunction = "random" randomly splits the scalar data nodes (X[i,j]) into k folds.
    print(paste("\n--- 2. Executing Native NIMBLE Cross-Validation (loss =", lossFunction, ") ---"))

    cv_output <- runCrossValidate(
        MCMCconfiguration = mcmc_conf,
        k = k_folds,
        foldFunction = "random",
        lossFunction = lossFunction,
        MCMCcontrol = list(
            niter = estimation_config$niter,
            nburnin = estimation_config$nburnin
        ),
        nCores = nCores,
        nBootReps = nBootReps,
        returnSamples = FALSE
    )

    print("\n--- Cross-Validation Complete! ---")
    print(paste("Final CV Value:", round(cv_output$CVvalue, 4)))
    print(paste("CV Standard Error:", round(cv_output$CVstandardError, 4)))

    return(cv_output)
}
