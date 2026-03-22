# PGDCM: Probabilistic Graphical Diagnostic Classification Models

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
  responses

We currently use [Cytoscape](https://cytoscape.org/) to provide a
powerful graphical user-interface for directed graph construction and
viewing, [igraph](https://igraph.org/r/) for graph processing and
manipulation functions, and [NIMBLE](https://r-nimble.org/) for Markov
Chain Monte Carlo (MCMC) estimation in R. This extensibility allows
developers to not only make full use of the wide variety of existing
estimation and inference algorithms NIMBLE but additionally provides
mechanisms for custom user-developed estimation and inference
algorithms.

To interact with the graph building component, you will need to have
Cytoscape installed and running on your system, as well as the **RCy3**
R package. Using the Cytoscape template file that we provide supports
correct construction of the probabilistic graphical model. Once
Cytoscape is running, the user may import the probabilistic graphical
model specifications using a spreadsheet/CSV format, create the
probabilistic graphical model directly within the Cytoscape environment,
or edit an existing probabilistic graphical model within Cytoscape. The
resulting probabilistic graphical model is then exported from Cytoscape
and can then be processed by `NIMBLE` and `igraph`.

We also provide many `igraph` edit functions in this package that can be
used for graph building and graph editing. These are especially useful
if you prefer a code-based workflow instead of Cytoscape, or if you want
to eliminate the dependency on Cytoscape entirely.

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
