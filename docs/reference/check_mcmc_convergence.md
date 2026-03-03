# Check MCMC Convergence

Evaluates rough convergence metrics by comparing block averages.

## Usage

``` r
check_mcmc_convergence(chainlist, blocksize = 10, burninperiod = 1000)
```

## Arguments

- chainlist:

  An `mcmc.list`, matrix, or a list containing samples.

- blocksize:

  Numeric. Size of the blocks to average over. Default is 10.

- burninperiod:

  Numeric. Number of initial samples to discard as burn-in. Default is
  1000.

## Value

A list containing `avgparamvector`, `abserrors`, `relerrors`, and a
boolean `converged` flag.
