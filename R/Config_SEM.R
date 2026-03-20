# =============================================================================
# Config_SEM.R
# Description: Explicit constants and initialization definitions for Structural Equation Models.
# =============================================================================

library(igraph)

# Distinct Initialization for SEM
#' Configure SEM Initialization and Constants
#'
#' Generates the necessary Nimble \code{constants}, \code{inits}, and \code{monitors}
#' tailored for Structural Equation Models (SEMs).
#'
#' @param info Graph structural properties from \code{get_graph_info}.
#' @param X A numeric matrix representing the observational participant data.
#' @param priors Optional list of prior specifications. Can be provided as common pairs 
#'   (e.g., \code{list(alpha = c(mean, std), beta = c(mean, std))}) or individual parameter arrays 
#'   (e.g., \code{list(alpha_mean = c(...), alpha_std = c(...), beta_mean = matrix(...), beta_std = matrix(...))}).
#'   If \code{NULL}, default priors (mean 0, std 2) are generated. Passing a standard deviation of 
#'   \code{0.0001} or similar effectively acts as a point distribution, enabling the use of \code{pgdcm} 
#'   as a scoring-only model when parameter means are supplied from a previous calibration.
#' @param priors Optional list of prior specifications.
#'
#' @return A list with \code{constants}, \code{inits}, \code{monitors}, and \code{data}.
#' @export
configure_sem <- function(info, X, priors = NULL) {
    nrparticipants <- nrow(X)

    # Look at graph compute properties to set constants
    att_computes <- info$attr_computes
    task_computes <- tolower(V(info$graph)[tolower(V(info$graph)$type) == "task"]$compute)

    constants <- list(
        nrparticipants = nrparticipants,
        nrtasknodes = info$nrtasknodes,
        nrattributenodes = info$nrattributenodes,
        nrnodes = info$nrnodes,
        CDMmatrix = info$matrix,
        attdim = info$nrattributenodes,
        SEMdoZscoreAttribute = as.numeric("zscore" %in% att_computes || "continuous" %in% att_computes),
        SEMdoPercentileAttribute = as.numeric("percentile" %in% att_computes),
        SEMdoBinaryAttribute = as.numeric("binary" %in% att_computes),
        SEMdoZscoreTask = as.numeric("zscore" %in% task_computes || "continuous" %in% task_computes),
        SEMdoPercentileTask = as.numeric("percentile" %in% task_computes),
        SEMdoBinaryTask = as.numeric("binary" %in% task_computes),
        CDMattnodesmax = max(2, info$nrattributenodes)
    )

    # Prior generation
    alpha_prior_mean <- rep(0, info$nrnodes)
    alpha_prior_std <- rep(2, info$nrnodes)
    beta_prior_mean <- matrix(0, nrow = info$nrnodes, ncol = info$nrnodes)
    beta_prior_std <- matrix(2, nrow = info$nrnodes, ncol = info$nrnodes)

    if (!is.null(priors)) {
        if (all(c("alpha", "beta") %in% names(priors)) && length(priors$alpha) == 2 && length(priors$beta) == 2 && !is.matrix(priors$beta)) {
            alpha_prior_mean[] <- priors$alpha[1]
            alpha_prior_std[] <- priors$alpha[2]
            beta_prior_mean[] <- priors$beta[1]
            beta_prior_std[] <- priors$beta[2]
        } else {
            if (!is.null(priors$alpha_mean)) alpha_prior_mean <- priors$alpha_mean
            if (!is.null(priors$alpha_std)) alpha_prior_std <- priors$alpha_std

            if (!is.null(priors$beta_mean)) beta_prior_mean <- priors$beta_mean
            if (!is.null(priors$beta_std)) beta_prior_std <- priors$beta_std
        }
    }

    constants$alpha_prior_mean <- alpha_prior_mean
    constants$alpha_prior_std <- alpha_prior_std
    constants$beta_prior_mean <- beta_prior_mean
    constants$beta_prior_std <- beta_prior_std

    alpha_init <- rep(0, info$nrnodes)
    beta_init <- matrix(0, nrow = info$nrnodes, ncol = info$nrnodes)

    for (r in 1:info$nrnodes) {
        for (c in 1:info$nrnodes) {
            if (info$matrix[r, c] == 1) {
                beta_init[r, c] <- rnorm(1, 0.5, 0.5)
            }
        }
    }

    if (constants$SEMdoBinaryAttribute || constants$SEMdoPercentileAttribute) {
        attributenodes_init <- matrix(rbinom(nrparticipants * constants$CDMattnodesmax, 1, 0.5), nrow = nrparticipants, ncol = constants$CDMattnodesmax)
    } else {
        attributenodes_init <- matrix(rnorm(nrparticipants * constants$CDMattnodesmax), nrow = nrparticipants, ncol = constants$CDMattnodesmax)
    }

    inits <- list(
        alpha = alpha_init,
        beta = beta_init,
        attributenodes = attributenodes_init
    )

    monitors <- c("alpha", "beta", "attributenodes")

    list(constants = constants, inits = inits, monitors = monitors, data = list(X = X))
}
