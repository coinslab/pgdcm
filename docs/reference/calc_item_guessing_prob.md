# Get Item Guessing (False Positive) Probability

Calculates the probability a student answers this item correctly WITHOUT
having the required skills (Non-Master).

## Usage

``` r
calc_item_guessing_prob(results, item)
```

## Arguments

- results:

  The full pgdcm results list object.

- item:

  A string item ID (e.g., "1") or integer index.

## Value

A list containing the target item, posterior mean guessing probability,
and 95

## Semantic Interpretation

\* \*\*High Value (\> 0.3)\*\*: The item is too "guessable" or uses a
flawed multiple-choice distractor. Non-masters can easily fake their way
to a correct answer. \* \*\*Low Value (\< 0.1)\*\*: Excellent item
security. Students who lack the skills cannot guess the answer.
