# Build Model Configuration for Scoring

Automatically isolates and structures the compiled structural and item
constraints from a calibrated model into a tightly locked scoring model
configuration.

## Usage

``` r
build_scoring_config(calib_results, calib_config, new_dataframe)
```

## Arguments

- calib_results:

  The list returned from `run_pgdcm_auto` containing
  `mapped_parameters`.

- calib_config:

  The model configuration object used to generate the calibrated model.

- new_dataframe:

  A `data.frame` of raw responses matching the new participants to
  score.

## Value

A configuration list prepared for `run_pgdcm_auto` execution.
