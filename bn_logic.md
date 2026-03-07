# Formulating Mixed-Domain Cognitive Diagnostics: The `loglinearBN` Framework

## 1. Introduction

Bayesian Networks (BNs) present a robust architecture for modeling complex dependencies in Psychometric frameworks such as Cognitive Diagnostic Models (CDMs) and Item Response Theory (IRT). Traditional implementations of CDMs typically require latent attributes to be strictly discrete (representing the presence or absence of a skill), whereas IRT traditionally relies strictly on continuous latent generic traits (like general intelligence).

The `pgdcm` package addresses a modern methodological challenge: formulating diagnostic equations when items or intermediate attributes demand *both* continuous roots and categorical dependencies simultaneously within a single causal hierarchy. Traditional psychometric software often separates these paradigms—forcing researchers to choose between treating all variables as continuous (e.g., Structural Equation Modeling) or all variables as categorical (e.g., Latent Class Models).

This document details how this hybridization is mathematically orchestrated within the package's primary BN compilation engine, specifically focusing on the computational logic within the `calc_mixed_kernel` Nimble function found in `loglinearBN.R`.

## 2. Core Model Architecture: `loglinearBN`

The `loglinearBN` script is built recursively in Nimble to map observational data ($X_{ij}$) to hierarchical latent states via Bayesian inference. The graph topography allows any node—whether it is a higher-order latent Attribute $k$ or an observable Task $j$—to have multiple distinct prerequisites (parents).

Dependencies in the BN are encoded via three potential structural condensation rules per node, drawing from standard cognitive diagnostic theory:

1. **DINA (Deterministic Input, Noisy "And")**: Non-compensatory logic. A subject must possess *all* requisite inputs to have a high probability of success.
2. **DINM (Deterministic Input, Noisy "Multiplicative")**: Compensatory logic. A subject's probability of success is proportional to the ratio of possessed inputs over total required inputs.
3. **DINO (Deterministic Input, Noisy "Or")**: Disjunctive logic. A subject must possess *any* individual requisite input to have a high probability of success.

To handle parent nodes that span both continuous domains ($\theta \in \mathbb{R}$) and discrete binary domains ($\alpha \in \{0,1\}$), we developed the `calc_mixed_kernel` compiler flag.

## 3. Mathematical Formalization of `calc_mixed_kernel`

The fundamental purpose of `calc_mixed_kernel` is to reduce an arbitrary array of $P$ parent states into a single, scalar "Effective Input" ($\psi_{ij}$) that is subsequently passed to the standard generalized logistic regression form to compute the probability of a positive outcome:

$$
P(X_{ij} = 1 \mid \psi, \lambda) \approx \text{logit}^{-1}(\lambda_{j,1} \cdot \psi_{ij} - \lambda_{j,2})
$$

Where:

* $\lambda_{j,1} \in (0, \infty)$ represents the discrimination (slope) parameter.
* $\lambda_{j,2} \in (-\infty, \infty)$ represents the difficulty (intercept) parameter.
* $\psi_{ij}$ is the condensed effective input for subject $i$ on node $j$, calculated dynamically by the BN.

### 3.1 Kernel Aggregation Mechanics

The `calc_mixed_kernel` function sequentially aggregates parent statuses during compilation. Given a vector of parent node values $v = (v_1, \dots, v_P)$ and corresponding Q-matrix/Adjacency weights $w = (w_1, \dots, w_P)$, the function computes:

1. **Continuous Summation ($S_c$)**: Accumulates the weighted values of root continuous inputs. The model architecture enforces that only root nodes (nodes with 0 in-degree, indexed $p \leq \text{nrbetaroot}$) can be modeled continuously as $N(0,1)$.
    $$ S_c = \sum_{p=1}^{\text{nrbetaroot}} w_p v_p $$
2. **Discrete Summation ($S_d$)**: Accumulates the weighted values of categorical specific attributes (where $p > \text{nrbetaroot}$). These are strictly modeled as Bernoullis.
    $$ S_d = \sum_{p=\text{nrbetaroot}+1}^{P} w_p v_p $$
3. **Required Discrete Mass ($R_d$)**: Totals the strictly necessary combinatorial weight of non-continuous prerequisites.
    $$ R_d = \sum_{p=\text{nrbetaroot}+1}^{P} w_p $$

The core ingenuity of the function lies in how it handles varying combinatorial constraints under the DINA (Non-Compensatory) flag parameterization when bridging $S_c$ and $S_d$. We outline the five exclusive behavioral scenarios handled natively by the algorithm.

---

## 4. Operational Scenarios

### Scenario 1: Standard Multidimensional IRT (Multiple Continuous Roots, No Discrete Parents)

When an item loads purely onto multiple continuous traits (e.g., General Math Ability $\theta_1$ and General Reading Ability $\theta_2$), the model automatically reduces to a standard Multidimensional Item Response Theory (MIRT) mapping.

**Mathematical Behavior:**
* The required discrete mass $R_d = 0$.
* The discrete sum $S_d = 0$.
* The gating logic strictly evaluates the condition $S_d == R_d$, which evaluates to `$0 == 0$` (True).
* The outcome assigns the effective input to the continuous sum: $\psi_{ij} = S_c = \lambda_1 \theta_1 + \lambda_2 \theta_2$.

