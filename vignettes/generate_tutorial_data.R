dir.create("locallib", showWarnings = FALSE)
.libPaths(c("locallib", .libPaths()))
install.packages("dcmdata", lib = "locallib", repos = "https://cloud.r-project.org")

library(dcmdata, lib.loc = "locallib")
library(nimble)
devtools::load_all()

X <- dtmr_data
Q <- dtmr_qmatrix
g <- QMatrix2iGraph(Q)
config <- build_model_config(g, X)

# Using fewer iterations for testing/caching to keep the website size fast while maintaining structure
results <- run_pgdcm_auto(
    config = config,
    estimation_config = list(niter = 10000, nburnin = 1000, chains = 2, prior_sims = NULL, post_sims = NULL),
    prefix = "vignettes/DCM_Beginner_Workflow"
)

saveRDS(results, "vignettes/Beginner_Tutorial_Results.rds")
print("Results successfully generated and saved to vignettes/Beginner_Tutorial_Results.rds!")

# Assess classification accuracy using true profiles
print("Assessing classification accuracy...")
accuracy_results <- assess_classification_accuracy(
    skill_profiles = results$skill_profiles,
    true_data = dtmr_true_profiles,
    mapping_list = list(
        "referent_units" = "referent_units",
        "partitioning_iterating" = "partitioning_iterating",
        "appropriateness" = "appropriateness",
        "multiplicative_comparison" = "multiplicative_comparison"
    )
)
print("Accuracy check complete.")
