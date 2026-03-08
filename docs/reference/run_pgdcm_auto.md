# Run Integrated Workflow (Prior, MCMC, Posterior)

Orchestrates the complete end-to-end Bayesian estimation pipeline for
PGDCM and SEM. Computes prior predictive checks, compiles and runs
Nimble MCMC, assesses convergence, and generates posterior predictive
checks.

## Usage

``` r
run_pgdcm_auto(
  config,
  estimation_config = list(niter = 1000, nburnin = 100, chains = 2, prior_sims = NULL,
    post_sims = NULL),
  prefix = NULL
)
```

## Arguments

- config:

  Model configuration list from `build_model_config`.

- estimation_config:

  List of parameters controlling MCMC execution (`niter`, `nburnin`,
  `chains`, `prior_sims`, `post_sims`). The `prior_sims` and `post_sims`
  arguments control the number of simulated datasets drawn during Prior
  and Posterior Predictive Checking respectively. Passing `NULL`
  disables these checks entirely. Defaults to
  `list(niter = 1000, nburnin = 100, chains = 2, prior_sims = NULL, post_sims = NULL)`.

- prefix:

  Character. Descriptor prefix used for saving generated reports.
  Defaults to a timestamped string based on the model type.

## Value

A comprehensive list containing the raw `mcmc_out`, `samples` (cleaned),
`prior_ppc`, and `post_ppc` objects.
