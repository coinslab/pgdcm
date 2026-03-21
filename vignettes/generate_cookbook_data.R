# generate_cookbook_data.R
# This script executes the exact commands from Cookbook.qmd to generate 
# the underlying full MCMC results for the four core psychometric models.
# Warning: Running this script may take a significant amount of time and memory.

dir.create("locallib", showWarnings = FALSE)
.libPaths(c("locallib", .libPaths()))

if (!requireNamespace("dcmdata", quietly = TRUE)) {
    install.packages("dcmdata", lib = "locallib", repos = "https://cloud.r-project.org")
}

library(dcmdata, lib.loc = "locallib")
library(nimble)
library(pgdcm) # Ensure package is loaded or use devtools::load_all()
# devtools::load_all()

# ----------------------------------------------------------------------------
# Setup Data
# ----------------------------------------------------------------------------
X <- dtmr_data
Q <- dtmr_qmatrix
item_names <- colnames(X)[-1]
estimation_cfg <- list(niter = 10000, nburnin = 1000, chains = 2, prior_sims = 25, post_sims = 25)

# ----------------------------------------------------------------------------
# 1. Unidimensional IRT Model
# ----------------------------------------------------------------------------
print("Building IRT Model...")
g_irt <- build_irt_graph(task_names = item_names)
config_irt <- build_model_config(g_irt, X)
res_IRT <- run_pgdcm_auto(
    config = config_irt,
    prefix = "IRT",
    estimation_config = estimation_cfg
)
saveRDS(res_IRT, "vignettes/IRT_results.rds")

# ----------------------------------------------------------------------------
# 2. Traditional Diagnostic Classification Model (DCM)
# ----------------------------------------------------------------------------
print("Building DCM Model...")
g_dcm <- QMatrix2iGraph(Q)
config_dcm <- build_model_config(g_dcm, X)
res_DCM <- run_pgdcm_auto(
    config = config_dcm,
    prefix = "DCM",
    estimation_config = estimation_cfg
)
saveRDS(res_DCM, "vignettes/DCM_results.rds")

# ----------------------------------------------------------------------------
# 3. Attribute Hierarchy DCM (AH-DCM)
# ----------------------------------------------------------------------------
print("Building AH-DCM Model...")
# Loads the pre-edited strict hierarchical causal graph structure
g_ah <- read_graph("vignettes/AH_DCM.graphml", format = "graphml")
config_ah <- build_model_config(g_ah, X)
res_AH <- run_pgdcm_auto(
    config = config_ah,
    prefix = "AH-DCM",
    estimation_config = estimation_cfg
)
saveRDS(res_AH, "vignettes/AH_DCM_results.rds")

# ----------------------------------------------------------------------------
# 4. Higher-Order DCM (HO-DCM)
# ----------------------------------------------------------------------------
print("Building HO-DCM Model...")
# Loads the specifically crafted HO-DCM topology
g_ho <- read_graph("vignettes/HO_DCM.graphml", format = "graphml")
config_ho <- build_model_config(g_ho, X)
res_HO <- run_pgdcm_auto(
    config = config_ho,
    prefix = "HO-DCM",
    estimation_config = estimation_cfg
)
saveRDS(res_HO, "vignettes/HO_DCM_results.rds")

print("All heavy result objects generated and saved!")
