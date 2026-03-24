# Get Curriculum Bottleneck Probability

Calculates the probability a student masters a skill GIVEN they have
perfectly acquired all its prerequisites.

## Usage

``` r
calc_prob_master_given_prereqs(results, skill)
```

## Arguments

- results:

  The full pgdcm results list object.

- skill:

  A string name (e.g., "partitioning_iterating") or integer index.

## Value

A list containing the target name, posterior mean probability, and 95

## Semantic Interpretation

\* \*\*High Value (\> 0.8)\*\*: The learning progression is working.
Once students get the prerequisites, they naturally acquire this target
skill. \* \*\*Low Value (\< 0.5)\*\*: A major curriculum bottleneck.
Even perfectly prepared students are failing to acquire this skill. This
implies the skill requires external knowledge not captured by the
prerequisites, or the instructional transition is poorly scaffolded.
