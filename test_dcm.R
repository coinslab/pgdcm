library(dcmdata, lib.loc="locallib")
library(nimble)
devtools::load_all()

X_calib <- dtmr_data[1:100,]
Q <- dtmr_qmatrix
g_dcm <- QMatrix2iGraph(Q)

# Simulate calibration config
config_calib <- build_model_config(g_dcm, X_calib)

num_beta_roots <- config_calib$constants$nrbetaroot
b_mean <- rep(0, num_beta_roots)
b_std <- rep(2, num_beta_roots)

K <- config_calib$constants$nrattributenodes
J <- config_calib$constants$nrtasknodes

calibrated_theta_means <- matrix(0, nrow = K, ncol = 2)
calibrated_lambda_means <- matrix(0, nrow = J, ncol = 2)

scoring_priors <- list(
    beta_mean = b_mean,
    beta_std = b_std,
    theta_mean = calibrated_theta_means,
    theta_std = matrix(0.0001, nrow = K, ncol = 2),
    lambda_mean = calibrated_lambda_means,
    lambda_std = matrix(0.0001, nrow = J, ncol = 2)
)

# Simulate scoring config
config_score <- build_model_config(g_dcm, X_calib, priors = scoring_priors)

print(dim(config_score$constants$beta_prior_mean))
print(config_score$constants$beta_prior_mean)
print("nrbetaroot:")
print(config_score$constants$nrbetaroot)

# Try running nimble code compilation manually to trigger the error
model_code <- get(config_score$model_object)
model <- nimbleModel(
    code = model_code,
    constants = config_score$constants,
    data = config_score$data,
    inits = config_score$inits
)
