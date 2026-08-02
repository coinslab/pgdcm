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
#'   Must be one of \code{"MSE"} (Mean Squared Error) or \code{"predictive"} (log predictive density).
#'   Alternatively, an R function can be provided. Default is \code{"MSE"}.
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
                         lossFunction = "MSE",
                         return_samples = FALSE,
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
    monitors_to_use <- config$monitors
    if (return_samples) {
        monitors_to_use <- unique(c(monitors_to_use, "X"))
    }
    mcmc_conf <- configureMCMC(model, monitors = monitors_to_use)

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
        returnSamples = return_samples
    )

    print("\n--- Cross-Validation Complete! ---")
    print(paste("Final CV Value:", round(cv_output$CVvalue, 4)))
    print(paste("CV Standard Error:", round(cv_output$CVstandardError, 4)))

    return(cv_output)
}

# =============================================================================
# CV PLOTTING
# =============================================================================

#' Plot Posterior Predictive CV Results
#'
#' Generates a confusion matrix and a jittered scatterplot of the cross-validation
#' predictions against the true observed responses. This requires the CV to have
#' been run with \code{return_samples = TRUE}.
#'
#' @param cv_output The list returned by \code{run_pgdcm_cv} (with \code{return_samples = TRUE}).
#' @param config The original model configuration object used to generate the data.
#'
#' @return Invisibly returns a list containing accuracy, confusion matrix, 
#' observed values, and simulated predictive means.
#' @export
plot_pgdcm_cv <- function(cv_output, config) {
    if (is.null(cv_output$samples)) {
        stop("plot_pgdcm_cv requires cv_output$samples to exist. Run run_pgdcm_cv with return_samples = TRUE.")
    }
    
    X_true <- as.matrix(config$data$X)
    
    all_obs <- numeric(0)
    all_pred <- numeric(0)
    
    k <- length(cv_output$samples)
    for (i in seq_len(k)) {
        samps <- as.matrix(cv_output$samples[[i]])
        
        # Identify X columns
        X_cols <- grep("^X\\[", colnames(samps), value = TRUE)
        if (length(X_cols) == 0) {
            stop("No 'X' nodes were monitored in the posterior samples.")
        }
        
        # Find which items were held out (they will vary, fixed ones won't)
        vars <- apply(samps[, X_cols, drop = FALSE], 2, var)
        held_out_cols <- names(vars)[vars > 0]
        
        if (length(held_out_cols) == 0) {
            warning(paste("No held-out nodes identified in fold", i))
            next
        }
        
        # Extract the posterior mean (probability) for the held-out nodes
        pred_means <- colMeans(samps[, held_out_cols, drop = FALSE])
        
        # Extract the true observed values for those exact nodes
        true_vals <- numeric(length(held_out_cols))
        names(true_vals) <- held_out_cols
        
        for (node in held_out_cols) {
            # Extract matrix indices from node string (e.g., "X[1, 5]")
            matches <- regmatches(node, gregexpr("[0-9]+", node))[[1]]
            if (length(matches) == 2) {
                row_idx <- as.numeric(matches[1])
                col_idx <- as.numeric(matches[2])
                true_vals[node] <- X_true[row_idx, col_idx]
            }
        }
        
        valid <- is.finite(true_vals) & is.finite(pred_means)
        all_obs <- c(all_obs, true_vals[valid])
        all_pred <- c(all_pred, pred_means[valid])
    }
    
    if (length(all_obs) == 0) {
        stop("No valid observed and simulated values were found.")
    }
    
    # Binarize predictions
    all_sim_binary <- ifelse(all_pred >= 0.5, 1, 0)
    accuracy <- mean(all_obs == all_sim_binary)
    
    confusion_matrix <- table(
        Observed = factor(all_obs, levels = c(0, 1)),
        Predicted = factor(all_sim_binary, levels = c(0, 1))
    )
    
    print("\n--- Plot 4 Cross-Validation Summary ---")
    print(paste("Total evaluated responses:", length(all_obs)))
    print(paste("Overall accuracy:", round(accuracy, 4)))
    print("Confusion Matrix:")
    print(confusion_matrix)
    
    # Generate Plot
    set.seed(123)
    observed_jitter <- jitter(all_obs, amount = 0.06)
    simulated_jitter <- jitter(all_sim_binary, amount = 0.06)
    
    plot(
        observed_jitter,
        simulated_jitter,
        xlab = "Observed Held-Out Responses",
        ylab = "Posterior Predictive Predicted Responses",
        main = "Plot 4: Posterior Predictive CV Check",
        pch = 16,
        col = grDevices::adjustcolor("black", alpha.f = 0.20),
        xlim = c(-0.12, 1.12),
        ylim = c(-0.12, 1.12),
        xaxt = "n",
        yaxt = "n"
    )
    axis(side = 1, at = c(0, 1), labels = c("0", "1"))
    axis(side = 2, at = c(0, 1), labels = c("0", "1"))
    abline(a = 0, b = 1, col = "red", lwd = 2)
    legend(
        "top",
        legend = paste0("Overall binary accuracy = ", round(accuracy, 3)),
        bty = "n"
    )
    
    invisible(list(
        accuracy = accuracy,
        confusion_matrix = confusion_matrix,
        observed = all_obs,
        predicted = all_sim_binary,
        predicted_probs = all_pred
    ))
}
