# Filter Structural NAs from MCMC Samples

Removes columns from MCMC samples that are entirely NA. This often
happens for structural constraints like Root Node Thetas in independent
models.

## Usage

``` r
filter_structural_nas(res)
```

## Arguments

- res:

  An `mcmc.list` or matrix object containing MCMC samples.

## Value

The cleaned `mcmc.list` or matrix with completely NA columns removed.
