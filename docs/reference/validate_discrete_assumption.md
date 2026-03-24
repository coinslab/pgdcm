# Validate Discrete Binary Assumption

Aborts the function if the MCMC samples contain continuous (fractional)
latent trait draws, as DiBello logical queries only apply to binary
skills.

## Usage

``` r
validate_discrete_assumption(samples)
```
