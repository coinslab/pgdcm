# Unifying Structural Equation Modeling through Bayesian Networks: The `loglinearSEM` Framework

## 1. Introduction: The Web of Relationships

While Cognitive Diagnostic Models (CDMs) and Item Response Theory (IRT) focus heavily on grading a student based on a hidden trait, **Structural Equation Modeling (SEM)** is all about mapping the *web of relationships*.

In a traditional testing model, we assume a hidden trait (like "Math Ability") directly causes a student to get a question right. But what if the world is messier?

* What if knowing "Algebra" directly helps you learn "Calculus"? (A hidden trait causing another hidden trait).
* What if answering Question 1 correctly gives you a hint that makes you more likely to answer Question 2 correctly? (An observed behavior causing another observed behavior).

The `pgdcm` package handles this massive, interconnected web using the `loglinearSEM.R` script. Just like the diagnostic models, this script instantiates standard SEM theories as a **Bayesian Network (BN)**.

This document breaks down how the `loglinearSEM` mathematical engine works under the hood, using plain English to explain how it gracefully calculates everything from standard regressions to complex network psychometrics.

---

## 2. The Core Mechanism: The Linear Predictor

In the `loglinearBN` (Diagnostic) model, we introduced the concept of a strict "Gate" (Non-Compensatory logic). The SEM model is much simpler in its philosophy: **Everything is Compensatory.** It runs on the engine of classic linear regression.

For every node in the network (whether it is a hidden student trait or an observed test score), the model calculates a **Linear Predictor** (an overall score):

$$
\text{Overall Score} = \text{Intercept} + (\text{Weight}_1 \times \text{Input}_1) + (\text{Weight}_2 \times \text{Input}_2) + \dots
$$

Let's translate the code variables into this equation:

* **Intercept ($\alpha$ / `alpha`)**: The baseline value. If a student has zero inputs, what is their natural baseline score or probability?
* **Weights ($\beta$ / `beta`)**: The strength of the connection. If you are great at Algebra, exactly *how much* does that boost your Calculus score? A high $\beta$ means a strong causal relationship.
* **Inputs**: The actual values of the parent nodes pointing to this node.

Because the math is strictly additive, a highly positive input can always compensate for a negative input.

---

## 3. The Three Types of Connections

What makes `loglinearSEM` powerful is that it calculates the overall score by looking at three distinct types of relationships simultaneously.

### Type 1: Latent to Latent (Attribute to Attribute)

*Example: "High Math Ability causes high Physics Ability."*

The model allows hidden traits to map to each other hierarchically. The script loops through the attributes and calculates a `linear_pred_att`. Because the Bayesian Network is topologically sorted, it calculates the "root" traits first (like General Intelligence), and then cascades those effects down to the dependent traits (like Physics).

### Type 2: Latent to Observed (Attribute to Task)

*Example: "High Physics Ability causes a high score on Question 1."*

This is the classic "Measurement Model" in psychometrics. The hidden traits point to the actual test questions. The model calculates the `input_from_atts` for every question by multiplying the student's hidden traits by the $\beta$ weights connecting them to the question.

### Type 3: Observed to Observed (Task to Task)

*Example: "Solving Question 1 correctly gives the student the formula needed to solve Question 2."*

This is where BNs shine. Traditional IRT assumes that test questions are completely independent of each other (Local Independence). BNs don't have this restriction! The script calculates `input_from_tasks`. It allows earlier test questions to literally act as weighted inputs for later test questions, capturing "Network Psychometrics" and test-taking momentum natively.

**The Grand Total:**
For any test question, the final score is the sum of all parts:
`Overall Score = Intercept + (Inputs from Hidden Traits) + (Inputs from Previous Questions)`

---

## 4. Flexible Distributions (The Toggle Flags)

So far, we have an "Overall Score" (Linear Predictor). But what do we do with it?

In SEM, variables can be continuous (a score from 0 to 100) or categorical (Pass/Fail). The `loglinearSEM` code provides absolute flexibility by letting the researcher toggle "Flags" that tell the engine how to distribute the final score.

It checks these flags for both Attributes (`SEMdo...Attribute`) and Tasks (`SEMdo...Task`):

### Toggle 1: The Z-Score Model (`SEMdoZscore`)

*Use Case: You want traits and scores to be continuous, like standard GPAs or survey scales.*

If this flag is active, the engine treats the node as a **Continuous Normal Distribution**. It takes the Overall Score and simply uses it as the *mean* ($\mu$) of a bell curve.
$$ \text{Node} \sim \text{Normal}(\mu = \text{Overall Score}, \sigma = 1) $$
This perfectly replicates classic Path Analysis and standard continuous Structural Equation Modeling.

### Toggle 2: The Binary Model (`SEMdoBinary`)

*Use Case: You want the outcome to be strictly Pass/Fail (1 or 0).*

If this flag is active, the engine squishes the Overall Score through a standard **Logistic Curve** (just like the Diagnostic BN model). It turns the linear score into a probability between 0% and 100%, and then flips a weighted coin to assign a `1` or `0`.
$$ P(\text{Node} = 1) = \text{logit}^{-1}(\text{Overall Score}) $$
This replicates standard Logistic Regression.

### Toggle 3: The Percentile / IRT Model (`SEMdoPercentile`)

*Use Case: You want a binary Pass/Fail outcome, but you want the math to align historically with Normal Ogive IRT parameters.*

If this flag is active, the engine does exactly the same thing as the Binary Model, but it actively multiplies the Overall Score by **1.702** before squishing it.
$$ P(\text{Node} = 1) = \text{logit}^{-1}(1.702 \times \text{Overall Score}) $$
Why 1.702? In psychometrics, multiplying a logistic score by $D \approx 1.702$ scales the curve so that it almost perfectly matches a Cumulative Normal curve. This is a famous mathematical trick that allows researchers to bridge Logistic modeling with older Normal modeling literature without losing accuracy.

---

## 5. Conclusion

By stripping away the confusing terminology of different statistical packages, the `loglinearSEM` script reveals that Structural Equation Modeling, Network Psychometrics, and Path Analysis can all be unified under one roof.

By calculating a simple compensatory Linear Predictor ($\alpha + \Sigma\beta x$) and providing toggle flags to route that predictor into a Continuous Bell Curve or a Binary Logistic Curve, this Bayesian Network elegantly replicates decades of distinct psychometric modeling techniques in fewer than 100 lines of code!
