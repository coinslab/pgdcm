# Unifying Psychometrics through Bayesian Networks: The `loglinearBN` Framework

## 1. Introduction: Two Worlds of Testing

If you are new to educational testing and psychometrics, you will quickly encounter two major camps of thought when it comes to evaluating students:

1. **Item Response Theory (IRT)**: This camp treats a student's ability as a **Continuous Trait**. Think of a spectrum like "General Intelligence" ($\theta$). A student could have a score anywhere from -3.0 (struggling) to +3.0 (gifted). The higher your score, the higher your smooth probability of answering a question correctly.
2. **Cognitive Diagnostic Models (CDMs)**: This camp treats abilities as **Discrete Skills**. Think of a checklist like "Knows Algebra" or "Knows Geometry" ($\alpha$). A student either possesses the skill ($\alpha = 1$) or does not ($\alpha = 0$).

Historically, software forced researchers to choose: build a continuous IRT model *or* build a discrete CDM model. But the real world is messy. What if a single advanced physics question requires general problem-solving intelligence (Continuous) AND a specific memorized formula (Discrete)?

The `pgdcm` package solves this by using **Bayesian Networks (BNs)**.

### What is a Bayesian Network?

A Bayesian Network is just a mathematical map of cause and effect. It is a web of "nodes" (variables) connected by arrows (dependencies).

* In our case, the nodes are **Student Traits** (like Intelligence or Algebra skill) and **Test Questions** (the actual data we observe).
* The beauty of a Bayesian Network is that it is flexible. A node doesn't care if the parent node pointing to it is continuous or discrete. It just takes all the inputs it receives and calculates a final probability.

This document breaks down exactly how the `pgdcm` package's grading engine—a custom function called `calc_mixed_kernel` inside the `loglinearBN.R` script—handles this mixing under the hood. By reading this guide, you will see how almost every major psychometric model from the last 50 years can be instantiated as a simple "special case" of this single Bayesian Network!

---

## 2. The Core Mechanism: The Logistic Equation

Before diving into the scenarios, we need to understand how the Bayesian Network calculates probability. For any given test question (or intermediate skill), the model calculates the probability that a student will succeed using a logistic equation:

$$
P(\text{Success}) \approx \text{logit}^{-1}(\text{Slope} \times \text{Effective Input} - \text{Intercept})
$$

Let's translate that into plain English:

* **The Logistic Curve ($\text{logit}^{-1}$)**: This is just an S-shaped curve that squishes any number into a valid probability between 0% and 100%.
* **Slope (Discrimination)**: How well does this question separate the masters from the novices? A steep slope means the question is highly sensitive to the student's ability.
* **Intercept (Difficulty)**: How fundamentally difficult is this question? A high intercept means you need a higher input score just to get a 50/50 chance of passing.
* **Effective Input ($\psi$)**: This is the magic number. This is what `calc_mixed_kernel` calculates for every single student on every single question. It looks at all the prerequisites the question requires, checks what the student possesses, and spits out a single summary score representing their "readiness."

### 2.1 The Three Moving Parts of the Effective Input

To calculate the Effective Input, the engine counts up three things for each student:

1. **Continuous Sum ($S_c$)**: It adds up the student's continuous traits (like general intelligence) if the question requires them. In the code, root nodes (variables with nothing pointing to them) are treated as continuous traits.
2. **Discrete Sum ($S_d$)**: It counts how many of the required discrete skills (like Algebra or Geometry) the student *actually possesses*.
3. **Required Mass ($R_d$)**: It counts how many discrete skills the question *formally demands*. (e.g., If the question requires Algebra and Geometry, $R_d = 2$).

Once the engine has these three numbers, it calculates the Effective Input depending on the structure of the question.

---

## 3. The Five Scenarios (How the BN Replicates Psychometrics)

Below, we detail how the math plays out in five distinct real-world scenarios. We will see how this single Bayesian Network elegantly becomes different classic psychometric models simply by changing what arrows point to what nodes.

### Scenario 1: Standard Multidimensional IRT (Continuous Only)

*Imagine a math-word problem that requires both "General Reading Ability" and "General Math Ability". It does not require any specific checklist skills.*

**How the BN Engine Reads It:**

* There are no discrete skills required, so the Required Mass ($R_d$) is exactly 0.
* Because nothing discrete is required, the student automatically clears the gate ($0 == 0$ is true).
* **The Result**: The Effective Input ($\psi$) is simply the sum of their continuous abilities: $S_c$ (Math + Reading).

**Why this is MIRT:**
This behaves exactly like a **Compensatory Multidimensional IRT (MIRT)** model. Because the Effective Input just adds the continuous traits together ($\theta_{\text{math}} + \theta_{\text{reading}}$), a student with a very high reading ability can mathematically "compensate" for a low math ability. Their combined sum will still be high enough to push them up the logistic curve.

