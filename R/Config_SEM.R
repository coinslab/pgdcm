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
#'
#' @return A list with \code{constants}, \code{inits}, \code{monitors}, and \code{data}.
#' @export
configure_sem <- function(info, X) {
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
        betapriormean = 0,
        betapriorstd = 2,
        attdim = info$nrattributenodes,
        SEMdoZscoreAttribute = as.numeric("zscore" %in% att_computes || "continuous" %in% att_computes),
        SEMdoPercentileAttribute = as.numeric("percentile" %in% att_computes),
        SEMdoBinaryAttribute = as.numeric("binary" %in% att_computes),
        SEMdoZscoreTask = as.numeric("zscore" %in% task_computes || "continuous" %in% task_computes),
        SEMdoPercentileTask = as.numeric("percentile" %in% task_computes),
        SEMdoBinaryTask = as.numeric("binary" %in% task_computes)
    )

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
        attributenodes_init <- matrix(rbinom(nrparticipants * info$nrattributenodes, 1, 0.5), nrow = nrparticipants, ncol = info$nrattributenodes)
    } else {
        attributenodes_init <- matrix(rnorm(nrparticipants * info$nrattributenodes), nrow = nrparticipants, ncol = info$nrattributenodes)
    }

    inits <- list(
        alpha = alpha_init,
        beta = beta_init,
        attributenodes = attributenodes_init
    )

    monitors <- c("alpha", "beta", "attributenodes")

    list(constants = constants, inits = inits, monitors = monitors, data = list(X = X))
}
