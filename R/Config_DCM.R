# =============================================================================
# Config_DCM.R
# Description: Explicit constants and initialization definitions for DCM families.
# =============================================================================

# Distinct Initialization for DCM based on subtype
#' Configure DCM Initialization and Constants
#'
#' Generates the necessary Nimble \code{constants}, \code{inits}, and \code{monitors}
#' specifically tailored for Diagnostic Classification Models (DCMs).
#'
#' @param info Graph structural properties from \code{get_graph_info}.
#' @param X A numeric matrix representing the observational participant data.
#' @param priors Optional list of prior specifications. Can be provided as common pairs
#'   (e.g., \code{list(beta = c(mean, std), theta = c(mean, std), lambda = c(mean, std))}) or individual parameter arrays
#'   (e.g., \code{list(beta_mean = c(...), beta_std = c(...), theta_mean = matrix(...), ...)}).
#'   If \code{NULL}, default priors (mean 0, std 2) are generated. Passing a standard deviation of
#'   \code{0.0001} or similar effectively acts as a point distribution, enabling the use of \code{pgdcm}
#'   as a scoring-only model when parameter means are supplied from a previous calibration.
#'
#' @return A list with \code{constants}, \code{inits}, \code{monitors}, and \code{data}.
#' @export
configure_dcm <- function(info, X, priors = NULL) {
    nrparticipants <- nrow(X)

    # Determine if root attributes are continuous (Higher-Order, MIRT, IRT structures)
    roots <- info$attr_computes[1:info$nrbetaroot]
    is_continuous_ho <- as.numeric(all(roots %in% c("zscore", "continuous")))

    constants <- list(
        nrparticipants = nrparticipants,
        nrtasknodes = info$nrtasknodes,
        nrattributenodes = info$nrattributenodes,
        nrnodes = info$nrnodes,
        CDMattnodes = info$nrattributenodes,
        CDMnrtasknodes = info$nrtasknodes,
        CDMmatrix = info$matrix,
        nrbetaroot = info$nrbetaroot,
        isDINA = info$isDINA,
        isDINO = info$isDINO,
        isDINM = info$isDINM,
        isContinuousHO = is_continuous_ho,
        CDMattnodesmax = max(2, info$nrattributenodes)
    )

    # Pre-calculate DAG topology constants to eliminate inner MCMC loops
    nrnodes <- info$nrnodes
    is_cont_parent <- matrix(0, nrow = nrnodes, ncol = nrnodes)
    is_disc_parent <- matrix(0, nrow = nrnodes, ncol = nrnodes)

    req_disc <- numeric(nrnodes)
    sum_input <- numeric(nrnodes)
    has_cont <- numeric(nrnodes)

    for (k in 1:nrnodes) {
        for (p in 1:nrnodes) {
            if (info$matrix[k, p] != 0) {
                # If continuous root (taking into account HO dynamically as before)
                if (is_continuous_ho == 1 && p <= info$nrbetaroot) {
                    is_cont_parent[k, p] <- info$matrix[k, p]
                } else {
                    is_disc_parent[k, p] <- info$matrix[k, p]
                }
            }
        }
        sum_input[k] <- sum(info$matrix[k, ])
        req_disc[k] <- sum(is_disc_parent[k, ])
        has_cont[k] <- ifelse(sum(is_cont_parent[k, ]) > 0, 1.0, 0.0)
    }

    constants$is_cont_parent <- is_cont_parent
    constants$is_disc_parent <- is_disc_parent
    constants$req_disc <- req_disc
    constants$sum_input <- sum_input
    constants$has_cont <- has_cont

    # Prior generation
    # Defaults
    beta_prior_mean <- matrix(0, nrow = info$nrbetaroot, ncol = 1)
    beta_prior_std <- matrix(2, nrow = info$nrbetaroot, ncol = 1)
    theta_prior_mean <- matrix(0, nrow = info$nrattributenodes, ncol = 2)
    theta_prior_std <- matrix(2, nrow = info$nrattributenodes, ncol = 2)
    lambda_prior_mean <- matrix(0, nrow = info$nrtasknodes, ncol = 2)
    lambda_prior_std <- matrix(2, nrow = info$nrtasknodes, ncol = 2)

    if (!is.null(priors)) {
        # Check for common pairs first
        if (all(c("beta", "theta", "lambda") %in% names(priors)) && length(priors$beta) == 2 && length(priors$theta) == 2 && length(priors$lambda) == 2 && !is.matrix(priors$theta) && !is.matrix(priors$lambda)) {
            beta_prior_mean[] <- priors$beta[1]
            beta_prior_std[] <- priors$beta[2]
            theta_prior_mean[] <- priors$theta[1]
            theta_prior_std[] <- priors$theta[2]
            lambda_prior_mean[] <- priors$lambda[1]
            lambda_prior_std[] <- priors$lambda[2]
        } else {
            # Check for individual arrays
            if (!is.null(priors$beta_mean)) beta_prior_mean <- matrix(priors$beta_mean, ncol = 1)
            if (!is.null(priors$beta_std)) beta_prior_std <- matrix(priors$beta_std, ncol = 1)

            if (!is.null(priors$theta_mean)) theta_prior_mean <- priors$theta_mean
            if (!is.null(priors$theta_std)) theta_prior_std <- priors$theta_std

            if (!is.null(priors$lambda_mean)) lambda_prior_mean <- priors$lambda_mean
            if (!is.null(priors$lambda_std)) lambda_prior_std <- priors$lambda_std
        }
    }

    constants$beta_prior_mean <- beta_prior_mean
    constants$beta_prior_std <- beta_prior_std
    constants$theta_prior_mean <- theta_prior_mean
    constants$theta_prior_std <- theta_prior_std
    constants$lambda_prior_mean <- lambda_prior_mean
    constants$lambda_prior_std <- lambda_prior_std

    # Inits
    beta_root_init <- rnorm(info$nrbetaroot, mean = 0, sd = 1)

    theta_init <- matrix(0, nrow = info$nrattributenodes, ncol = 2)
    if (info$nrattributenodes > info$nrbetaroot) {
        for (k in (info$nrbetaroot + 1):info$nrattributenodes) {
            theta_init[k, 1] <- runif(1, 0.2, 0.5)
            theta_init[k, 2] <- 0
        }
    }

    lambda_init <- matrix(0, nrow = info$nrtasknodes, ncol = 2)
    for (j in 1:info$nrtasknodes) {
        lambda_init[j, 1] <- runif(1, 0.5, 2.0)
        lambda_init[j, 2] <- rnorm(1, 0, 1)
    }

    attributenodes_init <- matrix(rbinom(nrparticipants * constants$CDMattnodesmax, 1, 0.5), nrow = nrparticipants, ncol = constants$CDMattnodesmax)

    # If continuous roots, enforce continuous initialization
    if (constants$isContinuousHO == 1) {
        for (m in 1:info$nrbetaroot) {
            attributenodes_init[, m] <- rnorm(nrparticipants, 0, 1)
        }
    }

    inits <- list(
        beta_root = beta_root_init,
        theta = theta_init,
        lambda = lambda_init,
        attributenodes = attributenodes_init
    )

    # Monitors
    monitors <- c("lambda", "attributenodes")
    if (constants$isContinuousHO == 0) monitors <- c(monitors, "beta_root")
    if (info$nrattributenodes > info$nrbetaroot) monitors <- c(monitors, "theta")

    list(constants = constants, inits = inits, monitors = monitors, data = list(X = X))
}