### Scenario 2: Standard Unidimensional IRT (Single Continuous Trait)

*Imagine a basic vocabulary question that simply relies on "General Reading Ability" and nothing else.*

**How the BN Engine Reads It:**

* Exactly like Scenario 1, but there is only one arrow pointing to the question.
* **The Result**: The Effective Input ($\psi$) is just their single reading ability: $S_c$ (Reading).

**Why this is 2PL IRT:**
This behaves exactly like a classic **2-Parameter Logistic (2PL) IRT** model. The Effective Input is just the student's trait ($\theta$). The higher their trait, the higher their probability of getting the question right on a smooth curve, moderated by the question's unique Slope and Intercept.

### Scenario 3: Standard DINA (Discrete Skills Only)

*Imagine a strict math problem that requires knowing exactly two rules: "The Pythagorean Theorem" and "How to Multiply Fractions". General intelligence is not a factor.*

**How the BN Engine Reads It:**

* There are no continuous traits involved (no root nodes point to this question), so the Continuous Sum ($S_c$) is internally turned off.
* The Required Mass ($R_d$) is 2. The engine strictly checks if the student's Discrete Sum ($S_d$) equals 2.
* **The Result**: If the student possesses both skills ($S_d = 2$), the Effective Input is `1`. If they are missing one or both ($S_d < 2$), the Effective Input is `0`.

**Why this is a DINA Model:**
This is the classic **Deterministic Input, Noisy "And" (DINA)** Cognitive Diagnostic Model. The probability of success splits into exactly two harsh groups regarding the Effective Input:

1. **Masters** (Input = 1): They get a high probability of success (though not 100%, allowing for "slips").
2. **Non-Masters** (Input = 0): They get a very low probability of success (just a baseline "guessing" chance).
There is no smooth curve here; it is a step-function!

### Scenario 4: The Gated Implementation (Mixed Continuous and Discrete)

*This is the breakthrough scenario unique to this framework. Imagine an advanced physics question. It requires a high "General Problem Solving Ability" (Continuous $\theta$), BUT you absolutely must know "Newton's Third Law" (Discrete $\alpha$).*

If the model just added these together ($\theta + \alpha$), a pure genius student ($\theta = +3.0$) who doesn't know Newton's Law ($\alpha = 0$) might still score high enough to pass. But physics is strict; you *cannot* logic your way out of not knowing the core formula!

**How the BN Engine Reads It:**
To prevent unfair compensation, the engine treats the discrete skills as a **Strict Gate**:

1. It compares the student's possessed discrete skills ($S_d$) to the requirement ($R_d$).
2. **If they pass the Gate ($S_d == R_d$)**: The gate opens! The Effective Input becomes their continuous intelligence ($S_c$). They get to use their problem-solving ability to scale the logistic probability curve.
3. **If they fail the Gate ($S_d < R_d$)**: The engine intervenes. It completely overrides the continuous intelligence and assigns an extreme penalty: **Effective Input = -10.0**.

**Why this is Gated DINA:**
Under logistic math, an Effective Input of `-10.0` translates to a $\approx 0.000045$ probability of success. It drops straight to zero. Because of this "gate", extreme continuous intelligence cannot compensate for missing core knowledge. This successfully creates a **Mixed-Domain Non-Compensatory (Gated DINA)** model, solving the hybridization problem!

### Scenario 5: Compensatory and Disjunctive Topologies (DINM and DINO)

*What if the researcher doesn't want the strict "All-or-Nothing" rules of DINA for their discrete skills? The BN allows flipping a flag to use DINM or DINO logic instead.*

* **DINM (Deterministic Input, Noisy "Multiplicative")**: This is the "Partial Credit" model. The engine ignores the strict "gate" entirely and calculates a ratio: `(Possessed Inputs) / (Required Inputs)`. If a question requires 3 skills/traits and the student has 2, their Effective Input is $2/3$. High continuous ability *can* boost your ratio here, providing a fully compensatory mixed model.
* **DINO (Deterministic Input, Noisy "Or")**: This is the "Fast Track" model. The engine asks one question: "Does the student have *any* of the required skills or traits > 0?" If yes, their Effective Input is given a full `1.0`. Any single skill or a positive continuous trait is enough to succeed.

---

## 4. Conclusion

By viewing educational testing through the lens of a Bayesian Network, we no longer have to choose between Continuous IRT models and Discrete CDMs.

The `calc_mixed_kernel` function in the `pgdcm` package operates as a universal psychometric compiler. By intelligently grouping continuous sums ($S_c$) and discrete sums ($S_d$), and applying strict gating mechanisms when necessary, it allows researchers to build a single Bayesian Network that seamlessly switches between standard 2PL IRT curves, compensatory MIRT planes, strict DINA categorizations, and novel mixed-domain logic—all evaluated concurrently on a node-by-node basis!
