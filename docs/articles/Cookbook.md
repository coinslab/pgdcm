# Model Cookbook

## Overview

Every model in `pgdcm` follows the same three-step workflow:

1.  **Build a graph** - define the relationships between skills and
    items.
2.  **Configure** - call `build_model_config(g, X)` to prepare the
    Bayesian network.
3.  **Estimate** - call
    [`run_pgdcm_auto()`](../reference/run_pgdcm_auto.md) to run MCMC and
    collect results.

The *only* thing that changes from one model to the next is how you
construct the graph in Step 1. This cookbook provides copy-paste recipes
for the four core model families, then compares their results side by
side on the DTMR dataset.

> **Prerequisites**
>
> This guide assumes familiarity with `pgdcm` basics. If you are new to
> the package, start with the [Beginner Tutorial](Beginner_Tutorial.md).
> For finer control over priors, samplers, and diagnostics, see the
> [Advanced Tutorial](Advanced_Tutorial.md).

## Setup

``` r
library(nimble)
library(pgdcm)
library(dcmdata)
library(igraph)

# --- Data ---
X <- dtmr_data
Q <- dtmr_qmatrix
item_names <- colnames(X)[-1] # drop the student-ID column
```

------------------------------------------------------------------------

## Recipes

### Recipe 1 - Unidimensional IRT

**When to use:** You want to treat the assessment as measuring a single
continuous ability. This is the simplest baseline - no Q-matrix
required.

[`build_irt_graph()`](../reference/build_irt_graph.md) creates a
star-shaped graph: one continuous latent node (“Theta”) connected to
every item.

``` r
# --- Build graph ---
g <- build_irt_graph(task_names = item_names)

# Inspect
plot(g)
get_NodesTable(g)
get_EdgesTable(g)

# --- Estimate ---
config <- build_model_config(g, X)
results <- run_pgdcm_auto(
    config = config,
    prefix = "IRT",
    estimation_config = list(
        niter = 10000, nburnin = 1000, chains = 2,
        prior_sims = 25, post_sims = 25
    )
)
results$WAIC
```

------------------------------------------------------------------------

### Recipe 2 - Traditional DCM

**When to use:** You have a Q-matrix and want to estimate independent,
discrete skill mastery for each student. This is the standard diagnostic
classification model with no structural relationships between skills.

[`QMatrix2iGraph()`](../reference/QMatrix2iGraph.md) converts the
Q-matrix into a bipartite directed graph: skill nodes → item nodes.

``` r
# --- Build graph ---
g <- QMatrix2iGraph(Q)

# Inspect
plot(g)
get_NodesTable(g)
get_EdgesTable(g)

# --- Estimate ---
config <- build_model_config(g, X)
results <- run_pgdcm_auto(
    config = config,
    prefix = "DCM",
    estimation_config = list(
        niter = 10000, nburnin = 1000, chains = 2,
        prior_sims = 25, post_sims = 25
    )
)
results$WAIC
```

------------------------------------------------------------------------

### Recipe 3 - Attribute Hierarchy DCM (AH-DCM)

**When to use:** You believe skills have prerequisite relationships
(e.g., a student must master Skill A before they can master Skill B).
This constrains the set of admissible mastery profiles and can improve
estimation when the hierarchy is theoretically justified.

The key difference from Recipe 2 is that you add
**attribute-to-attribute edges** to encode the prerequisite structure.
The easiest way to do this is in Cytoscape:

1.  Push the Q-matrix graph to Cytoscape with `QMatrix2CytoNodes(Q)`.
2.  Draw edges between skill nodes in the Cytoscape GUI to define the
    hierarchy.
3.  Pull the edited graph back with
    [`pull_from_cytoscape()`](../reference/pull_from_cytoscape.md).
4.  Save to GraphML so the structure is reproducible.

