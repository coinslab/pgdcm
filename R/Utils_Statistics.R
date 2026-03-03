# =============================================================================
# Utils_Statistics.R
# Description: General Utility Functions unified for PGDCM and SEM architecture
# =============================================================================
library(coda)

# ── compute_M2 ───────────────────────────────────────────────────────────────
#' Compute Second-Order Moment Matrix
#'
#' Computes the second-order moment matrix (uncentered covariance/co-occurrence)
#' for a given matrix (usually binary responses).
#'
#' @param mat A numeric matrix of responses.
#'
#' @return A numeric matrix representing the second-order moments.
#' @export
compute_M2 <- function(mat) {
    n_cols <- ncol(mat)
    M2 <- matrix(0, nrow = n_cols, ncol = n_cols)
    for (j in 1:n_cols) {
        for (k in 1:n_cols) {
            M2[j, k] <- mean(mat[, j] * mat[, k], na.rm = TRUE)
        }
    }
    return(M2)
}

# ── filter_structural_nas ────────────────────────────────────────────────────
#' Filter Structural NAs from MCMC Samples
#'
#' Removes columns from MCMC samples that are entirely NA.
#' This often happens for structural constraints like Root Node Thetas in independent models.
#'
#' @param res An \code{mcmc.list} or matrix object containing MCMC samples.
#'
#' @return The cleaned \code{mcmc.list} or matrix with completely NA columns removed.
#' @export
filter_structural_nas <- function(res) {
    if (inherits(res, "mcmc.list") && any(is.na(as.matrix(res)))) {
        print("WARNING: NA values found in MCMC samples. Filtering out structural NAs...")

        # Identify valid columns (columns that have ZERO NAs on first chain)
        mat <- as.matrix(res[[1]])
        valid_cols <- colSums(is.na(mat)) == 0

        # Subset the mcmc.list
        res_clean <- res[, valid_cols, drop = FALSE]

        if (any(is.na(as.matrix(res_clean)))) {
            print("CRITICAL: NAs persist even after removing structural columns. Model might be broken.")
            print(head(as.matrix(res_clean)[, is.na(as.matrix(res_clean)[1, ])]))
            return(res_clean)
        } else {
            print("Structural NAs successfully removed.")
            return(res_clean)
        }
    }
    # Return original if no NAs
    return(res)
}

# ── check_mcmc_convergence ───────────────────────────────────────────────────
#' Check MCMC Convergence
#'
#' Evaluates rough convergence metrics by comparing block averages.
#'
#' @param chainlist An \code{mcmc.list}, matrix, or a list containing samples.
#' @param blocksize Numeric. Size of the blocks to average over. Default is 10.
#' @param burninperiod Numeric. Number of initial samples to discard as burn-in. Default is 1000.
#'
#' @return A list containing \code{avgparamvector}, \code{abserrors}, \code{relerrors}, and a boolean \code{converged} flag.
#' @export
check_mcmc_convergence <- function(chainlist, blocksize = 10, burninperiod = 1000) {
    numericalepsilon <- 1e-8
    convergeinfo <- list()

    if (inherits(chainlist, "mcmc.list")) {
        list_chain <- chainlist
        nrchains <- length(chainlist)
    } else if (inherits(chainlist, "matrix")) {
        list_chain <- list(chainlist)
        nrchains <- 1
    } else {
        if (!is.null(chainlist$samples)) {
            list_chain <- chainlist$samples
            nrchains <- length(chainlist$samples)
        } else {
            list_chain <- list(chainlist)
            nrchains <- 1
        }
    }

    nrsamples <- nrow(list_chain[[1]])
    paramdim <- ncol(list_chain[[1]])

    # Compute Average Chain
    averagechain <- matrix(0, nrow = nrsamples, ncol = paramdim)
    for (chainid in 1:nrchains) {
        chainmx <- list_chain[[chainid]]
        averagechain <- averagechain + chainmx / nrchains
    }

    # Construct a list of parameter block averages
    startk <- burninperiod + blocksize
    if (startk < nrsamples) {
        nrblocks <- nrsamples - startk + 1
        averageparamblock <- matrix(0, nrow = nrblocks, ncol = paramdim)
        for (k in startk:nrsamples) {
            j <- k - startk + 1
            paramblockj <- averagechain[(k - blocksize + 1):k, 1:paramdim]
            averageparamblock[j, 1:paramdim] <- colMeans(paramblockj)
        }

        convergeinfo$avgparamvector <- colMeans(averageparamblock)
        convergeinfo$abserrors <- apply(averageparamblock, 2, sd)
        convergeinfo$relerrors <- abs(convergeinfo$abserrors) / (numericalepsilon + abs(convergeinfo$avgparamvector))

        if (!is.null(colnames(list_chain[[1]]))) {
            names(convergeinfo$avgparamvector) <- colnames(list_chain[[1]])
            names(convergeinfo$abserrors) <- colnames(list_chain[[1]])
            names(convergeinfo$relerrors) <- colnames(list_chain[[1]])
        }

        convergeinfo$converged <- all(convergeinfo$relerrors < 0.1, na.rm = TRUE)
    } else {
        convergeinfo$converged <- FALSE
        print("Warning: Burn-in + blocksize exceeds available samples. Cannot check convergence block.")
    }

    return(convergeinfo)
}
