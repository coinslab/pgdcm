# Get Item Slip (False Negative) Probability

Calculates the probability a student answers this item INCORRECTLY
despite possessing all required skills (True Master).

## Usage

``` r
calc_item_slip_prob(results, item)
```

## Arguments

- results:

  The full pgdcm results list object.

- item:

  A string item ID or integer index.

## Value

A list containing the target item, posterior mean slip probability, and
95

## Semantic Interpretation

This is mathematically identical to (1 - True Mastery Probability). \*
\*\*High Value (\> 0.3)\*\*: A high slip rate indicates the item is
tricky, wordy, or prone to careless computational errors by students who
otherwise completely understand the math. \* \*\*Low Value (\< 0.1)\*\*:
Excellent item reliability. Masters almost never get this wrong by
accident.
