# PGDCM: Probabilistic Graphical Diagnostic Classification Models

[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.19163714.svg)](https://doi.org/10.5281/zenodo.19163714)

PGDCM is a unified framework for building and estimating several
psychometric models within the probabilistic graphical modeling
framework (i.e., treating these psychometric models as special cases of
Bayesian networks, Hidden Markov Models, or Partially Observed Markov
Decision Processes).

Currently supported models include:

- Diagnostic Classification Models (DCM) with dichotomous responses
- Higher-order Diagnostic Classification Models (HDCM) with dichotomous
  responses
- Multidimensional Item Response Theory (MIRT) Models with dichotomous
  responses
- Item Response Theory (IRT) Models with dichotomous responses
- Linear and Logistic Structural Equation Models (SEM) with continuous
  responses \[experimental\]

## Key Features

PGDCM is designed to provide maximum flexibility through three core
pillars: **Modeling Capabilities**, **Estimation & Workflow**, and
**Architecture & Extensibility**.

### Modeling Capabilities

- **Unified Model Framework** - DCM, Higher-Order DCM, IRT, MIRT, and
  SEM are all treated as special cases of the same probabilistic
  graphical model. The graph structure alone determines the underlying
  model - no manual model selection flags are required.
- **Per-Item Compute Types** - Assign different response rules (e.g.,
  DINA, DINO, DINM) to individual items within a single model. Unlike
  traditional software that forces one global rule, `pgdcm` lets each
  item carry its own compensatory, non-compensatory, or additive logic.
- **Structural Skill Dependencies** - Easily model prerequisite
  relationships between skills (attribute hierarchies) or shared latent
  abilities (higher-order factors). The directed graph automatically
  encodes these dependencies for the estimator.
- **Latent Class Enumeration** - Automatically classify examinees into
  all $2^{K}$ possible mastery profiles and compute class-level
  prevalence rates for population-level diagnostic reporting.

### Estimation & Workflow

- **End-to-End Bayesian Pipeline** - A single function call orchestrates
  your entire analysis: prior predictive checking, MCMC sampling,
  convergence diagnostics, posterior predictive checking, and result
  extraction (skill profiles, item parameters, WAIC).
- **Operational Scoring** - Lock calibrated item parameters from a
  calibration sample to score new examinees against the validated
  framework.
- **Flexible Prior Specification** - Supply custom priors as simple
  `(mean, sd)` pairs or full per-parameter arrays. Omit priors for
  weakly informative defaults, or use near-zero variance to lock values
  for scoring workflows.
- **Missing Data Handling** - Built-in Bayesian missing data
  capabilities. Safely estimate item parameters and student profiles
  even when your response matrix has missing data.

### Architecture & Extensibility

- **Multiple Graph Input Methods** - Define your models any way you
  like: from a Q-matrix, adjacency matrix, node/edge CSV files, GraphML
  files, the Cytoscape GUI, or entirely in R code.
- **GUI & Code-Based Graph Building** - Build and visualize directed
  graphs interactively using the [Cytoscape](https://cytoscape.org/) UI,
  or opt for a completely code-based workflow using provided
  [igraph](https://igraph.org/r/) functions to eliminate external
  dependencies entirely.
- **NIMBLE Extensibility** - Built on the
  [NIMBLE](https://r-nimble.org/) probabilistic programming engine,
  advanced users can seamlessly swap in custom model code, samplers, or
  inference algorithms without leaving the package pipeline.

## Installation

Before installing the `pgdcm` package, you need to ensure some system
dependencies and essential R packages are installed, particularly for
NIMBLE and Cytoscape integration.

### 1. System Requirements (RTools / Xcode)

NIMBLE requires a C++ compiler to compile models.

- **macOS:** Open your terminal and run the following command to install
  Xcode Command Line Tools:

  ``` bash
  xcode-select --install
  ```

- **Windows:** Install
  [Rtools45](https://cran.r-project.org/bin/windows/Rtools/rtools45/rtools.html).
  We recommend using R version 4.5.1 or later. The package workflow is
  tested with R 4.5.1.

### 2. Install NIMBLE

Next, install the `nimble` package:

``` r
install.packages("nimble")
```

**Troubleshooting NIMBLE Installation:** If the standard installation
fails, try the following steps:

1.  First, install its dependencies manually:

    ``` r
    install.packages(c("igraph", "R6", "coda", "numDeriv", "pracma"))
    ```

2.  Then, install `nimble` from its source repository:

    ``` r
    # Install from source (type="source" is unnecessary for Linux)
    install.packages("nimble", repos = "https://r-nimble.org", type = "source")
    ```

### 3. Install pgdcm

Only after successfully installing the dependencies above should you
install the `pgdcm` package from GitHub.

Using `renv`:

``` r
renv::install("coinslab/pgdcm")
```

Alternatively, using `remotes`:

``` r
if (!requireNamespace("remotes", quietly = TRUE)) {
    install.packages("remotes")
}
remotes::install_github("coinslab/pgdcm")
```

## Getting Started

After installation, explore the tutorials in recommended order:

| Tutorial                                                                                                    | Description                                                 |
|:------------------------------------------------------------------------------------------------------------|:------------------------------------------------------------|
| [Beginner Tutorial](https://coinslab.github.io/pgdcm/articles/Beginner_Tutorial.html)                       | End-to-end introduction to Bayesian estimation with `pgdcm` |
| [Model Specification Tutorial](https://coinslab.github.io/pgdcm/articles/Model_Specification_Tutorial.html) | Constructing competency and evidence models in Cytoscape    |
| [Advanced Tutorial](https://coinslab.github.io/pgdcm/articles/Advanced_Tutorial.html)                       | Customizing priors, MCMC samplers, and diagnostic workflows |
| [Model Cookbook](https://coinslab.github.io/pgdcm/articles/Cookbook.html)                                   | Copy-paste recipes for IRT, DCM, AH-DCM, and HO-DCM         |
| [Scoring Cookbook](https://coinslab.github.io/pgdcm/articles/Scoring_Cookbook.html)                         | Operational calibration, scoring, and cross-validation      |

## Citation

If you use `pgdcm` in your research, please cite it as:

``` bibtex
@manual{pgdcm,
  title = {pgdcm: An R Package for Probabilistic Graphical Diagnostic Classification Modeling},
  author = {Athul Sudheesh and Richard M. Golden},
  year = {2026},
  note = {R package version 0.1.0},
  url = {https://github.com/coinslab/pgdcm},
  doi = {10.5281/zenodo.19163714}
}
```
