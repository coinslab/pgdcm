# Configure DCM Initialization and Constants

Generates the necessary Nimble `constants`, `inits`, and `monitors`
specifically tailored for Diagnostic Classification Models (DCMs).

## Usage

``` r
configure_dcm(info, X, priors = NULL)
```

## Arguments

- info:

  Graph structural properties from `get_graph_info`.

- X:

  A numeric matrix representing the observational participant data.

- priors:

  Optional list of prior specifications. Can be provided as common pairs
  (e.g.,
  `list(beta = c(mean, std), theta = c(mean, std), lambda = c(mean, std))`)
  or individual parameter arrays (e.g.,
  `list(beta_mean = c(...), beta_std = c(...), theta_mean = matrix(...), ...)`).
  Semantic meanings: `beta` represents the root attributes (initial
  probabilities), `theta` represents structural attribute transitions
  (dependencies between skills), and `lambda` represents item parameters
  (slopes and intercepts). If `NULL`, default priors (mean 0, std 2) are
  generated. Passing a standard deviation of `0.0001` or similar
  effectively acts as a point distribution, enabling the use of `pgdcm`
  as a scoring-only model when parameter means are supplied from a
  previous calibration.

## Value

A list with `constants`, `inits`, `monitors`, and `data`.
