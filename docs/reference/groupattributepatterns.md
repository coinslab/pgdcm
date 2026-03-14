# Group Participants by Attribute Mastery Patterns

Takes a matrix of continuous mastery probabilities (e.g., from
`skill_profiles`) and groups participants into discrete latent classes
based on a 0.5 threshold.

## Usage

``` r
groupattributepatterns(attributenodes)
```

## Arguments

- attributenodes:

  An `I x K` matrix or dataframe of participant masteries.

## Value

A list of all possible \$2^K\$ groups, containing group `label` (the
binary vector pattern) and `members` (row indices or names of
participants).