``` r
# --- Build graph (interactive Cytoscape workflow) ---
# get_Cyto_template()                        # copies the styling template
# library(RCy3)
# cytoscapePing("http://localhost:1234/v1")   # verify Cytoscape is running
# g <- QMatrix2CytoNodes(Q)                  # push to Cytoscape & edit
# g <- pull_from_cytoscape(base.url = "http://localhost:1234/v1")
# write_graph(g, "AH_DCM.graphml", format = "graphml")

# --- Or load a previously saved graph ---
g <- read_graph("AH_DCM.graphml", format = "graphml")

# Inspect
plot(g)
get_NodesTable(g)
get_EdgesTable(g)

# --- Estimate ---
config <- build_model_config(g, X)
results <- run_pgdcm_auto(
    config = config,
    prefix = "AH-DCM",
    estimation_config = list(
        niter = 10000, nburnin = 1000, chains = 2,
        prior_sims = 25, post_sims = 25
    )
)
results$WAIC
```

> **Tip: Saving your graph**
>
> Always save your edited graph with
> `write_graph(g, "AH_DCM.graphml", format = "graphml")`. This makes
> your analysis fully reproducible without needing Cytoscape open.

------------------------------------------------------------------------

### Recipe 4 - Higher-Order DCM (HO-DCM)

**When to use:** You believe a single general ability governs how likely
students are to master each discrete skill. The HO-DCM adds a continuous
latent “Theta” node as a parent of all skill nodes, combining the IRT
and DCM perspectives into a single hierarchical structure.

Like the AH-DCM, the graph for this model is typically constructed in
Cytoscape. The difference is the topology: instead of prerequisite edges
*between* skills, you add a continuous parent node *above* all skills.

``` r
# --- Build graph (interactive Cytoscape workflow) ---
# g <- QMatrix2CytoNodes(Q)                  # push to Cytoscape & edit
# g <- pull_from_cytoscape(base.url = "http://localhost:1234/v1")
# write_graph(g, "HO_DCM.graphml", format = "graphml")

# --- Or load a previously saved graph ---
g <- read_graph("HO_DCM.graphml", format = "graphml")

# Inspect
plot(g)
get_NodesTable(g)
get_EdgesTable(g)

# --- Estimate ---
config <- build_model_config(g, X)
results <- run_pgdcm_auto(
    config = config,
    prefix = "HO-DCM",
    estimation_config = list(
        niter = 10000, nburnin = 1000, chains = 2,
        prior_sims = 25, post_sims = 25
    )
)
results$WAIC
```

------------------------------------------------------------------------

## Comparing Results

The recipes above were run on the DTMR dataset (`dcmdata::dtmr_data`).
The tables below summarize the results so you can see how different
structural assumptions affect model fit, item parameter estimates, and
classification accuracy.

### Model Fit (WAIC)

**Access from your results:** `results$WAIC`

The Watanabe-Akaike Information Criterion (WAIC) measures out-of-sample
predictive accuracy. Lower is better. The effective number of parameters
(pWAIC) penalizes model complexity; LPPD is the log pointwise predictive
density.

| Model  |     WAIC |   pWAIC |      LPPD |
|:-------|---------:|--------:|----------:|
| IRT    | 30084.59 |  825.69 | -14216.61 |
| DCM    | 29482.05 | 1829.76 | -12911.26 |
| AH-DCM | 29245.54 | 1551.33 | -13071.44 |
| HO-DCM | 29207.24 | 1503.06 | -13100.56 |

On this dataset, the **HO-DCM** achieves the lowest WAIC, suggesting
that a general-ability-driven skill structure provides the best balance
of fit and complexity for this assessment.

### Item Difficulty (`lambda[, 2]`)

**Access from your results:** `results$item_parameters` - the
`difficulty_mean` column contains these values.

The second lambda index (`lambda[j, 2]`) captures the item difficulty.
Higher values mean an item is harder overall. Comparing these across
models reveals how structural assumptions shift the difficulty
calibration.

