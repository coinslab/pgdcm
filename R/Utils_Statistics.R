# =============================================================================
# Utils_Statistics.R
# Description: General Utility Functions unified for PGDCM and SEM architecture
# =============================================================================

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
    if (inherits(res, "mcmc.list")) {
        mat <- as.matrix(res)
        if (any(is.na(mat))) {
            print("WARNING: NA values found in MCMC samples. Filtering out structural NAs...")

            if (all(is.na(mat))) {
                stop("CRITICAL: All generated MCMC samples are NA. The model failed to sample completely.")
            }

            # Identify valid columns (columns that have ZERO NAs across all chains)
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

# ── map_pgdcm_parameters ─────────────────────────────────────────────────────
#' Map PGDCM Parameters to Readble Names
#'
#' Maps the MCMC parameter indices back to the actual string names
#' of items and skills provided during graph construction.
#'
#' @param summary_mx A matrix of summarized MCMC parameters (e.g., from \code{MCMCsummary}).
#' @param config_obj The model configuration list returned by \code{build_model_config}.
#' @param student_names An optional character vector of student names. If NULL, generic IDs are used.
#'
#' @return A \code{data.frame} combining the original summary with \code{Readable_Name} and \code{Type} columns.
#' @export
map_pgdcm_parameters <- function(summary_mx, config_obj, student_names = NULL) {
    # 1. Provide Generic IDs if none exist.
    if (is.null(student_names)) student_names <- 1:config_obj$constants$nrparticipants

    raw_names <- rownames(summary_mx)
    clean_names <- character(length(raw_names))
    types <- character(length(raw_names))

    # 2. Extract strictly ordered nodes directly from pgdcm's igraph object
    g <- config_obj$graph
    task_nodes <- igraph::V(g)[tolower(igraph::V(g)$type) == "task"]$name
    attr_nodes <- igraph::V(g)[tolower(igraph::V(g)$type) == "attribute"]$name

    # 3. Iterate through parameter trace names
    for (i in seq_along(raw_names)) {
        rn <- raw_names[i]

        # --- A. Lambda (Items/Tasks) ---
        if (grepl("^lambda\\[", rn)) {
            matches <- regmatches(rn, gregexpr("[0-9]+", rn))[[1]]
            j <- as.numeric(matches[1])
            col <- as.numeric(matches[2])

            if (j <= length(task_nodes)) {
                item_name <- task_nodes[j]
                param_type <- ifelse(col == 1, "Slope", "Intercept")

                clean_names[i] <- paste0(item_name, " - ", param_type)
                types[i] <- "Item Parameter"
            } else {
                clean_names[i] <- rn
                types[i] <- "Index Error"
            }
        }
        # --- B. Theta (Attribute Dependencies/Non-Roots) ---
        else if (grepl("^theta\\[", rn)) {
            matches <- regmatches(rn, gregexpr("[0-9]+", rn))[[1]]
            k <- as.numeric(matches[1])
            col <- as.numeric(matches[2])

            if (k <= length(attr_nodes)) {
                attr_name <- attr_nodes[k]
                param_type <- ifelse(col == 1, "Dependency on Parent", "Intercept")

                clean_names[i] <- paste0(attr_name, " - ", param_type)
                types[i] <- "Attribute Structure"
            } else {
                clean_names[i] <- rn
                types[i] <- "Index Error"
            }
        }
        # --- C. Beta Root (Root Attributes) ---
        else if (grepl("^beta_root\\[", rn)) {
            matches <- regmatches(rn, gregexpr("[0-9]+", rn))[[1]]
            k <- as.numeric(matches[1])

            if (k <= length(attr_nodes)) {
                attr_name <- attr_nodes[k]

                clean_names[i] <- paste0(attr_name, " - Prior/Intercept")
                types[i] <- "Root Structure"
            } else {
                clean_names[i] <- rn
            }
        }
        # --- D. Attribute Nodes (Students' true mastery traits) ---
        else if (grepl("^attributenodes\\[", rn)) {
            matches <- regmatches(rn, gregexpr("[0-9]+", rn))[[1]]
            s_idx <- as.numeric(matches[1]) # Student Row
            k <- as.numeric(matches[2]) # Attribute Column

            s_id <- "Unknown"
            if (s_idx <= length(student_names)) s_id <- student_names[s_idx]

            attr_name <- "Unknown"
            if (k <= length(attr_nodes)) attr_name <- attr_nodes[k]

            clean_names[i] <- paste0(s_id, " - ", attr_name)
            types[i] <- "Student Mastery"
        } else {
            clean_names[i] <- rn
            types[i] <- "Other"
        }
    }

    out_df <- data.frame(
        Raw_Param = rownames(summary_mx),
        Readable_Name = clean_names,
        Type = types
    )
    out_df <- cbind(out_df, as.data.frame(summary_mx))
    return(out_df)
}

# ── generate_summary_tables ──────────────────────────────────────────────────
#' Generate Specific Summary Tables
#'
#' Generates skill profiles and item parameters tables from the mapped MCMC results.
#'
#' @param mapped_results The \code{data.frame} output from \code{map_pgdcm_parameters}.
#' @param config_obj The model configuration list returned by \code{build_model_config}.
#' @param student_names Optional character vector of student names. If NULL, generic IDs are used.
#' @param threshold Numeric. The mastery probability threshold to use for latent class grouping. Default is 0.5.
#' @param return_groups Logical. If TRUE, calculates latent classes using \code{groupattributepatterns}. Default is FALSE.
#'
#' @return A list containing \code{skill_profiles} and \code{item_parameters} dataframes, and optionally \code{group_patterns}.
#' @export
generate_summary_tables <- function(mapped_results, config_obj, student_names = NULL, threshold = 0.5, return_groups = FALSE) {
    if (is.null(student_names)) student_names <- 1:config_obj$constants$nrparticipants

    g <- config_obj$graph
    task_nodes <- igraph::V(g)[tolower(igraph::V(g)$type) == "task"]$name
    attr_nodes <- igraph::V(g)[tolower(igraph::V(g)$type) == "attribute"]$name

    # 1. Skill Profiles (I x K matrix of mean mastery)
    student_mastery <- mapped_results[mapped_results$Type == "Student Mastery", ]

    skill_profiles <- matrix(NA, nrow = length(student_names), ncol = length(attr_nodes))
    rownames(skill_profiles) <- student_names
    colnames(skill_profiles) <- attr_nodes

    for (i in seq_along(student_names)) {
        for (k in seq_along(attr_nodes)) {
            rn <- paste0("^attributenodes\\[", i, ", ?", k, "\\]$")
            idx <- grep(rn, student_mastery$Raw_Param)
            if (length(idx) > 0) {
                skill_profiles[i, k] <- student_mastery$mean[idx[1]]
            }
        }
    }

    # 2. Item Parameters
    item_params <- mapped_results[mapped_results$Type == "Item Parameter", ]
    out_items <- data.frame(
        item = task_nodes,
        difficulty_mean = NA,
        difficulty_SD = NA,
        difficulty_Rhat = NA,
        discrimination_mean = NA,
        discrimination_SD = NA,
        discrimination_Rhat = NA,
        stringsAsFactors = FALSE
    )

    for (j in seq_along(task_nodes)) {
        # Difficulty (Intercept, col=2)
        diff_idx <- grep(paste0("^lambda\\[", j, ", ?2\\]$"), item_params$Raw_Param)
        if (length(diff_idx) > 0) {
            out_items$difficulty_mean[j] <- item_params$mean[diff_idx[1]]
            out_items$difficulty_SD[j] <- item_params$sd[diff_idx[1]]
            out_items$difficulty_Rhat[j] <- item_params$Rhat[diff_idx[1]]
        }

        # Discrimination (Slope, col=1)
        disc_idx <- grep(paste0("^lambda\\[", j, ", ?1\\]$"), item_params$Raw_Param)
        if (length(disc_idx) > 0) {
            out_items$discrimination_mean[j] <- item_params$mean[disc_idx[1]]
            out_items$discrimination_SD[j] <- item_params$sd[disc_idx[1]]
            out_items$discrimination_Rhat[j] <- item_params$Rhat[disc_idx[1]]
        }
    }

    # 3. Group Attribute Patterns (Latent Classes)
    group_patterns <- NULL
    if (return_groups) {
        group_patterns <- groupattributepatterns(skill_profiles, threshold = threshold)
    }

    return(list(
        skill_profiles = as.data.frame(skill_profiles),
        item_parameters = out_items,
        group_patterns = group_patterns
    ))
}

# ── groupattributepatterns ───────────────────────────────────────────────────
#' Group Participants by Attribute Mastery Patterns
#'
#' Takes a matrix of continuous mastery probabilities (e.g., from \code{skill_profiles})
#' and groups participants into discrete latent classes based on a provided threshold.
#'
#' @param attributenodes An \code{I x K} matrix or dataframe of participant masteries.
#' @param threshold Numeric. The probability cutoff above which a skill is considered mastered. Default is 0.5.
#'
#' @return A list of all possible $2^K$ groups, containing group \code{label}
#'   (the binary vector pattern) and \code{members} (row indices or names of participants).
#' @export
groupattributepatterns <- function(attributenodes, threshold = 0.5) {
    nrparticipants <- nrow(attributenodes)
    nrattributes <- ncol(attributenodes)

    # Compute All Possible Binary Attribute Patterns
    nrgroups <- 2^(nrattributes)
    binaryoptions <- replicate(nrattributes, 0:1, simplify = FALSE)
    attributevectorgrid <- expand.grid(binaryoptions)
    possibleattributepatterns <- as.matrix(attributevectorgrid)

    # Use participant names if they exist, otherwise use indices
    participant_labels <- rownames(attributenodes)
    if (is.null(participant_labels)) {
        participant_labels <- 1:nrparticipants
    }

    if (!is.null(colnames(attributenodes))) {
        colnames(possibleattributepatterns) <- colnames(attributenodes)
    }

    # Find rows in possibleattributepatterns which are present in attributenodes
    groupmembers <- list()
    classifiedattnodes <- matrix(as.numeric(as.matrix(attributenodes) > threshold), ncol = nrattributes, byrow = FALSE)

    for (groupid in 1:nrgroups) {
        groupval <- list()
        participantids <- c()

        for (i in 1:nrparticipants) {
            matchedi <- identical(as.numeric(classifiedattnodes[i, ]), as.numeric(possibleattributepatterns[groupid, ]))
            if (matchedi) {
                participantids <- c(participantids, participant_labels[i])
            }
        }

        groupval$members <- participantids
        groupval$label <- possibleattributepatterns[groupid, ]
        groupmembers[[paste(possibleattributepatterns[groupid, ], collapse = "")]] <- groupval
    }

    # Prepare grouping output
    return(groupmembers)
}

# ── assess_classification_accuracy ───────────────────────────────────────────
#' Assess Classification Accuracy
#'
#' Compares estimated skill mastery profiles against known true states to calculate
#' classification accuracy, Cohen's Kappa, and profile matching rates.
#' Useful for simulation studies or known-group diagnostics.
#'
#' @param skill_profiles An \code{I x K} matrix or dataframe of estimated mastery probabilities,
#'   typically the \code{skill_profiles} output from \code{generate_summary_tables()}.
#' @param true_data A dataframe containing the true mastery states (0 or 1).
#' @param mapping_list A named list mapping the expected model skill names to the column names
#'   in \code{true_data}. For example: \code{list("Addition" = "true_add", "Subtraction" = "true_sub")}.
#' @param threshold Numeric. The threshold used to binarize estimates. Default is 0.5.
#' @param random_inspect Integer. The number of random participants to print detailed comparisons for. Default is 10.
#'
#' @return A list containing \code{metrics} (Skill-level accuracy and Kappa) and
#'   \code{profile_accuracy} (Exact match rate across all mapped skills).
#' @export
assess_classification_accuracy <- function(skill_profiles, true_data, mapping_list = NULL, threshold = 0.5, random_inspect = 10) {
    if (is.null(mapping_list) || length(mapping_list) == 0) {
        stop("Must provide 'mapping_list' to link Model Attribute Names to True Column Names. e.g. list(Addition='true_add')")
    }

    # 1. Binarize Estimates
    prob_mx <- as.matrix(skill_profiles)
    est_class <- (prob_mx > threshold) * 1

    true_df <- as.data.frame(true_data)

    # 2. Align Rows (IDs)
    mod_ids <- rownames(prob_mx)
    true_ids <- if ("id" %in% colnames(true_df)) as.character(true_df$id) else rownames(true_df)

    common_ids <- intersect(mod_ids, true_ids)

    if (length(common_ids) == 0) {
        stop("No matching IDs between Model (rownames) and True Data! Cannot assess classification accuracy safely.")
    } else {
        message(paste("Matched", length(common_ids), "students by ID for accuracy assessment."))
        mod_idx <- match(common_ids, mod_ids)
        true_idx <- match(common_ids, true_ids)
    }

    n_common <- length(common_ids)

    # Storage for metrics
    skill_metrics <- data.frame(Skill = names(mapping_list), Accuracy = NA, Kappa = NA, stringsAsFactors = FALSE)

    message("\n--- Classification Accuracy ---")

    for (i in seq_along(mapping_list)) {
        mod_name <- names(mapping_list)[i]
        true_name <- mapping_list[[i]]

        if (!mod_name %in% colnames(prob_mx)) stop(paste("Model attribute", mod_name, "not found in skill_profiles."))
        if (!true_name %in% colnames(true_df)) stop(paste("Truth attribute", true_name, "not found in true_data."))

        y_est <- est_class[mod_idx, mod_name]
        y_true <- true_df[true_idx, true_name]

        # Accuracy
        acc <- mean(y_est == y_true, na.rm = TRUE)

        # Cohen's Kappa
        t_mat <- table(factor(y_est, levels = 0:1), factor(y_true, levels = 0:1))
        po <- sum(diag(t_mat)) / sum(t_mat)
        pe <- (sum(t_mat[1, ]) * sum(t_mat[, 1]) + sum(t_mat[2, ]) * sum(t_mat[, 2])) / sum(t_mat)^2
        kappa <- ifelse(pe == 1, 0, (po - pe) / (1 - pe))

        skill_metrics$Accuracy[i] <- round(acc, 3)
        skill_metrics$Kappa[i] <- round(kappa, 3)
    }

    print(skill_metrics)

    # 4. Profile Accuracy (Exact Vector Match)
    mod_cols <- names(mapping_list)
    true_cols <- unlist(mapping_list, use.names = FALSE)

    profiles_est <- apply(est_class[mod_idx, mod_cols, drop = FALSE], 1, paste, collapse = "")
    profiles_true <- apply(true_df[true_idx, true_cols, drop = FALSE], 1, paste, collapse = "")

    prof_acc <- mean(profiles_est == profiles_true, na.rm = TRUE)
    message(paste("Profile Correct Classification Rate:", round(prof_acc, 3)))

    # 5. Random Inspection
    if (random_inspect > 0) {
        n_inspect <- min(random_inspect, n_common)
        message(sprintf("\n--- Random Comparison of %d Students ---", n_inspect))

        set.seed(123)
        sample_locs <- sample(1:n_common, n_inspect)

        for (loc in sample_locs) {
            m_i <- mod_idx[loc]
            t_i <- true_idx[loc]
            tid <- common_ids[loc]

            message(paste("\nStudent ID:", tid))

            comp_df <- data.frame(
                Skill = names(mapping_list),
                Est_Prob = round(prob_mx[m_i, names(mapping_list)], 3),
                Est_Class = est_class[m_i, names(mapping_list)],
                True_State = as.integer(as.vector(t(true_df[t_i, true_cols]))),
                stringsAsFactors = FALSE
            )
            print(comp_df)
        }
        message("------------------------------------------------")
    }

    return(list(metrics = skill_metrics, profile_accuracy = prof_acc))
}
