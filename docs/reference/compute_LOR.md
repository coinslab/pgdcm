# Compute Log Odds Ratio Matrix

Computes the Log Odds Ratio (LOR) matrix with Haldane-Anscombe
correction for a given dataset directly from the response matrix to
robustly handle NAs.

## Usage

``` r
compute_LOR(mat)
```

## Arguments

- mat:

  A numeric matrix of responses (usually binary).

## Value

A numeric matrix representing the pairwise Log Odds Ratios.
