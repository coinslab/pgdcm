# Check MCMC Convergence via Rhat

Evaluates if the chains have converged by extracting non-NA Rhat values
from a summary matrix and returning whether convergence was met along
with the largest Rhat value.

## Usage

``` r
check_rhat_convergence(summary_mx, threshold = 1.1)
```

## Arguments

- summary_mx:

  A matrix or data.frame (like from `MCMCsummary`) containing an `Rhat`
  column.

- threshold:

  Numeric. Maximum acceptable Rhat value (default is 1.1).

## Value

A list containing `converged` (boolean) and `max_rhat` (numeric).
