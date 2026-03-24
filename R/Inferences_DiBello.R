# =============================================================================
# Inferences_DiBello.R
# Description: User-facing diagnostic queries for DiBello Cognitive Diagnostic Models.
# These functions compute exact posterior probabilities and differences directly
# from MCMC traces, mapping string names robustly to graph indices.
# =============================================================================



#' Validate Discrete Binary Assumption
#' @description Aborts the function if the MCMC samples contain continuous (fractional) 
#' latent trait draws, as DiBello logical queries only apply to binary skills.
validate_discrete_assumption <- function(samples) {
  attr_cols <- grep("^attributenodes\\[", colnames(samples), value = TRUE)
  if (length(attr_cols) > 0) {
    if (!all(samples[, attr_cols[1]] %in% c(0, 1))) {
      stop("Error: This query requires discrete binary skills (DiBelloBN/DCM). Your model returned continuous fractional traits. For continuous traits, please use standard IRT functions instead.")
    }
  }
}

#' Resolve Human-Readable Skill Name to Integer Index safely via Mapped Parameters
resolve_skill <- function(results, skill) {
  if (is.numeric(skill)) return(list(index = skill, name = paste("Skill", skill)))
  
  if ("mapped_parameters" %in% names(results)) {
    pattern <- paste0(" - ", skill, "$")
    hits <- grep(pattern, results$mapped_parameters$Readable_Name)
    if (length(hits) > 0) {
      raw_name <- results$mapped_parameters$Raw_Param[hits[1]]
      idx_str <- sub(".*\\[\\d+, (\\d+)\\].*", "\\1", raw_name)
      if (grepl("^\\d+$", idx_str)) {
        return(list(index = as.integer(idx_str), name = skill))
      }
    }
  }
  if ("skill_profiles" %in% names(results)) {
    idx <- which(colnames(results$skill_profiles) == skill)
    if (length(idx) > 0) return(list(index = idx, name = skill))
  }
  stop(paste("Skill '", skill, "' not found in results mapping.", sep=""))
}

#' Resolve Human-Readable Item Name to Integer Index safely via Mapped Parameters
resolve_item <- function(results, item) {
  if (is.numeric(item)) return(list(index = item, name = paste("Item", item)))
  item_str <- as.character(item)
  
  if ("mapped_parameters" %in% names(results)) {
    target_name <- paste0(item_str, " - Slope")
    hits <- which(results$mapped_parameters$Readable_Name == target_name)
    if (length(hits) > 0) {
      raw_name <- results$mapped_parameters$Raw_Param[hits[1]]
      idx_str <- sub(".*\\[(\\d+), 1\\].*", "\\1", raw_name)
      if (grepl("^\\d+$", idx_str)) {
        return(list(index = as.integer(idx_str), name = item_str))
      }
    }
  }
  if ("item_parameters" %in% names(results)) {
    idx <- which(results$item_parameters$item == item_str)
    if (length(idx) > 0) return(list(index = idx, name = item_str))
  }
  stop(paste("Item '", item_str, "' not found in results mapping.", sep=""))
}

# =============================================================================
# 1. Structural/Curriculum Queries
# =============================================================================

#' Get Curriculum Bottleneck Probability
#' 
#' @description Calculates the probability a student masters a skill GIVEN they have perfectly acquired all its prerequisites.
#' @param results The full pgdcm results list object.
#' @param skill A string name (e.g., "partitioning_iterating") or integer index.
#' @return A list containing the target name, posterior mean probability, and 95% Credible Interval.
#' @section Semantic Interpretation:
#' * **High Value (> 0.8)**: The learning progression is working. Once students get the prerequisites, they naturally acquire this target skill.
#' * **Low Value (< 0.5)**: A major curriculum bottleneck. Even perfectly prepared students are failing to acquire this skill. This implies the skill requires external knowledge not captured by the prerequisites, or the instructional transition is poorly scaffolded.
#' @export
calc_prob_master_given_prereqs <- function(results, skill) {
  s <- resolve_skill(results, skill)
  samples <- as.matrix(results$samples)
  validate_discrete_assumption(samples)
  
  slope_col <- paste0("theta[", s$index, ", 1]")
  intercept_col <- paste0("theta[", s$index, ", 2]")
  
  if (!all(c(slope_col, intercept_col) %in% colnames(samples))) stop("Skill is a root node (no prereqs).")
  
  probs <- plogis(samples[, slope_col] - samples[, intercept_col])
  
  return(list(
    metric = "Bottleneck Probability (Prereqs Met)",
    skill_target = s$name,
    mean_prob = mean(probs),
    ci_95 = quantile(probs, probs = c(0.025, 0.975))
  ))
}