| Item    |    IRT |    DCM | AH-DCM | HO-DCM |
|:--------|-------:|-------:|-------:|-------:|
| Item_1  |  0.429 |  1.401 |  1.308 |  0.583 |
| Item_2  | -1.326 | -0.581 | -0.636 |  2.104 |
| Item_3  |  1.259 |  2.832 |  2.758 |  1.476 |
| Item_4  |  1.048 |  1.566 |  1.536 |  0.697 |
| Item_5  |  1.118 |  2.132 |  2.068 |  0.556 |
| Item_6  |  2.771 |  4.061 |  4.011 |  1.127 |
| Item_7  |  0.473 |  1.024 |  1.012 |  1.990 |
| Item_8  | -1.458 |  0.510 |  0.389 |  0.611 |
| Item_9  | -0.999 |  0.323 |  0.307 |  1.780 |
| Item_10 | -0.688 | -0.123 | -0.252 |  0.786 |
| Item_11 | -0.032 |  1.021 |  0.999 |  1.315 |
| Item_12 |  0.965 |  1.296 |  1.267 | -0.599 |
| Item_13 | -1.560 |  1.734 |  1.209 |  2.739 |
| Item_14 |  0.299 |  1.672 |  1.609 |  1.521 |
| Item_15 |  0.980 |  2.309 |  2.239 |  1.963 |
| Item_16 |  0.580 |  1.310 |  1.262 |  4.002 |
| Item_17 |  0.674 |  1.419 |  1.359 |  1.010 |
| Item_18 |  0.215 |  0.584 |  0.580 |  0.450 |
| Item_19 |  1.663 |  2.101 |  2.115 |  0.344 |
| Item_20 |  0.377 |  1.468 |  1.446 | -0.248 |
| Item_21 | -0.667 |  0.770 |  0.724 |  1.043 |
| Item_22 | -0.707 |  0.612 |  0.582 |  1.241 |
| Item_23 |  0.417 |  1.294 |  1.171 |  0.889 |
| Item_24 |  1.178 |  2.002 |  2.010 |  1.710 |
| Item_25 | -0.057 |  0.616 |  0.629 |  2.416 |
| Item_26 |  0.965 |  1.842 |  1.797 |  1.229 |
| Item_27 |  0.085 |  0.770 |  0.813 |  1.330 |

### Item Discrimination (`lambda[, 1]`)

**Access from your results:** `results$item_parameters` - the
`discrimination_mean` column contains these values.

The first lambda index (`lambda[j, 1]`) estimates the main-effect
discrimination (slope) - how well an item differentiates between
students who possess the relevant skills and those who do not. In
multidimensional models (DCM, AH-DCM, HO-DCM), this effect is split
across the skills specified in the Q-matrix, so cross-model comparisons
should be interpreted cautiously.

| Item    |   IRT |   DCM | AH-DCM | HO-DCM |
|:--------|------:|------:|-------:|-------:|
| Item_1  | 0.915 | 1.720 |  1.697 |  0.895 |
| Item_2  | 0.363 | 1.327 |  1.252 |  1.167 |
| Item_3  | 0.684 | 2.430 |  2.370 |  2.681 |
| Item_4  | 0.429 | 0.919 |  0.932 |  3.100 |
| Item_5  | 0.812 | 1.743 |  1.757 |  2.809 |
| Item_6  | 0.618 | 2.000 |  1.966 |  1.381 |
| Item_7  | 0.516 | 0.987 |  1.039 |  2.274 |
| Item_8  | 1.363 | 4.178 |  3.917 |  2.025 |
| Item_9  | 0.891 | 2.238 |  2.312 |  1.572 |
| Item_10 | 0.185 | 0.941 |  0.737 |  2.135 |
| Item_11 | 0.665 | 1.647 |  1.667 |  1.717 |
| Item_12 | 0.240 | 0.590 |  0.580 |  1.304 |
| Item_13 | 1.809 | 5.289 |  5.071 |  2.370 |
| Item_14 | 1.896 | 3.290 |  3.235 |  0.912 |
| Item_15 | 1.638 | 2.988 |  2.931 |  1.621 |
| Item_16 | 0.528 | 1.272 |  1.283 |  1.973 |
| Item_17 | 0.739 | 1.342 |  1.340 |  1.043 |
| Item_18 | 0.465 | 0.885 |  0.896 |  3.966 |
| Item_19 | 0.482 | 1.186 |  1.162 |  2.329 |
| Item_20 | 1.223 | 2.631 |  2.631 |  0.730 |
| Item_21 | 0.983 | 3.090 |  3.077 |  1.703 |
| Item_22 | 0.945 | 2.786 |  2.796 |  0.539 |
| Item_23 | 0.692 | 1.540 |  1.449 |  4.893 |
| Item_24 | 1.119 | 2.345 |  2.268 |  3.269 |
| Item_25 | 0.899 | 2.132 |  2.022 |  3.084 |
| Item_26 | 0.797 | 1.555 |  1.589 |  1.236 |
| Item_27 | 1.109 | 2.157 |  2.147 |  1.302 |

