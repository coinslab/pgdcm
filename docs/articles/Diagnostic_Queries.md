# Generating Diagnostic Inferences

## Introduction

Once you have fitted a Cognitive Diagnostic Model (DCM) using the
`pgdcm` package, the raw MCMC output contains log-odds slopes and
intercepts (`lambda` and `theta` parameters). While mathematically
precise, these values are difficult to interpret directly. A slope of
3.2 on Item 7 does not immediately communicate the item’s guessing or
slip probabilities.

The `pgdcm` diagnostic query functions solve this by transforming raw
posterior draws into interpretable probability metrics (such as
**Guessing rates**, **Slip rates**, **True Positive probabilities**,
**Prerequisite Gate Strengths**, and more), each with full 95% Credible
Intervals computed directly from the MCMC chains.

> **Prerequisites**
>
> This vignette assumes you have already fitted a model using
> [`run_pgdcm_auto()`](../reference/run_pgdcm_auto.md) and have a
> `results` object. If you are new to the package, start with the
> [Beginner
> Tutorial](https://coinslab.github.io/pgdcm/articles/Beginner_Tutorial.html)
> first.

> **Discrete Skills Only**
>
> The diagnostic queries in this vignette apply to models with
> **discrete binary skills** (DCM, HO-DCM). If your model uses
> continuous latent traits (IRT/MIRT), these functions will raise an
> error. Use standard IRT posterior summaries for those models instead.

## The Underlying Math (Brief Recap)

Every node in a `pgdcm` model follows the logistic equation:

$$P\left( v_{i} = 1 \right) = \text{logit}^{-1}\!(a_{v} \cdot \psi_{v}\left( \text{parents} \right) - b_{v})$$

where $a_{v}$ is the slope (discrimination), $b_{v}$ is the intercept
(difficulty), and $\psi_{v}$ is a condensation rule over parent nodes.
For items, these parameters are stored as `lambda[j, 1]` (slope) and
`lambda[j, 2]` (intercept). For skills, they are `theta[k, 1]` and
`theta[k, 2]`.

The diagnostic queries below evaluate this equation at specific boundary
conditions (e.g., “all prereqs met” or “no prereqs met”) across every
MCMC draw, yielding full posterior distributions over interpretable
probabilities. For more details, see the [Mathematical
Foundations](https://coinslab.github.io/pgdcm/articles/Understanding_DiBelloBN.html)
vignette.

------------------------------------------------------------------------

## 1. Item-Level Diagnostics

### 1.1 Full Item Diagnostic Table

The
[`generate_item_diagnostics()`](../reference/generate_item_diagnostics.md)
function computes four metrics for every item in a single call:

``` r
item_metrics <- generate_item_diagnostics(results)
head(item_metrics, 3)
```

      Item Guessing_Mean Guessing_CI_Lower Guessing_CI_Upper Slip_Mean
    1    1    0.21374150        0.17074170        0.25775620 0.4041659
    2    2    0.65340753        0.59558992        0.70715483 0.1322389
    3    3    0.06105285        0.03678597        0.08957652 0.5954751
      Slip_CI_Lower Slip_CI_Upper TrueMastery_Mean TrueMastery_CI_Lower
    1     0.3525392     0.4555385        0.5958341            0.5444615
    2     0.1018374     0.1644979        0.8677611            0.8355021
    3     0.5499134     0.6398999        0.4045249            0.3601001
      TrueMastery_CI_Upper Discrimination_Index_Mean Discrimination_CI_Lower
    1            0.6474608                 0.3820926               0.3096333
    2            0.8981626                 0.2143535               0.1463346
    3            0.4500866                 0.3434720               0.2904186
      Discrimination_CI_Upper
    1               0.4492726
    2               0.2842916
    3               0.3973626

Each row contains the posterior mean and 95% Credible Interval for:

| Metric             | What it measures                                                                                |
|--------------------|-------------------------------------------------------------------------------------------------|
| **Guessing**       | $P\left( \text{correct} \mid \text{non-master} \right)$ (false positive rate)                   |
| **True Mastery**   | $P\left( \text{correct} \mid \text{master} \right)$ (true positive rate)                        |
| **Slip**           | $P\left( \text{incorrect} \mid \text{master} \right)$ (false negative rate, $1 -$ True Mastery) |
| **Discrimination** | True Mastery $-$ Guessing (the probability gap between masters and non-masters)                 |

> **Interpretation Guide**
>
> An item with **high guessing** (\> 0.3) suggests weak distractors
> (non-masters can easily guess a correct answer). An item with **high
> slip** (\> 0.3) suggests confusing wording or an unmodeled secondary
> skill that causes true masters to fail. Both are flags for item
> revision.

### 1.2 Querying a Single Item

To investigate a specific item, use the individual query functions. Each
returns a named list with the posterior mean and 95% CI:

``` r
# False positive: can non-masters guess this item correctly?
calc_item_guessing_prob(results, "1")
```

    $metric
    [1] "Item Guessing Probability"

    $item_target
    [1] "1"

    $mean_guessing_prob
    [1] 0.2137415

    $ci_95
         2.5%     97.5%
    0.1707417 0.2577562 

``` r
# True positive: can masters reliably answer correctly?
calc_item_true_positive_prob(results, "1")
```

    $metric
    [1] "Item True Mastery Probability"

    $item_target
    [1] "1"

    $mean_mastering_prob
    [1] 0.5958341

    $ci_95
         2.5%     97.5%
    0.5444615 0.6474608 

``` r
# False negative: how often do masters slip up?
calc_item_slip_prob(results, "1")
```

    $metric
    [1] "Item Slip (False Negative) Probability"

    $item_target
    [1] "1"

    $mean_slip_prob
    [1] 0.4041659

    $ci_95
         2.5%     97.5%
    0.3525392 0.4555385 

``` r
# Discrimination: how large is the master vs. non-master gap?
calc_item_discrimination_index(results, "1")
```

    $metric
    [1] "Item Discrimination Index (Probability Gap)"

    $item_target
    [1] "1"

    $mean_gap
    [1] 0.3820926

    $ci_95
         2.5%     97.5%
    0.3096333 0.4492726

    $mean_master_prob
    [1] 0.5958341

    $mean_guessing_prob
    [1] 0.2137415

------------------------------------------------------------------------

## 2. Skill-Level Structural Diagnostics

### 2.1 Full Skill Diagnostic Table

The
[`generate_skill_diagnostics()`](../reference/generate_skill_diagnostics.md)
function inspects your graph topology and computes the appropriate
metrics for each skill:

``` r
skill_metrics <- generate_skill_diagnostics(results)
skill_metrics[, c(
    "Skill", "Type", "BaseRate_Mean",
    "Prob_Given_All_Prereqs_Mean",
    "Prob_Given_No_Prereqs_Mean",
    "GateStrength_Mean"
)]
```

                          Skill      Type BaseRate_Mean Prob_Given_All_Prereqs_Mean
    1           appropriateness      Root     0.3914595                          NA
    2    partitioning_iterating Dependent            NA                   0.6715327
    3 multiplicative_comparison Dependent            NA                   0.8901759
    4            referent_units Dependent            NA                   0.7934351
      Prob_Given_No_Prereqs_Mean GateStrength_Mean
    1                         NA                NA
    2                  0.3019795         0.3695532
    3                  0.3299339         0.5602420
    4                  0.3171507         0.4762843

The function automatically classifies each skill:

- **Root** skills have no prerequisites. For these, only the population
  `BaseRate` (the proportion of students who have mastered this skill)
  is reported.
- **Dependent** skills have prerequisite arrows. For these, three
  structural metrics are computed:

| Metric                     | What it measures                                                                                            |
|----------------------------|-------------------------------------------------------------------------------------------------------------|
| **Prob Given All Prereqs** | $P\left( \text{master target skill} \mid \text{all prereqs met} \right)$ (success rate when fully prepared) |
| **Prob Given No Prereqs**  | $P\left( \text{master target skill} \mid \text{no prereqs met} \right)$ (the “leap” probability)            |
| **Gate Strength**          | Prob Given All Prereqs $-$ Prob Given No Prereqs (the causal impact of the prerequisite)                    |

### 2.2 Interpreting Structural Patterns

The three structural metrics tell a pointed story about each
prerequisite arrow:

**Strong gate** (Gate Strength \> 0.6): The prerequisite genuinely
matters. Students who lack the prerequisite have almost no chance of
acquiring the target skill, but those who master it progress naturally.

**Weak gate** (Gate Strength \< 0.2): The prerequisite arrow may be
theoretically unjustified. Students can “leap” to the target skill
without the prerequisite, suggesting the skills are more independent
than your graph assumes.

**Bottleneck** (Prob Given All Prereqs \< 0.5): Even perfectly prepared
students struggle to acquire this skill. This signals a missing
prerequisite, a poorly scaffolded instructional transition, or a skill
that depends on knowledge outside the model.

### 2.3 Querying a Single Skill

To evaluate a specific prerequisite relationship:

``` r
# Bottleneck: if students have all prereqs, what's their mastery probability?
calc_prob_master_given_prereqs(results, "partitioning_iterating")
```

    $metric
    [1] "Bottleneck Probability (Prereqs Met)"

    $skill_target
    [1] "partitioning_iterating"

    $mean_prob
    [1] 0.6715327

    $ci_95
         2.5%     97.5%
    0.6180963 0.7260112 

``` r
# Leap: can students master this skill without any prereqs?
calc_prob_master_given_no_prereqs(results, "partitioning_iterating")
```

    $metric
    [1] "Leap Probability (No Prereqs Met)"

    $skill_target
    [1] "partitioning_iterating"

    $mean_prob
    [1] 0.3019795

    $ci_95
         2.5%     97.5%
    0.2317165 0.3763714 

``` r
# Gate Strength: how much do the prerequisites actually help?
calc_risk_difference(results, "partitioning_iterating")
```

    $metric
    [1] "Prerequisite Gate Strength (Risk Difference)"

    $skill_target
    [1] "partitioning_iterating"

    $mean_gate_strength
    [1] 0.3695532

    $ci_95
         2.5%     97.5%
    0.2744367 0.4558058

    $mean_bottleneck_prob
    [1] 0.6715327

    $mean_leap_prob
    [1] 0.3019795

> **Root Nodes**
>
> Root skills have no `theta` parameters; they are governed by
> `beta_root` intercepts instead. Calling
> [`calc_prob_master_given_prereqs()`](../reference/calc_prob_master_given_prereqs.md)
> on a root skill will raise an error. Use
> [`generate_skill_diagnostics()`](../reference/generate_skill_diagnostics.md)
> to correctly identify root vs. dependent skills before running
> individual queries.

------------------------------------------------------------------------

## 3. Putting It All Together

A typical post-estimation diagnostic workflow combines both tables to
flag issues and then drills into the details:

``` r
# 1. Generate both diagnostic tables
item_dx  <- generate_item_diagnostics(results)
skill_dx <- generate_skill_diagnostics(results)

# 2. Flag problematic items (high guessing OR high slip)
bad_items <- item_dx[item_dx$Guessing_Mean > 0.3 | item_dx$Slip_Mean > 0.3, ]
bad_items[, c("Item", "Guessing_Mean", "Slip_Mean", "Discrimination_Index_Mean")]

# 3. Flag weak prerequisite links
weak_links <- skill_dx[!is.na(skill_dx$GateStrength_Mean) &
                        skill_dx$GateStrength_Mean < 0.2, ]
weak_links[, c("Skill", "GateStrength_Mean")]

# 4. Drill into a specific flagged item
calc_item_discrimination_index(results, bad_items$Item[1])
```

------------------------------------------------------------------------

## Function Reference

| Function                                            | Level        | Returns                                                               |
|-----------------------------------------------------|--------------|-----------------------------------------------------------------------|
| `generate_item_diagnostics(results)`                | All items    | Data frame with guessing, slip, mastery, and discrimination metrics   |
| `generate_skill_diagnostics(results)`               | All skills   | Data frame with base rates, bottleneck/leap probs, and gate strengths |
| `calc_item_guessing_prob(results, item)`            | Single item  | Guessing probability (false positive rate)                            |
| `calc_item_true_positive_prob(results, item)`       | Single item  | True mastery probability                                              |
| `calc_item_slip_prob(results, item)`                | Single item  | Slip probability (false negative rate)                                |
| `calc_item_discrimination_index(results, item)`     | Single item  | Master vs. non-master probability gap                                 |
| `calc_prob_master_given_prereqs(results, skill)`    | Single skill | Bottleneck probability (prereqs met)                                  |
| `calc_prob_master_given_no_prereqs(results, skill)` | Single skill | Leap probability (no prereqs met)                                     |
| `calc_risk_difference(results, skill)`              | Single skill | Gate strength (bottleneck - leap)                                     |
