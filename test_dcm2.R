library(dcmdata, lib.loc="locallib")
library(nimble)
devtools::load_all()

X_calib <- dtmr_data[1:100,]
Q <- dtmr_qmatrix
g_dcm <- QMatrix2iGraph(Q)

config_calib <- build_model_config(g_dcm, X_calib)
num_beta_roots <- config_calib$constants$nrbetaroot
scoring_priors <- list(
    beta_mean = rep(0, num_beta_roots),
    beta_std = rep(2, num_beta_roots),
    theta_mean = matrix(0, nrow = 4, ncol = 2),
    theta_std = matrix(0.0001, nrow = 4, ncol = 2),
    lambda_mean = matrix(0, nrow = 27, ncol = 2),
    lambda_std = matrix(0.0001, nrow = 27, ncol = 2)
)

config_score <- build_model_config(g_dcm, X_calib, priors = scoring_priors)

source(config_score$code_file)
model_code <- get(config_score$model_object)
model <- nimbleModel(
    code = model_code,
    constants = config_score$constants,
    data = config_score$data,
    inits = config_score$inits
)
print("SUCCESS!")
