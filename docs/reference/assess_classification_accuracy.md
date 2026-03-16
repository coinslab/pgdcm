# Assess Classification Accuracy

Compares estimated skill mastery profiles against known true states to
calculate classification accuracy, Cohen's Kappa, and profile matching
rates. Useful for simulation studies or known-group diagnostics.

## Usage

``` r
assess_classification_accuracy(
  skill_profiles,
  true_data,
  mapping_list = NULL,
  threshold = 0.5,
  random_inspect = 10
)
```

## Arguments

- skill_profiles:

  An `I x K` matrix or dataframe of estimated mastery probabilities,
  typically the `skill_profiles` output from
  [`generate_summary_tables()`](generate_summary_tables.md).

- true_data:

  A dataframe containing the true mastery states (0 or 1).

- mapping_list:

  A named list mapping the expected model skill names to the column
  names in `true_data`. For example:
  `list("Addition" = "true_add", "Subtraction" = "true_sub")`.

- threshold:

  Numeric. The threshold used to binarize estimates. Default is 0.5.

- random_inspect:

  Integer. The number of random participants to print detailed
  comparisons for. Default is 10.

## Value

A list containing `metrics` (Skill-level accuracy and Kappa) and
`profile_accuracy` (Exact match rate across all mapped skills).
