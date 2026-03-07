# Unifying Structural Equation Modeling through Bayesian Networks: The `loglinearSEM` Framework

## 1. Introduction: The Web of Relationships

Structural Equation Modeling (SEM) is a powerful statistical technique used across the social sciences to map webs of complex relationships.

In traditional testing models (like standard Item Response Theory), we often assume a simple structure: a hidden trait (like "Math Ability") directly causes a student to get a specific math question right. But what if the world is messier?

* What if knowing "Algebra" directly helps you learn "Calculus"? (A hidden trait causing another hidden trait).
* What if answering Question 1 correctly gives you a hint that makes you more likely to answer Question 2 correctly? (An observed behavior causing another observed behavior).

Standard psychometric tools often struggle with these interconnected feedback loops. The `pgdcm` package handles this massive, interconnected web by instantiating SEM theories as a flexible  **Bayesian Network (BN)** using the `loglinearSEM.R` script.

This document breaks down how the `loglinearSEM` mathematical engine works under the hood, using plain English to explain how it gracefully calculates everything from standard regressions to complex network psychometrics.

---

## 2. The Core Mechanism: The Linear Predictor

The fundamental philosophy of the `loglinearSEM` engine is that **everything is compensatory**. It runs on the engine of classic linear regression.

For every node in the network (whether it is a hidden student trait or an observed test score), the model calculates an overall score, mathematically known as a **Linear Predictor**:

$$
\text{Overall Score} = \text{Intercept} + (\text{Weight}_1 \times \text{Input}_1) + (\text{Weight}_2 \times \text{Input}_2) + \dots
$$

Let's translate the code variables from `loglinearSEM` into this equation:

* **Intercept ($\alpha$ / `alpha`)**: The baseline value. If a student has zero inputs (or average inputs), what is their natural baseline score or probability?
* **Weights ($\beta$ / `beta`)**: The strength of the connection. If you are highly skilled at Algebra, exactly *how much* does that boost your Calculus score? A high $\beta$ means a strong causal relationship between the two variables.
* **Inputs**: The actual current values of the parent nodes pointing to this node.

Because the math is strictly additive, a highly positive input on one variable can historically "compensate" for a negative input on another variable to maintain a high overall score.

---

## 3. The Three Types of Connections

What makes `loglinearSEM` so much more powerful than a standard regression is that it calculates the overall score by dynamically handling three distinct types of relationships simultaneously within a single causal network.

### Type 1: Latent to Latent (Attribute to Attribute)

*Example: "High Math Ability causes high Physics Ability."*

The model allows hidden traits to map to each other hierarchically. The script loops through all latent attributes and calculates a `linear_pred_att`. Because the Bayesian Network is topologically sorted, it calculates the "root" traits first (like General Intelligence), and then naturally cascades those downstream effects to the dependent traits (like Physics) before evaluating them.

### Type 2: Latent to Observed (Attribute to Task)

*Example: "High Physics Ability causes a high score on Question 1."*

This is the classic "Measurement Model" in psychometrics. The hidden traits point to the actual observable test questions. The model calculates the `input_from_atts` for every specific question by multiplying the student's hidden traits by the $\beta$ weights connecting them to that specific question.

### Type 3: Observed to Observed (Task to Task)

*Example: "Solving Question 1 correctly gives the student the formula needed to solve Question 2."*

This is where BNs truly shine. Traditional psychometric modeling assumes that test questions are completely independent of each other once you factor in ability (this is called "Local Independence"). BNs do not have this restriction!

The script calculates `input_from_tasks`. It allows earlier test questions to literally act as weighted inputs for later test questions, capturing "Network Psychometrics" and test-taking momentum natively.

**The Grand Total:**
For any test question, the engine simply adds the cascading logic together:
`Overall Score = Intercept + (Inputs from Hidden Traits) + (Inputs from Previous Questions)`

---

## 4. Flexible Distributions (The Toggle Flags)

So far, we have calculated an "Overall Score" (Linear Predictor). But what do we do with it? Is an "Overall Score of 2.1" a GPA, or a 90% probability of passing?

In SEM, variables can be continuous (a score from 0 to 100) or categorical (Pass/Fail). The `loglinearSEM` code provides absolute flexibility by letting the researcher toggle "Flags" that tell the engine exactly how to distribute the final score into real-world statistics.

It checks these flags for both Attributes (`SEMdo...Attribute`) and Tasks (`SEMdo...Task`):

### Toggle 1: The Z-Score Model (`SEMdoZscore`)

*Use Case: You want traits and scores to be strictly continuous, like standard GPAs, reaction times, or survey scales.*

If this flag is active, the engine treats the node as a **Continuous Normal Distribution**. It takes the Overall Score and simply uses it as the *mean* ($\mu$) of a bell curve.
$$ \text{Node} \sim \text{Normal}(\mu = \text{Overall Score}, \sigma = 1) $$
This perfectly replicates classic Path Analysis and standard continuous Structural Equation Modeling without any transformation tricks.

### Toggle 2: The Binary Model (`SEMdoBinary`)

*Use Case: You want the observed outcome to be strictly Pass/Fail (1 or 0).*

If this flag is active, the engine squishes the Overall Score through a standard **Logistic Curve**. It turns the linear score spanning $-\infty$ to $+\infty$ into a strict probability between 0% and 100%, and then flips a weighted coin to assign a `1` or `0` based on that probability.
$$ P(\text{Node} = 1) = \text{logit}^{-1}(\text{Overall Score}) $$
This replicates standard Logistic Regression inside the network framework.

### Toggle 3: The Percentile / IRT Model (`SEMdoPercentile`)

*Use Case: You want a binary Pass/Fail outcome, but you want the math to align historically with Normal Ogive parameters commonly used in classic psychometrics.*

If this flag is active, the engine does exactly the same thing as the Binary Model, but it actively multiplies the Overall Score by a scaling factor of **1.702** before squishing it.
$$ P(\text{Node} = 1) = \text{logit}^{-1}(1.702 \times \text{Overall Score}) $$
Why 1.702? In psychometrics, multiplying a logistic score by $D \approx 1.702$ scales the logistic curve so that it almost perfectly matches a Cumulative Normal curve (the Normal Ogive). This is a famous mathematical trick that allows modern software to run fast Logistic equations while perfectly replicating older Normal-based psychometric literature without losing accuracy.

---

## 5. Conclusion

By stripping away the confusing terminology of different statistical packages, the `loglinearSEM` script reveals a unified truth: Structural Equation Modeling, Network Psychometrics, and Path Analysis can all be unified under one robust Bayesian architecture.

By calculating a simple compensatory Linear Predictor ($\alpha + \Sigma\beta x$) and providing toggle flags to route that predictor into a Continuous Bell Curve or a Binary Logistic Curve, this single engine elegantly replicates decades of distinct psychometric modeling techniques in fewer than 100 lines of code.
