# Get Item Discrimination Index (Probability Gap)

Calculates the absolute probability difference between a True Master
answering correctly and a Non-Master guessing correctly. This is the
Item-level equivalent of Gate Strength.

## Usage

``` r
calc_item_discrimination_index(results, item)
```

## Arguments

- results:

  The full pgdcm results list object.

- item:

  A string item ID or integer index.

## Value

A list containing the target item, posterior mean gap, and 95

## Semantic Interpretation

\* \*\*High Value (\> 0.6)\*\*: The item discriminates incredibly well.
Masters are vastly more likely to get it right than non-masters. \*
\*\*Low Value (\< 0.2)\*\*: A weak item. Masters and non-masters have
practically the same chance of answering correctly.
