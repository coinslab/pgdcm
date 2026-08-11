# =============================================================================
# Workflow_PPC.R
# Description: Predictive Check plot generation and simulation loop wrappers.
# =============================================================================


# ── Reporting Plots ──────────────────────────────────────────────────────────
#' Generate Posterior/Prior Predictive Plots
#'
#' Creates diagnostic plots comparing simulated vs observed statistics
#' including global means, score distributions, item difficulties, and co-occurrences.
#' When \code{filename} is \code{NULL}, plots render inline to the active graphics
#' device (e.g., RStudio Plots pane or Quarto output). Otherwise, saves to a PDF file.
#'
#' @param filename Character or \code{NULL}. Output path for the PDF file.
#'   If \code{NULL}, renders inline instead of saving to PDF.
#' @param title_suffix Character. Title suffix appended to plot titles.
#' @param simMeans Numeric vector. Simulated global means.
#' @param simRowMeans Numeric matrix. Simulated row (participant) means.
#' @param simColMeans Numeric matrix. Simulated column (item) means.
#' @param avgSimM2 Numeric matrix. Simulated average second-order moments.
#' @param obsColMeans Numeric vector. Observed column means.
#' @param obsRowMeans Numeric vector. Observed row means.
#' @param obsMean Numeric. Observed global mean.
#' @param M2_obs Numeric matrix. Observed second-order moments.
#'
#' @return NULL. Saves a PDF file to the specified path, or renders inline if
#'   \code{filename} is \code{NULL}.
#' @export
generate_ppc_plots <- function(filename, title_suffix, simMeans, simRowMeans, simColMeans, avgSimM2, obsColMeans, obsRowMeans, obsMean, M2_obs) {
    if (!is.null(filename)) {
        pdf(filename, width = 12, height = 12)
    }

    p1 <- ggplot(data.frame(x = simMeans), aes(x = x)) +
        geom_histogram(fill = "lightblue", color = "black", bins = 15) +
        geom_vline(xintercept = obsMean, color = "red", linetype = "dashed", linewidth = 1.5) +
        labs(title = paste("1. Avg. Response Distribution", title_suffix), subtitle = paste("Obs Mean =", round(obsMean, 3))) +
        theme_minimal()

    row_means_df <- data.frame(
        value = c(obsRowMeans, as.vector(simRowMeans)),
        type = c(rep("Observed", length(obsRowMeans)), rep("Simulated", length(as.vector(simRowMeans)))),
        simulation = c(rep(NA, length(obsRowMeans)), rep(1:nrow(simRowMeans), each = length(obsRowMeans)))
    )

    p2 <- ggplot() +
        geom_density(data = subset(row_means_df, type == "Simulated"), aes(x = value, group = simulation), color = "blue", alpha = 0.1) +
        geom_density(data = subset(row_means_df, type == "Observed"), aes(x = value), color = "black", linewidth = 1.2) +
        labs(title = paste("2. Participant Response Dist.", title_suffix), subtitle = "Black: Obs, Blue: Sim") +
        theme_minimal()

    col_means_df <- data.frame(
        value = c(obsColMeans, as.vector(simColMeans)),
        type = c(rep("Observed", length(obsColMeans)), rep("Simulated", length(as.vector(simColMeans)))),
        simulation = c(rep(NA, length(obsColMeans)), rep(1:nrow(simColMeans), each = length(obsColMeans)))
    )

    p3 <- ggplot() +
        geom_density(data = subset(col_means_df, type == "Simulated"), aes(x = value, group = simulation), color = "blue", alpha = 0.1) +
        geom_density(data = subset(col_means_df, type == "Observed"), aes(x = value), color = "black", linewidth = 1.2) +
        labs(title = paste("3. Item Response Dist.", title_suffix), subtitle = "Black: Obs, Blue: Sim") +
        theme_minimal()

    p4 <- ggplot(data.frame(Obs = obsColMeans, Sim = colMeans(simColMeans)), aes(x = Obs, y = Sim)) +
        geom_point(color = "blue", alpha = 0.7) +
        geom_abline(slope = 1, intercept = 0, linetype = "dashed", color = "red") +
        labs(title = paste("4. Simulated Item Response Versus Observed Item Response", title_suffix)) +
        xlim(0, 1) +
        ylim(0, 1) +
        theme_minimal()

    p5 <- ggplot(data.frame(Obs = as.vector(M2_obs), Sim = as.vector(avgSimM2)), aes(x = Obs, y = Sim)) +
        geom_point(color = "darkgreen", size = 0.5, alpha = 0.5) +
        geom_abline(slope = 1, intercept = 0, linetype = "dashed", color = "red") +
        labs(title = paste("5. Simulated Item Response Co-occurrence Versus Observed Item Response Co-occurrence", title_suffix)) +
        xlim(0, 1) +
        ylim(0, 1) +
        theme_minimal()

    grid.arrange(p1, arrangeGrob(p2, p3, ncol = 2), arrangeGrob(p4, p5, ncol = 2), nrow = 3)
    if (!is.null(filename)) {
        dev.off()
        print(paste("Plots saved to", filename))
    }
}

