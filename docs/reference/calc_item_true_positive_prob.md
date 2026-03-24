# Get Item True Mastery Probability

Calculates the probability a student answers this item correctly GIVEN
they possess all required skills (True Master).

## Usage

``` r
calc_item_true_positive_prob(results, item)
```

## Arguments

- results:

  The full pgdcm results list object.

- item:

  A string item ID (e.g., "1") or integer index.

## Value

A list containing the target item, posterior mean mastery probability,
and 95

## Semantic Interpretation

\* \*\*High Value (\> 0.8)\*\*: Excellent item alignment. True Masters
can reliably demonstrate their proficiency cleanly on this item. \*
\*\*Low Value (\< 0.5)\*\*: A flawed or "slipping" item. Even true
Masters often fail this item, suggesting the question is confusingly
worded, computationally exhausting, or requires an unmodeled secondary
skill (like advanced reading comprehension).
