# Simulate Data for Parameter Recovery

Generates simulated response data and latent attributes based on a
provided model configuration. Can simulate from priors or fixed true
parameters.

## Usage

``` r
simulate_data(config, parameters = NULL, seed = NULL)
```

## Arguments

- config:

  A model configuration list returned by `build_model_config`.

- parameters:

  Optional list of exact parameter values to use (e.g., `lambda`,
  `theta`, `beta_root`). If `NULL`, parameters are drawn randomly from
  the model's priors.

- seed:

  Optional integer to set the random seed for reproducibility.

## Value

A list containing:

- `X`: The simulated \$N J\$ binary response matrix.

- `attributes`: The simulated \$N K\$ latent attribute matrix.

- `parameters`: A list of the parameters used to generate the data.
