# Generate Specific Summary Tables

Generates skill profiles and item parameters tables from the mapped MCMC
results.

## Usage

``` r
generate_summary_tables(
  mapped_results,
  config_obj,
  student_names = NULL,
  threshold = 0.5,
  return_groups = FALSE
)
```

## Arguments

- mapped_results:

  The `data.frame` output from `map_pgdcm_parameters`.

- config_obj:

  The model configuration list returned by `build_model_config`.

- student_names:

  Optional character vector of student names. If NULL, generic IDs are
  used.

- threshold:

  Numeric. The mastery probability threshold to use for latent class
  grouping. Default is 0.5.

- return_groups:

  Logical. If TRUE, calculates latent classes using
  `groupattributepatterns`. Default is FALSE.

## Value

A list containing `skill_profiles` and `item_parameters` dataframes, and
optionally `group_patterns`.
