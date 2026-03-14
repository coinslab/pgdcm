# Map PGDCM Parameters to Readble Names

Maps the MCMC parameter indices back to the actual string names of items
and skills provided during graph construction.

## Usage

``` r
map_pgdcm_parameters(summary_mx, config_obj, student_names = NULL)
```

## Arguments

- summary_mx:

  A matrix of summarized MCMC parameters (e.g., from `MCMCsummary`).

- config_obj:

  The model configuration list returned by `build_model_config`.

- student_names:

  An optional character vector of student names. If NULL, generic IDs
  are used.

## Value

A `data.frame` combining the original summary with `Readable_Name` and
`Type` columns.
