# PGDCM: Probabilistic Graphical Diagnostic Classification Models

PGDCM is a unified framework for building and estimating several psychometric models within the probabilistic graphical modeling framework (i.e., treating these psychometric models as special cases of Bayesian networks, Hidden Markov Models, or Partially Observed Markov Decision Processes).

Currently supported models include:

* Diagnostic Classification Models (DCM)
* Higher-order Diagnostic Classification Models (HDCM)
* Multidimensional Item Response Theory (MIRT) Models
* Item Response Theory (IRT) Models
* Structural Equation Models (SEM)

We currently use [Cytoscape](https://cytoscape.org/) for graph building and [NIMBLE](https://r-nimble.org/) for Markov Chain Monte Carlo (MCMC) estimation. However, a core design philosophy of `pgdcm` is extensibility, allowing developers to swap out the MCMC sampler with other estimation algorithms in the future.

To interact with the graph building component, you will need to have Cytoscape installed and running on your system, as well as the **RCy3** R package. Using the Cytoscape template file that we provide ensures that the graph is built correctly for the estimation engine. Once a graph is built in Cytoscape, we use `igraph` for other operations.

We also provide many `igraph` edit functions in this package that can be used for graph building and graph editing. These are especially useful if you prefer a code-based workflow instead of Cytoscape, or if you want to eliminate the dependency on Cytoscape entirely.

## Installation

Before installing the `pgdcm` package, you need to ensure some system dependencies and essential R packages are installed, particularly for NIMBLE and Cytoscape integration.

### 1. System Requirements (RTools / Xcode)

NIMBLE requires a C++ compiler to compile models.

* **macOS:** Open your terminal and run the following command to install Xcode Command Line Tools:

  ```bash
  xcode-select --install
  ```

* **Windows:** Install [Rtools45](https://cran.r-project.org/bin/windows/Rtools/rtools45/rtools.html). We recommend using R version 4.5.1 or later. The package workflow is tested with R 4.5.1.

### 2. Install NIMBLE

Next, install the `nimble` package:

```r
install.packages("nimble")
```

**Troubleshooting NIMBLE Installation:**
If the standard installation fails, try the following steps:

1. First, install its dependencies manually:

   ```r
   install.packages(c("igraph", "R6", "coda", "numDeriv", "pracma"))
   ```

2. Then, install `nimble` from its source repository:

   ```r
   # Install from source (type="source" is unnecessary for Linux)
   install.packages("nimble", repos = "https://r-nimble.org", type = "source")
   ```

### 3. Install RCy3

`RCy3` is required for interacting with Cytoscape. Install it via Bioconductor:

```r
if (!"RCy3" %in% installed.packages()) {
    install.packages("BiocManager")
    BiocManager::install("RCy3")
}
```

Alternatively, using `renv`:

```r
renv::install("bioc::RCy3")
```

*Note: If prompted with "Do you want to attempt to install these from sources? (Yes/no/cancel)", type `Yes` and press Enter.*

### 4. Install pgdcm

Only after successfully installing the dependencies above should you install the `pgdcm` package from GitHub.

Using `renv`:

```r
renv::install("coinslab/pgdcm")
```

Alternatively, using `remotes`:

```r
if (!requireNamespace("remotes", quietly = TRUE)) {
    install.packages("remotes")
}
remotes::install_github("coinslab/pgdcm")
```
