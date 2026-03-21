# calculate_accuracy.R
# This script demonstrates how the classification accuracy was explicitly calculated 
# from the MCMC results for the Cookbook table.

library(pgdcm)
library(dcmdata)

# 1. Load the pre-processed lightweight cookbook data (or original full .rds results)
cookbook_data <- readRDS("cookbook_data.rds")
res_DCM <- cookbook_data$DCM
res_AH <- cookbook_data$AH
res_HO <- cookbook_data$HO

# 2. Define exactly which skills map to which simulated traits in dtmr_true_profiles
skill_mapping <- list(
    "referent_units" = "referent_units",
    "partitioning_iterating" = "partitioning_iterating",
    "appropriateness" = "appropriateness",
    "multiplicative_comparison" = "multiplicative_comparison"
)

# 3. Helper function that pulls the MCMC skill profile means from the raw summary object
get_skill_profiles <- function(res) {
    rn <- rownames(res$mcmc_out$summary$all.chains)
    att_rn <- rn[grepl("^attributenodes", rn)]
    
    s <- as.numeric(stringr::str_extract(att_rn, "(?<=\\[)\\d+"))
    k <- as.numeric(stringr::str_extract(att_rn, "\\d+(?=\\])"))
    
    df <- data.frame(s = s, k = k, rn = att_rn, stringsAsFactors = FALSE)
    df$val <- res$mcmc_out$summary$all.chains[df$rn, "mean"]
    df <- df[order(df$s, df$k), ]
    
    mat <- matrix(df$val, nrow = max(df$s), ncol = max(df$k), byrow = TRUE)
    
    # Subsets to exactly 4 attributes to securely match Q-matrix skills
    num_skills <- length(skill_mapping)
    if (ncol(mat) > num_skills) {
        mat <- mat[, 1:num_skills, drop = FALSE]
    }
    
    colnames(mat) <- c("referent_units", "partitioning_iterating", "appropriateness", "multiplicative_comparison")
    return(as.data.frame(mat))
}

# 4. Assess accuracy against ground truth "dtmr_true_profiles" included in dcmdata
get_acc <- function(res) {
    profiles <- get_skill_profiles(res)
    acc <- pgdcm::assess_classification_accuracy(
        skill_profiles = profiles,
        true_data = dcmdata::dtmr_true_profiles,
        mapping_list = skill_mapping
    )
    # The output from assess_classification_accuracy consists of raw metric stats and total match %
    return(c(acc$metrics$Accuracy, acc$profile_accuracy))
}

# 5. Extract tables dynamically
acc_tbl <- data.frame(
    Metric = c(names(skill_mapping), "Overall Profile Match"),
    `DCM` = get_acc(res_DCM),
    `AH-DCM` = get_acc(res_AH),
    `HO-DCM` = get_acc(res_HO),
    check.names = FALSE
)

print(acc_tbl)
