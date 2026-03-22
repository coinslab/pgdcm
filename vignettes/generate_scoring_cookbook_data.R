# generate_scoring_cookbook_data.R
# This script executes a calibration and scoring workflow to generate
# the underlying full MCMC results and fit/accuracy metrics for the four core
# psychometric models on a split-half dataset.
# Warning: Running this script may take a significant amount of time and memory.

dir.create("locallib", showWarnings = FALSE)
.libPaths(c("locallib", .libPaths()))

if (!requireNamespace("dcmdata", quietly = TRUE)) {
    install.packages("dcmdata", lib = "locallib", repos = "https://cloud.r-project.org")
}

library(dcmdata, lib.loc = "locallib")
library(nimble)
# library(pgdcm)
devtools::load_all() # Load the package locally for development/vignette usage

# Create a clean sub-folder for output artifacts to prevent root clutter
out_dir <- "vignettes/scoring_results"
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

# ----------------------------------------------------------------------------
# Setup Data
# ----------------------------------------------------------------------------
# We randomize the rows (shuffle participants) with a consistent seed
set.seed(2026)
N <- nrow(dtmr_data)
shuffled_idx <- sample(1:N)

# Shuffle data
X_shuffled <- dtmr_data[shuffled_idx, ]

# Dynamically match the true profiles to the exact shuffled IDs
matched_idx <- match(as.character(X_shuffled[[1]]), as.character(dtmr_true_profiles[[1]]))
true_profiles_shuffled <- dtmr_true_profiles[matched_idx, ]

# Overwrite the base R indexing row names with the actual String IDs so that
# the internal auto-mapper safely labels the output columns for accuracy validation
rownames(X_shuffled) <- as.character(X_shuffled[[1]])
rownames(true_profiles_shuffled) <- as.character(true_profiles_shuffled[[1]])

half <- floor(N / 2)
X_calib <- X_shuffled[1:half, ]
X_score <- X_shuffled[(half + 1):N, ]
true_calib <- true_profiles_shuffled[1:half, ]
true_score <- true_profiles_shuffled[(half + 1):N, ]

Q <- dtmr_qmatrix
item_names <- colnames(X_shuffled)[-1]
estimation_cfg <- list(niter = 10000, nburnin = 1000, chains = 2, prior_sims = NULL, post_sims = NULL)

skills_map <- list(
    "referent_units" = "referent_units",
    "partitioning_iterating" = "partitioning_iterating",
    "appropriateness" = "appropriateness",
    "multiplicative_comparison" = "multiplicative_comparison"
)

results_summary <- data.frame(
    Model = character(),
    Phase = character(),
    WAIC = numeric(),
    pWAIC = numeric(),
    Profile_Accuracy = numeric(),
    stringsAsFactors = FALSE
)

# Helper function to run calibration and scoring
run_and_score_model <- function(model_name, graph_obj) {
    print(paste("=========================================="))
    print(paste("Starting", model_name, "Calibration..."))
    print(paste("=========================================="))

    # ---------------- 1. Calibration ----------------
    config_calib <- build_model_config(graph_obj, X_calib)

    res_calib <- run_pgdcm_auto(
        config = config_calib,
        prefix = paste0(out_dir, "/", model_name, "_Calib"),
        estimation_config = estimation_cfg
    )

    # Assess calibration accuracy (Skip for IRT)
    if (model_name == "IRT") {
        acc_calib_val <- NA
    } else {
        acc_calib <- assess_classification_accuracy(
            skill_profiles = res_calib$skill_profiles,
            true_data = true_calib,
            mapping_list = skills_map
        )
        acc_calib_val <- acc_calib$profile_accuracy
    }

    # Add calibration results to the dataframe
    results_summary <<- rbind(results_summary, data.frame(
        Model = model_name,
        Phase = "Calibration",
        WAIC = res_calib$WAIC$WAIC,
        pWAIC = res_calib$WAIC$pWAIC,
        Profile_Accuracy = acc_calib_val,
        stringsAsFactors = FALSE
    ))

    # ---------------- 2. Extract Priors ----------------
    print(paste("=========================================="))
    print(paste("Starting", model_name, "Scoring..."))
    print(paste("=========================================="))

    # Compile the base scoring configuration dynamically holding fixed architecture constraints
    config_score <- build_scoring_config(calib_results = res_calib, calib_config = config_calib, new_dataframe = X_score)

    res_score <- run_pgdcm_auto(
        config = config_score,
        prefix = paste0(out_dir, "/", model_name, "_Score"),
        estimation_config = estimation_cfg
    )

    # Assess scoring accuracy (Skip for IRT)
    if (model_name == "IRT") {
        acc_score_val <- NA
    } else {
        acc_score <- assess_classification_accuracy(
            skill_profiles = res_score$skill_profiles,
            true_data = true_score,
            mapping_list = skills_map
        )
        acc_score_val <- acc_score$profile_accuracy
    }

    # Add scoring results to the dataframe
    results_summary <<- rbind(results_summary, data.frame(
        Model = model_name,
        Phase = "Scoring",
        WAIC = res_score$WAIC$WAIC,
        pWAIC = res_score$WAIC$pWAIC,
        Profile_Accuracy = acc_score_val,
        stringsAsFactors = FALSE
    ))
}

# ----------------------------------------------------------------------------
# 1. Unidimensional IRT Model
# ----------------------------------------------------------------------------
print("Building IRT Model...")
g_irt <- build_irt_graph(task_names = item_names)
run_and_score_model("IRT", g_irt)

# ----------------------------------------------------------------------------
# 2. Traditional Diagnostic Classification Model (DCM)
# ----------------------------------------------------------------------------
print("Building DCM Model...")
g_dcm <- QMatrix2iGraph(Q)
run_and_score_model("DCM", g_dcm)

# ----------------------------------------------------------------------------
# 3. Attribute Hierarchy DCM (AH-DCM)
# ----------------------------------------------------------------------------
print("Building AH-DCM Model...")
g_ah <- read_graph("vignettes/AH_DCM.graphml", format = "graphml")
plot(g_ah)
run_and_score_model("AH-DCM", g_ah)

# ----------------------------------------------------------------------------
# 4. Higher-Order DCM (HO-DCM)
# ----------------------------------------------------------------------------
print("Building HO-DCM Model...")
g_ho <- read_graph("vignettes/HO_DCM.graphml", format = "graphml")
plot(g_ho)
run_and_score_model("HO-DCM", g_ho)

# ----------------------------------------------------------------------------
# Output Results
# ----------------------------------------------------------------------------
csv_path <- paste0(out_dir, "/model_comparisons.csv")
write.csv(results_summary, file = csv_path, row.names = FALSE)

print("All heavy result objects generated and saved!")
print(paste("Comparison CSV successfully exported to:", csv_path))
print(results_summary)
