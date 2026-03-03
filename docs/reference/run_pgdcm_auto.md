# Run Integrated Workflow (Prior, MCMC, Posterior)

Orchestrates the complete end-to-end Bayesian estimation pipeline for
PGDCM and SEM. Computes prior predictive checks, compiles and runs
Nimble MCMC, assesses convergence, and generates posterior predictive
checks.

## Usage

``` r
run_pgdcm_auto(config, estimation_config, prefix = "Unified_Pipeline")
```

## Arguments

- config:

  Model configuration list from `build_model_config`.

- estimation_config:

  List of parameters controlling MCMC execution (`niter`, `nburnin`,
  `chains`, `prior_sims`, `post_sims`).

- prefix:

  Character. Descriptor prefix used for saving generated reports.

## Value

A comprehensive list containing the raw `mcmc_out`, `samples` (cleaned),
`prior_ppc`, and `post_ppc` objects.