#' Get Prerequisite "Leap" Probability
#' 
#' @description Calculates the probability a student masters a skill WITHOUT having acquired its prerequisites.
#' @param results The full pgdcm results list object.
#' @param skill A string name or integer index.
#' @return A list containing the target name, posterior mean probability, and 95% Credible Interval.
#' @section Semantic Interpretation:
#' * **High Value (> 0.5)**: A curriculum "leap" or bypass. Students are figuring out this skill without needing the prerequisites you specified. This implies your theoretical graph (DAG) might be incorrect, or the skill relies heavily on unmodeled outside common-sense knowledge.
#' * **Low Value (< 0.2)**: A strict prerequisite. Students who lack the prerequisite essentially have zero chance of leaping or guessing their way into mastering this skill.
#' @export
calc_prob_master_given_no_prereqs <- function(results, skill) {
  s <- resolve_skill(results, skill)
  samples <- as.matrix(results$samples)
  validate_discrete_assumption(samples)
  
  intercept_col <- paste0("theta[", s$index, ", 2]")
  probs <- plogis(-samples[, intercept_col])
  
  return(list(
    metric = "Leap Probability (No Prereqs Met)",
    skill_target = s$name,
    mean_prob = mean(probs),
    ci_95 = quantile(probs, probs = c(0.025, 0.975))
  ))
}

#' Get Prerequisite Gate Strength (Risk Difference)
#' 
#' @description Calculates the absolute difference between the Bottleneck Probability and the Leap Probability.
#' @param results The full pgdcm results list object.
#' @param skill A string name or integer index.
#' @return A list containing the target name and posterior means/intervals for the gate strength.
#' @section Semantic Interpretation:
#' * **High Value (> 0.6)**: The prerequisite is critically required. Mastering the prerequisite creates a massive jump in the likelihood of mastering the target skill.
#' * **Low Value (< 0.2)**: A weak structural connection. Having the prerequisite barely improves a student's chances of getting the target skill, implying the theoretical arrow in your DAG represents a weak or non-existent causal relationship.
#' @export
calc_risk_difference <- function(results, skill) {
  s <- resolve_skill(results, skill)
  samples <- as.matrix(results$samples)
  validate_discrete_assumption(samples)
  
  slope_col <- paste0("theta[", s$index, ", 1]")
  intercept_col <- paste0("theta[", s$index, ", 2]")
  
  bottleneck <- plogis(samples[, slope_col] - samples[, intercept_col])
  leap <- plogis(-samples[, intercept_col])
  gate <- bottleneck - leap
  
  return(list(
    metric = "Prerequisite Gate Strength (Risk Difference)",
    skill_target = s$name,
    mean_gate_strength = mean(gate),
    ci_95 = quantile(gate, probs = c(0.025, 0.975)),
    mean_bottleneck_prob = mean(bottleneck),
    mean_leap_prob = mean(leap)
  ))
}

# =============================================================================
# 2. Item-Level Diagnostic Queries
# =============================================================================

#' Get Item Guessing (False Positive) Probability
#' 
#' @description Calculates the probability a student answers this item correctly WITHOUT having the required skills (Non-Master).
#' @param results The full pgdcm results list object.
#' @param item A string item ID (e.g., "1") or integer index.
#' @return A list containing the target item, posterior mean guessing probability, and 95% Credible Interval.
#' @section Semantic Interpretation:
#' * **High Value (> 0.3)**: The item is too "guessable" or uses a flawed multiple-choice distractor. Non-masters can easily fake their way to a correct answer.
#' * **Low Value (< 0.1)**: Excellent item security. Students who lack the skills cannot guess the answer.
#' @export
calc_item_guessing_prob <- function(results, item) {
  it <- resolve_item(results, item)
  samples <- as.matrix(results$samples)
  intercept_col <- paste0("lambda[", it$index, ", 2]")
  probs <- plogis(-samples[, intercept_col])
  
  return(list(
    metric = "Item Guessing Probability",
    item_target = it$name,
    mean_guessing_prob = mean(probs),
    ci_95 = quantile(probs, probs = c(0.025, 0.975))
  ))
}

