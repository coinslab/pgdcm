## ----load-cache, echo=FALSE, eval=TRUE, message=FALSE, warning=FALSE----------
# Load cached results to avoid compiling MCMC on every Quarto render
# Source compute_M2() directly since pgdcm may not be installed during preview
source("../R/Utils_Statistics.R")
cached_results <- readRDS("assets/Advanced_Tutorial_Results.rds")
X <- cached_results$config$data$X
obsMean <- mean(X, na.rm = TRUE)
obsRowMeans <- rowMeans(X, na.rm = TRUE)
obsColMeans <- colMeans(X, na.rm = TRUE)
obsM2 <- compute_M2(X)


## -----------------------------------------------------------------------------
#| eval: false
# library(nimble)
# library(pgdcm)
# library(dcmdata)
# library(MCMCvis)
# 
# # Load data and Q-Matrix
# X <- dtmr_data
# Q <- dtmr_qmatrix
# 
# # Build the graphical structure
# g <- QMatrix2iGraph(Q)
# 
# # Generate Nimble configurations
# config <- build_model_config(g, X)


## -----------------------------------------------------------------------------
#| eval: false
# # The config object specifies the location of the generated code inside your library
# source(config$code_file)
# 
# # We extract the actual code object into memory
# model_code <- get(config$model_object)


## -----------------------------------------------------------------------------
#| eval: false
# prior_ppc_results <- run_predictive_check(
#     config = config,
#     obs_X = config$data$X,
#     posterior_samples = NULL, # Enforces PRIOR checking
#     n_sim = 50,
#     prefix = NULL, # NULL renders inline; set a string to save as PDF
#     title = "PriorCheck"
# )


## -----------------------------------------------------------------------------
#| eval: false
#| output: false
# mcmc_raw <- nimbleMCMC(
#     code = model_code, # The NIMBLE code we extracted earlier
#     constants = config$constants, # Fixed constants mapped from the Q-Matrix
#     data = config$data, # The isolated observational vectors
#     inits = config$inits, # Starter values for the Markov chain
#     monitors = config$monitors, # Variables we want NIMBLE to track
#     nchains = 2,
#     niter = 2000,
#     nburnin = 500,
#     summary = TRUE,
#     samplesAsCodaMCMC = TRUE, # Force output to a list format compatible with CODA
#     WAIC = TRUE # Calculate the Watanabe-Akaike Information Criterion
# )


## -----------------------------------------------------------------------------
#| eval: false
# mcmc_raw$WAIC


## -----------------------------------------------------------------------------
#| echo: false
#| eval: true
cat(paste("WAIC:", round(cached_results$mcmc_raw$WAIC$WAIC, 2)))
cat(paste("\npWAIC:", round(cached_results$mcmc_raw$WAIC$pWAIC, 2)))


## -----------------------------------------------------------------------------
#| eval: false
# # 1. Build the model object
# model <- nimbleModel(
#     code = model_code,
#     constants = config$constants,
#     data = config$data,
#     inits = config$inits
# )
# 
# # 2. Create a default MCMC configuration
# mcmc_conf <- configureMCMC(model, monitors = config$monitors)
# 
# # 3. Inspect the current sampler assignments
# print(mcmc_conf$getSamplers())
# 
# # 4. Customize: e.g., replace a specific sampler with a slice sampler
# # mcmc_conf$removeSamplers("beta_root[1]")
# # mcmc_conf$addSampler(target = "beta_root[1]", type = "slice")
# 
# # 5. Build, compile, and run
# mcmc_built <- buildMCMC(mcmc_conf)
# cmodel <- compileNimble(model)
# cmcmc <- compileNimble(mcmc_built, project = model)
# samples <- runMCMC(cmcmc, niter = 2000, nburnin = 500, nchains = 2,
#                    samplesAsCodaMCMC = TRUE)


## -----------------------------------------------------------------------------
#| eval: false
# # Convert raw samples to an MCMC list format
# res_mcmc <- mcmc.list(mcmc_raw$samples)
# 
# # Clean structural MCMC artifacts
# res_clean <- filter_structural_nas(res_mcmc)


## -----------------------------------------------------------------------------
#| eval: false
# convergence_diag <- check_mcmc_convergence(
#     chainlist = res_clean,
#     blocksize = 50,
#     burninperiod = 100
# )
# 
# print(paste("Algorithm fully converged:", convergence_diag$converged))


