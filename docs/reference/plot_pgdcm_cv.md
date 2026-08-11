# Plot Posterior Predictive CV Results

Generates a confusion matrix and a jittered scatterplot of the
cross-validation predictions against the true observed responses. This
requires the CV to have been run with `return_samples = TRUE`.

## Usage

``` r
plot_pgdcm_cv(cv_output, config)
```

## Arguments

- cv_output:

  The list returned by `run_pgdcm_cv` (with `return_samples = TRUE`).

- config:

  The original model configuration object used to generate the data.

## Value

Invisibly returns a list containing accuracy, confusion matrix, observed
values, and simulated predictive means.
