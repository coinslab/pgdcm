# Generate Specific Summary Tables

Generates skill profiles and item parameters tables from the mapped MCMC
results.

## Usage

``` r
generate_summary_tables(mapped_results, config_obj, student_names = NULL)
```

## Arguments

- mapped_results:

  The `data.frame` output from `map_pgdcm_parameters`.

- config_obj:

  The model configuration list returned by `build_model_config`.

- student_names:

  Optional character vector of student names. If NULL, generic IDs are
  used.

## Value

A list containing `skill_profiles` and `item_parameters` dataframes.
