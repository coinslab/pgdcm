# Get Prerequisite Gate Strength (Risk Difference)

Calculates the absolute difference between the Bottleneck Probability
and the Leap Probability.

## Usage

``` r
calc_risk_difference(results, skill)
```

## Arguments

- results:

  The full pgdcm results list object.

- skill:

  A string name or integer index.

## Value

A list containing the target name and posterior means/intervals for the
gate strength.

## Semantic Interpretation

\* \*\*High Value (\> 0.6)\*\*: The prerequisite is critically required.
Mastering the prerequisite creates a massive jump in the likelihood of
mastering the target skill. \* \*\*Low Value (\< 0.2)\*\*: A weak
structural connection. Having the prerequisite barely improves a
student's chances of getting the target skill, implying the theoretical
arrow in your DAG represents a weak or non-existent causal relationship.
