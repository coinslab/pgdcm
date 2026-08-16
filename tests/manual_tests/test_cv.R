devtools::load_all()

data(dtmr) # or load it if it's there
X <- dtmr_data[1:20,]
Q <- dtmr_qmatrix

g <- QMatrix2iGraph(Q, compute = "dina")
config <- build_model_config(g, X)

# Run CV
res <- run_pgdcm_cv(config, k_folds = 2, estimation_config = list(niter = 50, nburnin = 10), nBootReps = 2)
print(res)
