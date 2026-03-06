# Formulating Mixed-Domain Cognitive Diagnostics: The `loglinearBN` Framework

## 1. Introduction

Bayesian Networks (BNs) present a robust architecture for modeling complex dependencies in Psychometric frameworks such as Cognitive Diagnostic Models (CDMs) and Item Response Theory (IRT). Traditional implementations of CDMs typically require latent attributes to be strictly discrete (representing the presence or absence of a skill), whereas IRT traditionally relies strictly on continuous latent generic traits (like general intelligence).

The `pgdcm` package addresses a modern challenge: formulating diagnostic equations when items or intermediate attributes demand *both* continuous roots and categorical dependencies simultaneously. This document details how this hybridization is mathematically orchestrated within the package's primary BN compilation engine, specifically focusing on the computational logic within the `calc_mixed_kernel` Nimble function found in `loglinearBN.R`.

## 2. Core Model Architecture: `loglinearBN`

The `loglinearBN` script is built recursively in Nimble to map observational data ($X_{ij}$) to hierarchical latent states via Bayesian inference. The graph topography allows any node (Attribute $k$ or Task $j$) to have multiple distinct prerequisites (parents).

Dependencies in the BN are encoded via three potential structural condensation rules per node:

1. **DINA (Deterministic Input, Noisy "And")**: Non-compensatory; requires *all* requisite inputs.
2. **DINM (Deterministic Input, Noisy "Multiplicative")**: Compensatory; constructs a partial credit ratio based on inputs.
3. **DINO (Deterministic Input, Noisy "Or")**: Disjunctive; requires *any* individual requisite input.

To handle parent nodes that span both continuous domains ($\theta \in \mathbb{R}$) and discrete binary domains ($\alpha \in \{0,1\}$), we developed the `calc_mixed_kernel` compiler flag.

## 3. Mathematical Formalization of `calc_mixed_kernel`

The fundamental purpose of `calc_mixed_kernel` is to reduce an arbitrary array of $P$ parent states into a single, scalar "Effective Input" ($\psi_{ik}$) that is subsequently passed to the standard generalized logistic regression form to compute the probability of a positive outcome:

$$
P(X_{ij} = 1 \mid \psi, \lambda) \approx \text{logit}^{-1}(\lambda_{j,1} \cdot \psi_{ij} - \lambda_{j,2})
$$
Where $\lambda_{j,1}$ represents the slope (discrimination) and $\lambda_{j,2}$ represents the intercept (difficulty).

The function sequentially aggregates parent statuses during compilation as follows:

1. **Continuous Summation ($S_c$)**: Accumulates the weighted values of root continuous inputs (where the parent index $p \leq \text{nrbetaroot}$).
2. **Discrete Summation ($S_d$)**: Accumulates the weighted values of categorical specific attributes (where $p > \text{nrbetaroot}$).
3. **Required Discrete Mass ($R_d$)**: Totals the strictly necessary combinatorial weight of non-continuous prerequisites.

The core ingenuity of the function lies in how it handles varying combinatorial constraints under the DINA flag parameterization. We outline the five exclusive behavioral scenarios handled natively by the algorithm.

### Scenario 1: Standard Multidimensional IRT (Multiple Continuous Roots)

When an item loads purely onto continuous traits (e.g., General Math Ability $\theta_1$ and General Reading Ability $\theta_2$), the model reduces to standard MIRT mapping.

**Mathematical Behavior:**

- The required discrete mass $R_d = 0$.
- The discrete sum $S_d = 0$.
- The logic strictly evaluates the condition $S_d == R_d$, inherently resolving to True.
- The outcome assigns $\psi_{ij} = S_c$.
The loglinear kernel becomes a multi-parameter combination $P(X_{ij}=1) = \text{logit}^{-1}(\lambda_{j,1}(\theta_{1} + \theta_{2}) - \lambda_{j,2})$. The model naturally behaves cleanly as Compensatory MIRT.

### Scenario 2: Standard Unidimensional IRT (Single Continuous Root)

When an item loads solely onto one continuous ability ($\theta_1$).

**Mathematical Behavior:**

- The required discrete mass $R_d = 0$.
- The condition $S_d == R_d$ remains True.
- The outcome assigns $\psi_{ij} = \theta_1$.
The kernel collapses accurately to the standard 2PL IRT equation: $P(X_{ij}=1) = \text{logit}^{-1}(\lambda_{j,1} \theta_1 - \lambda_{j,2})$.

### Scenario 3: Standard DINA (Multiple Discrete Attributes)

A traditional cognitive item that necessitates the mastery of several distinct binary skills (e.g., $\alpha_1, \alpha_2$), completely agnostic to general continuous traits.

**Mathematical Behavior:**

- Continuous summation $S_c = 0$ and the `has_cont` flag disables.
- The logic strictly bypasses the continuous evaluation branch and verifies only if the student has every requisite categorical skill ($S_d == R_d$).
- The function emits a strict discrete binary boolean: $\psi_{ij} \in \{0, 1\}$.
The logistic probability is strictly grouped into two distinct strata based on full competency pattern mastery.

### Scenario 4: The Gated Implementation (Mixed Continuous and Discrete Inputs)

The most intricate structural constraint arises when an outcome demands both specific mastery ($\alpha_1$) alongside a sufficient baseline continuum trait ($\theta_1$). Standard compensatory mixtures natively permit a high continuous trait to mathematically supersede a missing critical discrete requirement, violating non-compensatory theory.

The `loglinearBN` circumvents this by instituting a strict **Gating Matrix** approach:
$$
\psi_{ij} =
\begin{cases}
S_c & \text{if } S_d == R_d \\
-10.0 & \text{otherwise}
\end{cases}
$$

**Mathematical Behavior:**

- The function determines that continuous inputs denote the true predictive variable (`has_cont == 1.0`).
- The explicit checking condition requires mastering every single categorical skill.
- **If prerequisites are met**, the discrete gate is opened, and the probability evaluates identically to a 2PL curve scaling along the continuum variable $\theta_1$.
- **If prerequisites are violated**, the item emits an extreme, arbitrary scalar penalty ($\psi_{ij} = -10$), which, under a logistic curve, collapses the unnormalized probability $P(X_{ij}=1) \rightarrow 0.000045$, strictly terminating the capacity for $\theta$ to compensate.

### Scenario 5: Compensatory and Disjunctive Topologies (DINM and DINO)

When researchers invoke strictly compensatory architectures substituting the DINA rule constraint, the algorithm behaves algebraically.

- **DINM**: Computes uniformly utilizing the mass inputs regardless of continuity properties: $\psi_{ij} = (S_c + S_d) / \max(1, S_{input})$.
- **DINO**: Computes a straightforward logical bypass mapping: $\psi_{ij} = 1.0 \text{ if } (S_c + S_d > 0) \text{ else } 0$.

## 4. Conclusion

The topological engine powering `loglinearBN` successfully abstracts the traditionally disjoint continuous (IRT) and categorical (CDM) parameter spaces. By utilizing the `calc_mixed_kernel` subroutine, the Bayesian structural compiler handles unidimensional IRT, multidimensional compensatory arrays, strict categorical grouping rules, and complex gated hierarchies under a single, unified syntax standard.