**Psychometric Implication:**
The loglinear kernel becomes a multi-parameter additive combination:
$$P(X_{ij}=1) = \text{logit}^{-1}(\lambda_{j,1}(\theta_{1} + \theta_{2}) - \lambda_{j,2})$$
Because $S_c$ relies on simple addition, a high draw from $\theta_1$ can mathematically compensate for a low draw from $\theta_2$. The model naturally and correctly behaves as Compensatory MIRT.

### Scenario 2: Standard Unidimensional IRT (Single Continuous Root, No Discrete Parents)

This is a specific reduction of Scenario 1, where an item loads solely onto one continuous ability ($\theta_1$).

**Mathematical Behavior:**
* Again, $R_d = 0$ and $S_d == R_d \rightarrow \text{True}$.
* The outcome assigns $\psi_{ij} = \theta_1$.

**Psychometric Implication:**
The kernel collapses accurately to the standard 2-Parameter Logistic (2PL) IRT equation:
$$P(X_{ij}=1) = \text{logit}^{-1}(\lambda_{j,1} \theta_1 - \lambda_{j,2})$$

### Scenario 3: Standard DINA (Multiple Discrete Attributes, No Continuous Roots)

Consider a traditional cognitive item that necessitates the mastery of several distinct binary skills (e.g., $\alpha_1, \alpha_2$), completely agnostic to general continuous traits. This represents the classic Cognitive Diagnostic Model formulation.

**Mathematical Behavior:**
* Continuous summation $S_c = 0$ and the internal `has_cont` flag disables.
* The algorithm bypasses the continuous evaluation branch entirely.
* It verifies if the student has every requisite categorical skill ($S_d == R_d$).
* The function emits a strict discrete boolean: $\psi_{ij} = 1$ if $S_d == R_d$, else $0$.

**Psychometric Implication:**
The input to the logistic equation is strictly binary. Students drop into two distinct probability strata (often referred to as the guessing and slipping parameters in classical DINA formulations):
* Masters (possessed all skills): $P(X_{ij}=1) = \text{logit}^{-1}(\lambda_{j,1}(1) - \lambda_{j,2})$
* Non-Masters (missing $\ge 1$ skill): $P(X_{ij}=1) = \text{logit}^{-1}(\lambda_{j,1}(0) - \lambda_{j,2})$

### Scenario 4: The Gated Implementation (Mixed Continuous and Discrete Inputs)

The most intricate structural constraint arises when an outcome demands *both* specific mastery ($\alpha_1$) alongside a sufficient baseline continuum trait ($\theta_1$).

If one were to use standard compensatory summation ($\theta_1 + \alpha_1$), a very high continuous trait ($\theta_1 = 3.0$) could mathematically superscript a missing critical discrete requirement ($\alpha_1 = 0$), violating non-compensatory theory. For example, extreme general intelligence should not compensate for zero knowledge of the actual required vocabulary word.

The `loglinearBN` algorithm resolves this by establishing the discrete traits as a strict **Gating Matrix** for the continuous trait:

$$
\psi_{ij} =
\begin{cases}
S_c & \text{if } S_d == R_d \quad \text{(Gate Open)} \\
-10.0 & \text{otherwise} \quad \text{(Gate Closed)}
\end{cases}
$$

**Mathematical Behavior:**
* The function detects that continuous inputs exist (`has_cont == 1.0`).
* It checks the categorical prerequisite constraint ($S_d == R_d$).
* **If prerequisites are met**, the discrete gate opens, and the effective input becomes the continuous scalar $\theta_1$. The probability evaluates identically to a standard 2PL curve scaling along the continuum variable.
* **If prerequisites are violated**, the item emits an extreme, overriding scalar penalty ($\psi_{ij} = -10.0$).

**Psychometric Implication:**
Under a standard logistic curve, $\text{logit}^{-1}(-10) \approx 0.000045$. This forces the probability of success to near-zero, strictly terminating the capacity for the continuous trait $\theta$ to compensate for the missing discrete skill. The item behaves exactly as a Non-Compensatory mixed-domain node should.

### Scenario 5: Compensatory and Disjunctive Topologies (DINM and DINO)

When researchers invoke strictly compensatory (`isDINM=1`) or disjunctive (`isDINO=1`) architectures, substituting the DINA rule constraint, the algorithm behaves algebraically across all domains.

* **DINM (Compensatory)**: Computes uniformly utilizing the mass inputs regardless of continuity properties by taking the ratio of possessed weight over total required weight.
  $$ \psi_{ij} = \frac{S_c + S_d}{\max(1, \sum w_p)} $$
  *Note: A high continuous draw in $S_c$ can successfully increase the ratio, directly modeling compensation.*
* **DINO (Disjunctive)**: Computes a straightforward logical bypass mapping:
  $$ \psi_{ij} = 1.0 \text{ if } (S_c + S_d > 0) \text{ else } 0.0 $$
  If the subject has *any* of the prerequisites (whether that is a categorical skill $\alpha=1$ or a sufficient continuous draw $\theta > 0$), they are granted full input mass.

## 5. Conclusion

The topological computation engine powering `loglinearBN` successfully abstracts the traditionally disjoint continuous (IRT) and categorical (CDM) parameter spaces. By utilizing the `calc_mixed_kernel` subroutine, the Bayesian structural compiler fluently handles unidimensional IRT, multidimensional compensatory arrays, strict categorical grouping rules, and complex gated hierarchies under a single, unified syntax standard.
