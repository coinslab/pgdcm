dir.create("locallib", showWarnings = FALSE)
.libPaths(c("locallib", .libPaths()))
install.packages("dcmdata", lib = "locallib", repos = "https://cloud.r-project.org")

library(dcmdata, lib.loc = "locallib")
library(nimble)
library(pgdcm) # Assuming devtools::load_all() or installation handles this
devtools::load_all()

X <- dtmr_data
Q <- dtmr_qmatrix
g <- QMatrix2iGraph(Q)
config <- build_model_config(g, X)
source(config$code_file)
model_code <- get(config$model_object)

# Suppress graphics device via pdf
pdf("vignettes/temp_generate.pdf")

prior_ppc_results <- run_predictive_check(
    config = config,
    obs_X = config$data$X,
    posterior_samples = NULL,
    n_sim = 50,
    prefix = "vignettes/Advanced_Prior",
    title = "PriorCheck"
)

mcmc_raw <- nimbleMCMC(
    code = model_code,
    constants = config$constants,
    data = config$data,
    inits = config$inits,
    monitors = config$monitors,
    nchains = 2,
    niter = 2000,
    nburnin = 500,
    summary = TRUE,
    samplesAsCodaMCMC = TRUE,
    WAIC = TRUE
)

res_mcmc <- coda::mcmc.list(mcmc_raw$samples)
res_clean <- filter_structural_nas(res_mcmc)

convergence_diag <- check_mcmc_convergence(
    chainlist = res_clean,
    blocksize = 50,
    burninperiod = 100
)

post_ppc_results <- run_predictive_check(
    config = config,
    obs_X = config$data$X,
    posterior_samples = res_clean,
    n_sim = 50,
    prefix = "vignettes/Advanced_Posterior",
    title = "PosteriorCheck"
)

dev.off()

results <- list(
    mcmc_raw = mcmc_raw,
    res_clean = res_clean,
    convergence_diag = convergence_diag,
    prior_ppc_results = prior_ppc_results,
    post_ppc_results = post_ppc_results,
    config = config
)

saveRDS(results, "Advanced_Tutorial_Results.rds")
print("Results successfully generated and saved to vignettes/Advanced_Tutorial_Results.rds!")
