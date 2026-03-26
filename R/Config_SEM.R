# =============================================================================
# Config_SEM.R
# Description: Explicit constants and initialization definitions for Structural Equation Models.
# =============================================================================


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

    # Validate: all attributes must share a single compute type, and all tasks must share one
    att_sem_types <- unique(ifelse(att_computes %in% c("zscore", "continuous"), "zscore", att_computes))
    task_sem_types <- unique(ifelse(task_computes %in% c("zscore", "continuous"), "zscore", task_computes))

    if (length(att_sem_types) > 1) {
        stop("SEM Validation Error: All attribute nodes must share a single compute type, but found: ",
            paste(unique(att_computes), collapse = ", "), ". ",
            "The SEM model applies the same distribution to every node within a layer.",
            call. = FALSE
        )
    }
    if (length(task_sem_types) > 1) {
        stop("SEM Validation Error: All task nodes must share a single compute type, but found: ",
            paste(unique(task_computes), collapse = ", "), ". ",
            "The SEM model applies the same distribution to every node within a layer.",
            call. = FALSE
        )
    }

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

    # Extracting sparse edges to send as constants alongside the data
    edges <- which(info$matrix == 1, arr.ind = TRUE)
    zeros <- which(info$matrix == 0, arr.ind = TRUE)

    constants$num_edges <- nrow(edges)
    constants$edge_from <- edges[, 1]
    constants$edge_to <- edges[, 2]

    constants$num_zeros <- nrow(zeros)
    constants$zero_from <- zeros[, 1]
    constants$zero_to <- zeros[, 2]

    # Prior generation
    alpha_prior_mean <- rep(0, info$nrnodes)
    alpha_prior_std <- rep(2, info$nrnodes)

    if (nrow(edges) > 0) {
        beta_prior_mean <- rep(0, nrow(edges))
        beta_prior_std <- rep(2, nrow(edges))
    } else {
        beta_prior_mean <- numeric(0)
        beta_prior_std <- numeric(0)
    }

    if (!is.null(priors)) {
        if (all(c("alpha", "beta") %in% names(priors)) && length(priors$alpha) == 2 && length(priors$beta) == 2 && !is.matrix(priors$beta)) {
            alpha_prior_mean[] <- priors$alpha[1]
            alpha_prior_std[] <- priors$alpha[2]
            if (nrow(edges) > 0) {
                beta_prior_mean[] <- priors$beta[1]
                beta_prior_std[] <- priors$beta[2]
            }
        } else {
            if (!is.null(priors$alpha_mean)) alpha_prior_mean <- priors$alpha_mean
            if (!is.null(priors$alpha_std)) alpha_prior_std <- priors$alpha_std

            if (!is.null(priors$beta_mean) && nrow(edges) > 0) {
                for (e in 1:nrow(edges)) {
                    beta_prior_mean[e] <- priors$beta_mean[edges[e, "row"], edges[e, "col"]]
                }
            }
            if (!is.null(priors$beta_std) && nrow(edges) > 0) {
                for (e in 1:nrow(edges)) {
                    beta_prior_std[e] <- priors$beta_std[edges[e, "row"], edges[e, "col"]]
                }
            }
        }
    }

    constants$alpha_prior_mean <- alpha_prior_mean
    constants$alpha_prior_std <- alpha_prior_std
    constants$beta_prior_mean <- beta_prior_mean
    constants$beta_prior_std <- beta_prior_std

    # Sigma prior for continuous observed task nodes
    sigma_task_prior_mean <- 1.0
    sigma_task_prior_std <- 1.0
    if (!is.null(priors$sigma_task_mean)) sigma_task_prior_mean <- priors$sigma_task_mean
    if (!is.null(priors$sigma_task_std)) sigma_task_prior_std <- priors$sigma_task_std
    constants$sigma_task_prior_mean <- sigma_task_prior_mean
    constants$sigma_task_prior_std <- sigma_task_prior_std

    alpha_init <- rep(0, info$nrnodes)
    if (nrow(edges) > 0) {
        beta_edge_init <- rnorm(nrow(edges), 0.5, 0.5)
    } else {
        beta_edge_init <- numeric(0)
    }

    if (constants$SEMdoBinaryAttribute || constants$SEMdoPercentileAttribute) {
        attributenodes_init <- matrix(rbinom(nrparticipants * constants$CDMattnodesmax, 1, 0.5), nrow = nrparticipants, ncol = constants$CDMattnodesmax)
    } else {
        attributenodes_init <- matrix(rnorm(nrparticipants * constants$CDMattnodesmax), nrow = nrparticipants, ncol = constants$CDMattnodesmax)
    }

    inits <- list(
        alpha = alpha_init,
        beta_edge = beta_edge_init,
        attributenodes = attributenodes_init,
        sigma_task = 1.0
    )

    monitors <- c("alpha", "beta", "attributenodes", "sigma_task")

    if (constants$SEMdoZscoreTask == 1) {
        message("SEM Configuration: Globally auto-scaling continuous task observations to align with standard normal N(0,2) priors while preserving relative item difficulties.")
        X_mean <- mean(X, na.rm = TRUE)
        X_sd <- sd(X, na.rm = TRUE)
        X <- as.matrix((X - X_mean) / X_sd)
    }

    list(constants = constants, inits = inits, monitors = monitors, data = list(X = X))
}
