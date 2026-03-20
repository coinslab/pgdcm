## ----setup, message=FALSE, warning=FALSE--------------------------------------
#| eval: false
# library(nimble)
# library(pgdcm)
# library(dcmdata)


## ----extract-data, message=FALSE, warning=FALSE-------------------------------
#| eval: false
# X <- dtmr_data
# Q <- dtmr_qmatrix


## ----peek-data, message=FALSE, warning=FALSE----------------------------------
#| eval: false
# # X should be N (students) x J (items)
# dim(X)
# head(X[, 1:6]) # first 6 columns
# 
# # Q should be J (items) x K (skills)
# dim(Q)
# head(Q)


## ----format-data, message=FALSE, warning=FALSE--------------------------------
#| eval: false
# # Restructure Matrix to an iGraph object
# g <- QMatrix2iGraph(Q)
# 
# # Link student responses to the Graph
# config <- build_model_config(g, X)


## ----execute-mcmc, eval=FALSE-------------------------------------------------
# results <- run_pgdcm_auto(
#     config = config,
#     prefix = "DINA_DTMR" # You can give any name here. This prefix is used while saving
#     # the prior predictive and posterior predictive simulation results.
# )
# 
# # Save the exact results to an RDS file to bypass future recomputation
# saveRDS(results, "assets/Beginner_Tutorial_Results.rds")


## ----load-cache, echo=FALSE, eval=TRUE, message=FALSE, warning=FALSE----------
# Hidden: silently load cached results so interpretation chunks render
results <- readRDS("assets/Beginner_Tutorial_Results.rds")
library(MCMCvis)


## ----skill-profiles, message=FALSE, warning=FALSE-----------------------------
# Each row = one student, each column = one skill
head(results$skill_profiles)


## ----item-params, message=FALSE, warning=FALSE--------------------------------
head(results$item_parameters)


## ----waic, message=FALSE, warning=FALSE---------------------------------------
results$WAIC


## ----groups-example, eval=FALSE-----------------------------------------------
# results <- run_pgdcm_auto(
#     config = config,
#     prefix = "DINA_DTMR",
#     return_groups = TRUE
# )


## ----load-mcmcvis, message=FALSE, warning=FALSE-------------------------------
#| eval: false
# library(MCMCvis)


## ----render-table, message=FALSE, warning=FALSE-------------------------------
# Retrieve a numerical summary table specifically for the 'lambda' item parameters
res <- MCMCsummary(results$samples, params = "lambda")
head(res) # only a few rows from res are displayed here.


## ----render-plot, fig.width=8, fig.height=6, message=FALSE, warning=FALSE-----
# Visually plot the 'lambda' parameter distributions
MCMCplot(results$samples, params = "lambda")

