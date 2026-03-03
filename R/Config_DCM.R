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
#'
#' @return A list with \code{constants}, \code{inits}, \code{monitors}, and \code{data}.
#' @keywords internal
configure_dcm <- function(info, X) {
    nrparticipants <- nrow(X)

    # Determine if root attributes are continuous (Higher-Order, MIRT, IRT structures)
    roots <- info$attr_computes[1:info$nrbetaroot]
    is_continuous_ho <- as.numeric(all(roots %in% c("zscore", "continuous")))

    constants <- list(
        nrparticipants = nrparticipants,
        nrtasknodes = info$nrtasknodes,
        nrattributenodes = info$nrattributenodes,
        nrnodes = info$nrnodes,
        CDMmatrix = info$matrix,
        betapriormean = 0,
        betapriorstd = 2,
        nrbetaroot = info$nrbetaroot,
        isDINA = info$isDINA,
        isDINO = info$isDINO,
        isDINM = info$isDINM,
        isContinuousHO = is_continuous_ho
    )

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

    attributenodes_init <- matrix(rbinom(nrparticipants * info$nrattributenodes, 1, 0.5), nrow = nrparticipants, ncol = info$nrattributenodes)

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