# ── General Predictive Checking Wrapper ──────────────────────────────────────
#' Run Predictive Check (Prior or Posterior)
#'
#' Simulates responses from the specified Nimble model using either priors
#' or a provided posterior distribution matrix. Generates corresponding diagnostic plots.
#'
#' @param config Model configuration list from \code{build_model_config}.
#' @param obs_X Numeric matrix of observed data to compare against.
#' @param posterior_samples Optional \code{mcmc.list} or matrix of posterior samples. If \code{NULL}, simulates priors.
#' @param n_sim Numeric. Number of simulations to draw. Default is 50.
#' @param prefix Character or \code{NULL}. Prefix for the output plot filename.
#'   If \code{NULL}, plots render inline instead of saving to PDF.
#' @param title Character. String used for labeling (e.g., "PriorPPC").
#'
#' @return A nested list containing exact Posterior/Prior Predictive P-values (PPPs) 
#'   and their corresponding observed discrepancy values:
#'   \itemize{
#'     \item \code{Global_Fit}: Global matrix means.
#'     \item \code{Item_Fit}: Item column means (Proportion correct).
#'     \item \code{Person_Fit}: Participant row means (Total score).
#'     \item \code{Edge_Fit}: Pairwise Log Odds Ratios (LOR) and Joint Co-occurrences (M2).
#'   }
#'   Each metric is returned as a list containing \code{value} (the observed statistic) and \code{ppp} (the predictive p-value).
#' @export
run_predictive_check <- function(config, obs_X, posterior_samples = NULL, n_sim = 50, prefix = "Untitled", title = "PPC") {
    source(config$code_file)
    model_code <- get(config$model_object)

    data_sim <- config$data
    data_sim$X <- NULL # allow data to be simulated

    model_sim <- nimbleModel(code = model_code, constants = config$constants, data = data_sim, inits = config$inits, buildDerivs = FALSE)
    cmodel_sim <- compileNimble(model_sim)

    params_in_model <- config$monitors

    n_participants <- config$constants$nrparticipants
    n_items <- config$constants$nrtasknodes
    
    task_names <- igraph::V(config$graph)[tolower(igraph::V(config$graph)$type) == "task"]$name

    simMeans <- numeric(n_sim)
    simRowMeans <- matrix(NA, nrow = n_sim, ncol = n_participants)
    simColMeans <- matrix(NA, nrow = n_sim, ncol = n_items)
    colnames(simColMeans) <- task_names
    
    simM2Sum <- matrix(0, nrow = n_items, ncol = n_items)
    rownames(simM2Sum) <- task_names
    colnames(simM2Sum) <- task_names

    LOR_ppp_count <- matrix(0, nrow = n_items, ncol = n_items)
    M2_ppp_count <- matrix(0, nrow = n_items, ncol = n_items)

    obsMean <- mean(obs_X, na.rm = TRUE)
    obsRowMeans <- rowMeans(obs_X, na.rm = TRUE)
    obsColMeans <- colMeans(obs_X, na.rm = TRUE)
    names(obsColMeans) <- task_names
    
    obsM2 <- compute_M2(obs_X)
    rownames(obsM2) <- task_names
    colnames(obsM2) <- task_names
    
    obsLOR <- compute_LOR(obs_X)
    rownames(obsLOR) <- task_names
    colnames(obsLOR) <- task_names

    if (!is.null(posterior_samples)) {
        samples_mat <- as.matrix(posterior_samples)
        sample_indices <- sample(1:nrow(samples_mat), n_sim, replace = TRUE)
        nodesToSim <- cmodel_sim$getDependencies(params_in_model, self = FALSE, downstream = TRUE)
    } else {
        nodesToSim <- cmodel_sim$getDependencies(params_in_model, self = TRUE, downstream = TRUE)
    }

    # Single Pass: Simulate and calculate strict test statistics
    for (i in 1:n_sim) {
        if (!is.null(posterior_samples)) {
            idx <- sample_indices[i]
            row <- samples_mat[idx, ]

            for (pNode in params_in_model) {
                cols_for_node <- grep(paste0("^", pNode, "\\["), names(row), value = TRUE)
                if (length(cols_for_node) > 0) {
                    for (col in cols_for_node) {
                        val <- row[col]
                        matches <- regmatches(col, gregexpr("[0-9]+", col))[[1]]
                        if (length(matches) == 2) {
                            cmodel_sim[[pNode]][as.numeric(matches[1]), as.numeric(matches[2])] <- val
                        } else if (length(matches) == 1) {
                            cmodel_sim[[pNode]][as.numeric(matches[1])] <- val
                        }
                    }
                }
            }
        }

        cmodel_sim$simulate(nodesToSim)
        simX <- cmodel_sim$X

        # Univariate
        sim_mean <- mean(simX, na.rm = TRUE)
        sim_col_means <- colMeans(simX, na.rm = TRUE)
        sim_row_means <- rowMeans(simX, na.rm = TRUE)
        
        simMeans[i] <- sim_mean
        simColMeans[i, ] <- sim_col_means
        simRowMeans[i, ] <- sim_row_means
        
        # Bivariate
        simM2 <- compute_M2(simX)
        simM2Sum <- simM2Sum + replace(simM2, is.na(simM2), 0)
        
        simLOR <- compute_LOR(simX)
        
        # Accumulate PPPs for bivariate statistics
        M2_ppp_count <- M2_ppp_count + replace(simM2 >= obsM2, is.na(simM2 >= obsM2), 0)
        LOR_ppp_count <- LOR_ppp_count + replace(simLOR >= obsLOR, is.na(simLOR >= obsLOR), 0)

        if (i %% 10 == 0) print(paste(title, "Simulation:", i, "/", n_sim))
    }

    if (!is.null(prefix)) {
        plot_filename <- paste0(prefix, "_", gsub(" ", "", title), "_", config$type, ".pdf")
    } else {
        plot_filename <- NULL
    }

    generate_ppc_plots(
        plot_filename,
        paste("(", title, "-", config$type, ")"),
        simMeans, simRowMeans, simColMeans, simM2Sum / n_sim, obsColMeans, obsRowMeans, obsMean, obsM2
    )
    
    # Calculate Posterior Predictive P-values (PPP)
    ppp_Global_Mean <- mean(simMeans >= obsMean, na.rm = TRUE)
    ppp_Item_Mean <- colMeans(sweep(simColMeans, 2, obsColMeans, ">="), na.rm = TRUE)
    ppp_Person_Mean <- colMeans(sweep(simRowMeans, 2, obsRowMeans, ">="), na.rm = TRUE)
    
    ppp_LOR <- LOR_ppp_count / n_sim
    ppp_M2 <- M2_ppp_count / n_sim
    
    cat(sprintf("\n--- %s Standard PPC Fit Summary ---\n", title))
    cat(sprintf("Global Mean = %.3f (PPP: %.3f)\n", obsMean, ppp_Global_Mean))
    cat(sprintf("Item Means (PPP < 0.05 or > 0.95): %d / %d\n", sum(ppp_Item_Mean < 0.05 | ppp_Item_Mean > 0.95), n_items))
    cat(sprintf("Item LOR (PPP < 0.05 or > 0.95): %d / %d\n", sum(ppp_LOR[upper.tri(ppp_LOR)] < 0.05 | ppp_LOR[upper.tri(ppp_LOR)] > 0.95, na.rm = TRUE), (n_items * (n_items - 1)) / 2))
    
    return(list(
        Global_Fit = list(
            Mean = list(value = obsMean, ppp = ppp_Global_Mean)
        ),
        Item_Fit = list(
            Mean = list(value = obsColMeans, ppp = ppp_Item_Mean)
        ),
        Person_Fit = list(
            Mean = list(value = obsRowMeans, ppp = ppp_Person_Mean)
        ),
        Edge_Fit = list(
            LOR = list(value = obsLOR, ppp = ppp_LOR),
            M2 = list(value = obsM2, ppp = ppp_M2)
        ),
        n_sim = n_sim
    ))
}