## -----------------------------------------------------------------------------
#| echo: false
#| eval: true
cat(paste("Algorithm fully converged:", cached_results$convergence_diag$converged))
cat(paste("\nMax relative error:", round(max(cached_results$convergence_diag$relerrors, na.rm = TRUE), 4)))


## -----------------------------------------------------------------------------
#| eval: false
# post_ppc_results <- run_predictive_check(
#     config = config,
#     obs_X = config$data$X,
#     posterior_samples = res_clean, # Uses trained inference
#     n_sim = 50,
#     prefix = NULL, # Renders plot inline in Quarto
#     title = "PosteriorCheck"
# )


## -----------------------------------------------------------------------------
#| eval: false
# # 1. Generate the raw summary matrix
# mcmc_summ <- MCMCvis::MCMCsummary(object = res_clean)
# 
# # 2. Extract original participant IDs for correct row mapping
# student_ids <- rownames(config$data$X)
# 
# # 3. Map Nimble parameters to human-readable names
# mapped_results <- map_pgdcm_parameters(
#     summary_mx = mcmc_summ,
#     config_obj = config,
#     student_names = student_ids
# )
# 
# # 4. Generate the final clean tables (Skill Profiles, Item Parameters)
# summary_tables <- generate_summary_tables(
#     mapped_results = mapped_results,
#     config_obj = config,
#     student_names = student_ids,
#     return_groups = TRUE # Enable this to explicitly extract skill profile clusters
# )
# 
# # Extract the skill profiles specifically
# skill_profiles <- summary_tables$skill_profiles
# group_patterns <- summary_tables$group_patterns


## -----------------------------------------------------------------------------
#| eval: false
# # Assess classification accuracy against known true profiles
# accuracy_results <- assess_classification_accuracy(
#     skill_profiles = skill_profiles,
#     true_data = dtmr_true_profiles,
#     mapping_list = list(
#         "referent_units" = "referent_units",
#         "partitioning_iterating" = "partitioning_iterating",
#         "appropriateness" = "appropriateness",
#         "multiplicative_comparison" = "multiplicative_comparison"
#     )
# )
# 
# # View the individual skill accuracies, Cohen's Kappa, and overall profile match rate
# print(accuracy_results$metrics)
# print(paste("Profile Correct Classification Rate:", accuracy_results$profile_accuracy))


## -----------------------------------------------------------------------------
#| eval: false
# # 1. Extract calibrated parameters from your previous estimation (Section 7)
# #    Filter mapped_results for theta (structural) and lambda (item) parameters
# theta_rows <- grepl("^theta", mapped_results$Parameter)
# lambda_rows <- grepl("^lambda", mapped_results$Parameter)
# 
# # Reshape posterior means into the required K x 2 and J x 2 matrices
# K <- config$constants$nrattributenodes  # number of skills
# J <- config$constants$nrtasknodes       # number of items
# calibrated_theta_means <- matrix(mapped_results$mean[theta_rows], nrow = K, ncol = 2)
# calibrated_lambda_means <- matrix(mapped_results$mean[lambda_rows], nrow = J, ncol = 2)
# 
# # 2. Build your highly informative scoring priors
# scoring_priors <- list(
#     # Keep the root attribute priors somewhat diffuse to allow new students to be scored
#     beta_mean = c(0),
#     beta_std = c(2),
# 
#     # "Lock in" your previously calibrated structural parameters (K x 2 matrix)
#     theta_mean = calibrated_theta_means,
#     theta_std = matrix(0.0001, nrow = nrow(calibrated_theta_means), ncol = 2),
# 
#     # "Lock in" your previously calibrated item parameters (J x 2 matrix)
#     lambda_mean = calibrated_lambda_means,
#     lambda_std = matrix(0.0001, nrow = nrow(calibrated_lambda_means), ncol = 2)
# )
# 
# # 3. Compile the new config for the new dataset
# config_scoring <- build_model_config(g, X_new_students, priors = scoring_priors)
# 
# # 4. Execute the automated workflow (it will sample with fixed items)
# scoring_results <- run_pgdcm_auto(config_scoring)
# 
# # Profile the new students!
# print(scoring_results$skill_profiles)