#' Get Item True Mastery Probability
#' 
#' @description Calculates the probability a student answers this item correctly GIVEN they possess all required skills (True Master).
#' @param results The full pgdcm results list object.
#' @param item A string item ID (e.g., "1") or integer index.
#' @return A list containing the target item, posterior mean mastery probability, and 95% Credible Interval.
#' @section Semantic Interpretation:
#' * **High Value (> 0.8)**: Excellent item alignment. True Masters can reliably demonstrate their proficiency cleanly on this item.
#' * **Low Value (< 0.5)**: A flawed or "slipping" item. Even true Masters often fail this item, suggesting the question is confusingly worded, computationally exhausting, or requires an unmodeled secondary skill (like advanced reading comprehension).
#' @export
calc_item_true_positive_prob <- function(results, item) {
  it <- resolve_item(results, item)
  samples <- as.matrix(results$samples)
  slope_col <- paste0("lambda[", it$index, ", 1]")
  intercept_col <- paste0("lambda[", it$index, ", 2]")
  probs <- plogis(samples[, slope_col] - samples[, intercept_col])
  
  return(list(
    metric = "Item True Mastery Probability",
    item_target = it$name,
    mean_mastering_prob = mean(probs),
    ci_95 = quantile(probs, probs = c(0.025, 0.975))
  ))
}

#' Get Item Slip (False Negative) Probability
#' 
#' @description Calculates the probability a student answers this item INCORRECTLY despite possessing all required skills (True Master).
#' @param results The full pgdcm results list object.
#' @param item A string item ID or integer index.
#' @return A list containing the target item, posterior mean slip probability, and 95% Credible Interval.
#' @section Semantic Interpretation:
#' This is mathematically identical to (1 - True Mastery Probability).
#' * **High Value (> 0.3)**: A high slip rate indicates the item is tricky, wordy, or prone to careless computational errors by students who otherwise completely understand the math.
#' * **Low Value (< 0.1)**: Excellent item reliability. Masters almost never get this wrong by accident.
#' @export
calc_item_slip_prob <- function(results, item) {
  it <- resolve_item(results, item)
  samples <- as.matrix(results$samples)
  slope_col <- paste0("lambda[", it$index, ", 1]")
  intercept_col <- paste0("lambda[", it$index, ", 2]")
  
  probs <- 1 - plogis(samples[, slope_col] - samples[, intercept_col])
  
  return(list(
    metric = "Item Slip (False Negative) Probability",
    item_target = it$name,
    mean_slip_prob = mean(probs),
    ci_95 = quantile(probs, probs = c(0.025, 0.975))
  ))
}

#' Get Item Discrimination Index (Probability Gap)
#' 
#' @description Calculates the absolute probability difference between a True Master answering correctly and a Non-Master guessing correctly. This is the Item-level equivalent of Gate Strength.
#' @param results The full pgdcm results list object.
#' @param item A string item ID or integer index.
#' @return A list containing the target item, posterior mean gap, and 95% Credible Interval.
#' @section Semantic Interpretation:
#' * **High Value (> 0.6)**: The item discriminates incredibly well. Masters are vastly more likely to get it right than non-masters.
#' * **Low Value (< 0.2)**: A weak item. Masters and non-masters have practically the same chance of answering correctly.
#' @export
calc_item_discrimination_index <- function(results, item) {
  it <- resolve_item(results, item)
  samples <- as.matrix(results$samples)
  slope_col <- paste0("lambda[", it$index, ", 1]")
  intercept_col <- paste0("lambda[", it$index, ", 2]")
  
  master_probs <- plogis(samples[, slope_col] - samples[, intercept_col])
  guessing_probs <- plogis(-samples[, intercept_col])
  gap <- master_probs - guessing_probs
  
  return(list(
    metric = "Item Discrimination Index (Probability Gap)",
    item_target = it$name,
    mean_gap = mean(gap),
    ci_95 = quantile(gap, probs = c(0.025, 0.975)),
    mean_master_prob = mean(master_probs),
    mean_guessing_prob = mean(guessing_probs)
  ))
}

# =============================================================================
# 3. Aggregate Diagnostic Wrappers
# =============================================================================

