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

A nested list containing exact Posterior/Prior Predictive P-values
(PPPs) and their corresponding observed discrepancy values:

- `Global_Fit`: Global matrix means.

- `Item_Fit`: Item column means (Proportion correct).

- `Person_Fit`: Participant row means (Total score).

- `Edge_Fit`: Pairwise Log Odds Ratios (LOR) and Joint Co-occurrences
  (M2).

Each metric is returned as a list containing `value` (the observed
statistic) and `ppp` (the predictive p-value).
