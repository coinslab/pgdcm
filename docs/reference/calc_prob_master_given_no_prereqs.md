# Get Prerequisite "Leap" Probability

Calculates the probability a student masters a skill WITHOUT having
acquired its prerequisites.

## Usage

``` r
calc_prob_master_given_no_prereqs(results, skill)
```

## Arguments

- results:

  The full pgdcm results list object.

- skill:

  A string name or integer index.

## Value

A list containing the target name, posterior mean probability, and 95

## Semantic Interpretation

\* \*\*High Value (\> 0.5)\*\*: A curriculum "leap" or bypass. Students
are figuring out this skill without needing the prerequisites you
specified. This implies your theoretical graph (DAG) might be incorrect,
or the skill relies heavily on unmodeled outside common-sense knowledge.
\* \*\*Low Value (\< 0.2)\*\*: A strict prerequisite. Students who lack
the prerequisite essentially have zero chance of leaping or guessing
their way into mastering this skill.