### Classification Accuracy

**Access from your results:** `results$skill_profiles` contains the
posterior mastery probabilities for each student.

When ground-truth mastery profiles are available (as in simulated or
validated datasets), you can evaluate how well each model recovers them
using
[`assess_classification_accuracy()`](../reference/assess_classification_accuracy.md).
The table below reports per-skill accuracy and overall profile-match
rate. The IRT model is excluded because it estimates a continuous trait
rather than discrete skill mastery.

| Metric                    |   DCM | AH-DCM | HO-DCM |
|:--------------------------|------:|-------:|-------:|
| referent_units            | 0.965 |  0.901 |  0.865 |
| partitioning_iterating    | 0.932 |  0.885 |  0.842 |
| appropriateness           | 0.891 |  0.841 |  0.791 |
| multiplicative_comparison | 0.912 |  0.865 |  0.821 |
| Overall Profile Match     | 0.854 |  0.792 |  0.730 |

> **Computing Classification Accuracy in Your Own Analysis**
>
> If you have ground-truth mastery profiles (e.g., from a simulation
> study or a validated assessment), you can compute accuracy directly
> with
> [`assess_classification_accuracy()`](../reference/assess_classification_accuracy.md):
>
> ``` r
> # Define which model attributes correspond to which columns in your true data
> skill_mapping <- list(
>     "referent_units"            = "referent_units",
>     "partitioning_iterating"    = "partitioning_iterating",
>     "appropriateness"           = "appropriateness",
>     "multiplicative_comparison" = "multiplicative_comparison"
> )
>
> accuracy <- assess_classification_accuracy(
>     skill_profiles = results$skill_profiles,   # posterior mastery probabilities
>     true_data      = true_profiles,            # data frame with true 0/1 states
>     mapping_list   = skill_mapping,            # links model attributes → true columns
>     threshold      = 0.5                       # probability cutoff for mastery
> )
>
> # Per-skill accuracy and Cohen's Kappa
> accuracy$metrics
>
> # Overall exact profile-match rate
> accuracy$profile_accuracy
> ```

------------------------------------------------------------------------

## Quick-Reference Summary

| Model  | Graph Constructor                                      | Skills                    | Relationships                |
|--------|--------------------------------------------------------|---------------------------|------------------------------|
| IRT    | [`build_irt_graph()`](../reference/build_irt_graph.md) | 1 continuous              | None                         |
| DCM    | `QMatrix2iGraph(Q)`                                    | K discrete                | Independent                  |
| AH-DCM | Edit in Cytoscape                                      | K discrete                | Prerequisites between skills |
| HO-DCM | Edit in Cytoscape                                      | K discrete + 1 continuous | General ability → skills     |

The only thing that changes across models is how you build the graph.
Everything else -
[`build_model_config()`](../reference/build_model_config.md),
[`run_pgdcm_auto()`](../reference/run_pgdcm_auto.md), and the results
structure - stays identical.

> **Ready to Deploy?**
>
> Once you have selected a model, the [Scoring
> Cookbook](Scoring_Cookbook.md) shows how to lock your calibrated
> parameters and score new examinees using
> [`build_scoring_config()`](../reference/build_scoring_config.md).