#' Generate Item Diagnostics Table
#' 
#' @description Computes True Mastery, Slip, and Guessing probabilities for all items.
#' @param results The full pgdcm results object.
#' @return A data.frame containing item-level diagnostic metrics.
#' @export
generate_item_diagnostics <- function(results) {
  if (!"item_parameters" %in% names(results)) stop("results$item_parameters not found.")
  items <- as.character(unique(results$item_parameters$item))
  J <- length(items)
  
  df <- data.frame(
    Item = items,
    Guessing_Mean = rep(NA_real_, J),
    Guessing_CI_Lower = rep(NA_real_, J),
    Guessing_CI_Upper = rep(NA_real_, J),
    Slip_Mean = rep(NA_real_, J),
    Slip_CI_Lower = rep(NA_real_, J),
    Slip_CI_Upper = rep(NA_real_, J),
    TrueMastery_Mean = rep(NA_real_, J),
    TrueMastery_CI_Lower = rep(NA_real_, J),
    TrueMastery_CI_Upper = rep(NA_real_, J),
    Discrimination_Index_Mean = rep(NA_real_, J),
    Discrimination_CI_Lower = rep(NA_real_, J),
    Discrimination_CI_Upper = rep(NA_real_, J),
    stringsAsFactors = FALSE
  )
  
  for (j in 1:J) {
    try({
      g <- calc_item_guessing_prob(results, items[j])
      df$Guessing_Mean[j] <- g$mean_guessing_prob
      df$Guessing_CI_Lower[j] <- g$ci_95[1]
      df$Guessing_CI_Upper[j] <- g$ci_95[2]
    }, silent = TRUE)
    
    try({
      s <- calc_item_slip_prob(results, items[j])
      df$Slip_Mean[j] <- s$mean_slip_prob
      df$Slip_CI_Lower[j] <- s$ci_95[1]
      df$Slip_CI_Upper[j] <- s$ci_95[2]
    }, silent = TRUE)
    
    try({
      tm <- calc_item_true_positive_prob(results, items[j])
      df$TrueMastery_Mean[j] <- tm$mean_mastering_prob
      df$TrueMastery_CI_Lower[j] <- tm$ci_95[1]
      df$TrueMastery_CI_Upper[j] <- tm$ci_95[2]
    }, silent = TRUE)
    
    try({
      idx <- calc_item_discrimination_index(results, items[j])
      df$Discrimination_Index_Mean[j] <- idx$mean_gap
      df$Discrimination_CI_Lower[j] <- idx$ci_95[1]
      df$Discrimination_CI_Upper[j] <- idx$ci_95[2]
    }, silent = TRUE)
  }
  return(df)
}

#' Generate Skill Diagnostics Table
#' 
#' @description Computes structural probabilities and gate strengths for all skills, handling Root nodes and Continuous traits elegantly.
#' @param results The full pgdcm results object.
#' @return A data.frame containing skill-level structural metrics.
#' @export
generate_skill_diagnostics <- function(results) {
  if (!"skill_profiles" %in% names(results)) stop("results$skill_profiles not found.")
  skills <- colnames(results$skill_profiles)
  K <- length(skills)
  samples <- as.matrix(results$samples)
  
  df <- data.frame(
    Skill = skills,
    Type = rep("Unknown", K),
    Is_Continuous = rep(FALSE, K),
    BaseRate_Mean = rep(NA_real_, K),
    Prob_Given_All_Prereqs_Mean = rep(NA_real_, K),
    Prob_Given_No_Prereqs_Mean = rep(NA_real_, K),
    GateStrength_Mean = rep(NA_real_, K),
    GateStrength_CI_Lower = rep(NA_real_, K),
    GateStrength_CI_Upper = rep(NA_real_, K),
    stringsAsFactors = FALSE
  )
  
  for (k in 1:K) {
    s_idx <- resolve_skill(results, skills[k])$index
    
    # Check if continuous
    attr_col <- paste0("attributenodes[1, ", s_idx, "]")
    if (attr_col %in% colnames(samples)) {
      if (!all(samples[, attr_col] %in% c(0, 1))) {
        df$Is_Continuous[k] <- TRUE
      }
    }
    
    is_root <- paste0("beta_root[", s_idx, "]") %in% colnames(samples)
    
    if (is_root) {
      df$Type[k] <- "Root"
      if (!df$Is_Continuous[k]) {
        root_col <- paste0("beta_root[", s_idx, "]")
        if (root_col %in% colnames(samples)) {
          probs <- plogis(samples[, root_col])
          df$BaseRate_Mean[k] <- mean(probs)
        }
      }
    } else {
      df$Type[k] <- "Dependent"
      if (!df$Is_Continuous[k]) {
        try({
          b <- calc_prob_master_given_prereqs(results, skills[k])
          df$Prob_Given_All_Prereqs_Mean[k] <- b$mean_prob
        }, silent = TRUE)
        
        try({
          l <- calc_prob_master_given_no_prereqs(results, skills[k])
          df$Prob_Given_No_Prereqs_Mean[k] <- l$mean_prob
        }, silent = TRUE)
        
        try({
          g <- calc_risk_difference(results, skills[k])
          df$GateStrength_Mean[k] <- g$mean_gate_strength
          df$GateStrength_CI_Lower[k] <- g$ci_95[1]
          df$GateStrength_CI_Upper[k] <- g$ci_95[2]
        }, silent = TRUE)
      }
    }
  }
  return(df)
}
