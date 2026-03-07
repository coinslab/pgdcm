# Understanding the Mixed-Domain Logic in `loglinearBN`

## 1. Introduction

In educational testing and psychometrics, we often use models to figure out two things:

1. **Continuous Traits**: A student's general ability level on a spectrum (e.g., General Intelligence $\theta$, ranging from -3 to +3). This is handled by **Item Response Theory (IRT)**.
2. **Discrete Skills**: Whether a student possesses a specific skill or not (e.g., "Knows Algebra" $\alpha = 1$ or $\alpha = 0$). This is handled by **Cognitive Diagnostic Models (CDMs)**.

Historically, software forced researchers to choose: build a continuous model *or* build a discrete model. The `pgdcm` package solves this by allowing **Bayesian Networks (BNs)** that mix both. A single test question might require general intelligence AND a specific discrete skill simultaneously.

This document breaks down exactly how the mathematical grading engine—a function called `calc_mixed_kernel` inside `loglinearBN.R`—handles this mixing under the hood.

---

## 2. How the "Grading Engine" Works

The core of the model is a logistic equation. For any given test question (or intermediate skill), the model calculates the probability that student $i$ will succeed:

$$
P(\text{Success}) \approx \text{logit}^{-1}(\text{Slope} \times \text{Effective Input} - \text{Intercept})
$$

* **Slope ($\lambda_1$)**: How well does this question distinguish between good and bad students?
* **Intercept ($\lambda_2$)**: How fundamentally difficult is the question?
* **Effective Input ($\psi$)**: This is what `calc_mixed_kernel` calculates. It looks at all the prerequisites the question requires, looks at what the student possesses, and spits out a single score summarizing their readiness.

### 2.1 The Three Moving Parts

To calculate the Effective Input, the engine counts up three things for the student:

1. **Continuous Sum ($S_c$)**: It adds up the student's continuous traits (like general intelligence) if the question requires them.
2. **Discrete Sum ($S_d$)**: It counts how many of the required specific skills (like algebra or geometry) the student actually possesses.
3. **Required Mass ($R_d$)**: It counts how many specific skills the question *formally demands*. (e.g., If it requires algebra and geometry, $R_d = 2$).

Once it has these three numbers, the engine uses them to calculate the final Effective Input depending on the structure of the question.

---

## 3. The Five Scenarios

Below, we detail how the math plays out in five distinct real-world scenarios.

### Scenario 1: Standard Multidimensional IRT (Continuous Only)

*Imagine a math-word problem that requires both "General Reading Ability" and "General Math Ability". It does not require any specific checklist skills.*

**How the Engine Reads It:**

* There are no discrete skills required, so the Required Mass ($R_d$) is 0.
* Because nothing specific is required, the student automatically clears the "gate" ($0 == 0$ is true).
* **The Result**: The Effective Input is simply the sum of their continuous abilities: $S_c$ (Math + Reading).

**What This Means:**
This behaves exactly like a **Compensatory MIRT** model. Because it just adds the traits together, a student with a very high reading ability can mathematically compensate for a low math ability and still get the question right.

### Scenario 2: Standard Unidimensional IRT (Single Continuous Trait)

*Imagine a basic vocabulary question that simply relies on "General Reading Ability."*

**How the Engine Reads It:**

* Exactly like Scenario 1, but there is only one trait.
* **The Result**: The Effective Input is just their reading ability: $\theta$.

**What This Means:**
This behaves exactly like a classic **2-Parameter Logistic (2PL) IRT** model. The higher their trait, the higher their probability of getting the question right on a smooth curve.

### Scenario 3: Standard DINA (Discrete Skills Only)

*Imagine a strict math problem that requires knowing exactly two rules: "The Pythagorean Theorem" and "How to Multiply Fractions". General intelligence is not factored in.*

**How the Engine Reads It:**

* There are no continuous traits involved, so the Continuous Sum ($S_c$) is turned off.
* The Required Mass ($R_d$) is 2. The engine checks if the student's Discrete Sum ($S_d$) equals 2.
* **The Result**: If they have both skills, the Effective Input is `1`. If they are missing one or both, the Effective Input is `0`.

**What This Means:**
This is the classic **Cognitive Diagnostic Model (DINA)**. Probability splits into two harsh groups: "Masters" (input=1) who have a high probability of success, and "Non-Masters" (input=0) who have a very low probability (just a guessing chance).

### Scenario 4: The Gated Implementation (Mixed Continuous and Discrete Inputs)

*This is the breakthrough scenario. Imagine an advanced physics question. It requires a high "General Problem Solving Ability" (Continuous $\theta$), BUT you absolutely must know "Newton's Third Law" (Discrete $\alpha$).*

If we just added these together ($\theta + \alpha$), a genius student ($\theta = +3.0$) who doesn't know Newton's Law ($\alpha = 0$) might still get a high score. But this is a strict test; you *cannot* logic your way out of not knowing the formula!

**How the Engine Reads It:**
To prevent unfair compensation, the engine treats the discrete skills as a **Strict Gate**:

1. It compares the student's skills ($S_d$) to the requirements ($R_d$).
2. **If they pass the Gate ($S_d == R_d$)**: The gate opens! The Effective Input becomes their continuous intelligence ($S_c$). They get to use their problem-solving ability on the question.
3. **If they fail the Gate ($S_d \neq R_d$)**: The engine intervenes and assigns an extreme penalty: **Effective Input = -10.0**.

**What This Means:**
Under logistic math, an input of `-10.0` translates to a $\approx 0.000045$ probability of success. It drops straight to zero. Because of this "gate", extreme continuous intelligence cannot compensate for missing core knowledge. This successfully creates a **Mixed-Domain Non-Compensatory (Gated DINA)** model.

### Scenario 5: Compensatory and Disjunctive Topologies (DINM and DINO)

*What if the researcher doesn't want the strict "All-or-Nothing" rules? They can flip a flag to use DINM or DINO logic instead.*

* **DINM (Partial Credit/Compensatory)**: The engine ignores the "gate" and just calculates a ratio: (What you have) / (What is required). If you need 3 skills/traits and possess 2, your Effective Input is $2/3$. High continuous ability *can* boost your ratio here.
* **DINO (Fast Track/Disjunctive)**: The engine says, "Do you have *any* of the required skills or traits > 0?" If yes, your Effective Input is a full `1.0`.

---

## 4. Conclusion

The `calc_mixed_kernel` function operates as a universal psychometric compiler. By intelligently grouping and gating continuous sums ($S_c$) and discrete sums ($S_d$), it allows researchers to build single Bayesian Networks that seamlessly switch between standard IRT curves, strict DINA groupings, and the novel Gated Mixed-Domain logic—all on a node-by-node basis.
