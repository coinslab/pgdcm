# =============================================================================
# Inferences_Causal.R
# Description: Bridge module to export pgdcm imputed latent data to bnlearn
#              for exploratory causal discovery and Q-Matrix validation.
# =============================================================================

#' Export Imputed Data to bnlearn
#'
#' @description Extracts the latent skill profiles from a calibrated pgdcm model, 
#' binarizes them, and binds them with the raw item responses to create a fully
#' observed dataframe formatted for \code{bnlearn}. Also generates the required
#' structural blacklist enforcing task-to-skill and task-to-task edge prohibitions.
#'
#' @param results A fitted \code{pgdcm} results list containing \code{skill_profiles}.
#' @param threshold Numeric. The probability threshold used to binarize mastery (default 0.5).
#' @return A list containing \code{data} (a dataframe of factors) and \code{blacklist} (a 2-column matrix).
#' @export
export_to_bnlearn <- function(results, threshold = 0.5) {
  if (is.null(results$skill_profiles)) {
    stop("Error: The results object must contain 'skill_profiles' to export imputed data.")
  }
  if (is.null(results$config$data$X)) {
    stop("Error: The results object config must contain the raw task data matrix 'X'.")
  }
  
  # 1. Binarize Latent Skills
  prob_mx <- results$skill_profiles
  imputed_skills <- as.data.frame(ifelse(prob_mx >= threshold, 1, 0))
  
  # 2. Extract Raw Tasks
  raw_tasks <- as.data.frame(results$config$data$X)
  
  # Ensure column names are unique and match graph names
  g <- results$config$graph
  task_names <- igraph::V(g)[tolower(igraph::V(g)$type) == "task"]$name
  attr_names <- igraph::V(g)[tolower(igraph::V(g)$type) == "attribute"]$name
  
  if (ncol(imputed_skills) == length(attr_names)) colnames(imputed_skills) <- attr_names
  if (ncol(raw_tasks) == length(task_names)) colnames(raw_tasks) <- task_names
  
  # 3. Combine
  bn_data <- cbind(imputed_skills, raw_tasks)
  
  # 4. Convert all columns to factors (required by bnlearn for discrete BNs)
  # Level 0 and 1
  bn_data[] <- lapply(bn_data, function(x) factor(x, levels = c(0, 1)))
  
  # 5. Build Structural Blacklist
  # We forbid Tasks -> Attributes (Effects cannot cause Latent Traits)
  # We forbid Tasks -> Tasks (Local Independence assumption)
  blacklist_list <- list()
  
  # Tasks -> Attributes
  for (t_node in task_names) {
    for (a_node in attr_names) {
      blacklist_list[[length(blacklist_list) + 1]] <- c(from = t_node, to = a_node)
    }
  }
  
  # Tasks -> Tasks
  for (t1 in task_names) {
    for (t2 in task_names) {
      if (t1 != t2) {
        blacklist_list[[length(blacklist_list) + 1]] <- c(from = t1, to = t2)
      }
    }
  }
  
  blacklist_mx <- do.call(rbind, blacklist_list)
  
  return(list(
    data = bn_data,
    blacklist = blacklist_mx
  ))
}

#' Run Q-Matrix and Structural Discovery
#'
#' @description Uses \code{bnlearn}'s Hill-Climbing algorithm to discover the 
#' data-driven structural network linking Latent Skills and Tasks, providing an 
#' empirical validation of the Q-Matrix and Omega-Matrix.
#'
#' @param results A fitted \code{pgdcm} results list.
#' @param algorithm Character. The bnlearn algorithm to use (default "hc" for Hill-Climbing).
#' @param threshold Numeric. Binarization threshold for latent skills (default 0.5).
#' @param ... Additional arguments passed to the bnlearn algorithm (e.g., \code{score="bic"}).
#' @return A \code{bn} object representing the discovered directed acyclic graph.
#' @export
run_qmatrix_discovery <- function(results, algorithm = "hc", threshold = 0.5, ...) {
  if (!requireNamespace("bnlearn", quietly = TRUE)) {
    stop("Error: The 'bnlearn' package is required for causal discovery. Please install it with install.packages('bnlearn').", call. = FALSE)
  }
  
  bn_prep <- export_to_bnlearn(results, threshold)
  
  if (algorithm == "hc") {
    learned_net <- bnlearn::hc(x = bn_prep$data, blacklist = bn_prep$blacklist, ...)
    return(learned_net)
  } else if (algorithm == "tabu") {
    learned_net <- bnlearn::tabu(x = bn_prep$data, blacklist = bn_prep$blacklist, ...)
    return(learned_net)
  } else {
    stop(paste("Algorithm", algorithm, "is not supported by the wrapper. Use 'hc' or 'tabu'."))
  }
}
