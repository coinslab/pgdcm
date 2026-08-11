# Compute Empirical Reliability Metrics

Calculates three standard Cognitive Diagnostic Model reliability metrics
based on posterior mastery probabilities: Marginal Reliability,
Classification Accuracy, and Classification Consistency.

## Usage

``` r
compute_empirical_reliability(skill_profiles)
```

## Arguments

- skill_profiles:

  An `N x K` matrix or dataframe of continuous mastery probabilities
  (e.g., from `generate_summary_tables`).

## Value

A data.frame containing the metrics for each skill/attribute.
