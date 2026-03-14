# Run Predictive Check (Prior or Posterior)

Simulates responses from the specified Nimble model using either priors
or a provided posterior distribution matrix. Generates corresponding
diagnostic plots.

## Usage

``` r
run_predictive_check(
  config,
  obs_X,
  posterior_samples = NULL,
  n_sim = 50,
  prefix = "Untitled",
  title = "PPC"
)
```

## Arguments

- config:

  Model configuration list from `build_model_config`.

- obs_X:

  Numeric matrix of observed data to compare against.

- posterior_samples:

  Optional `mcmc.list` or matrix of posterior samples. If `NULL`,
  simulates priors.

- n_sim:

  Numeric. Number of simulations to draw. Default is 50.

- prefix:

  Character or `NULL`. Prefix for the output plot filename. If `NULL`,
  plots render inline instead of saving to PDF.

- title:

  Character. String used for labeling (e.g., "PriorPPC").

## Value

A list containing the simulated and observed statistics.
