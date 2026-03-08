# PGDCM: Probabilistic Graphical Diagnostic Classification Models

PGDCM stands for **Probabilistic Graphical Diagnostic Classification Models**. It is a unified framework for building and estimating several psychometric models within the probabilistic graphical modeling framework (i.e., treating these psychometric models as special cases of Bayesian networks, Hidden Markov Models, or Partially Observed Markov Decision Processes).

Currently supported models include:

* Diagnostic Classification Models (DCM)
* Higher-order Diagnostic Classification Models (HDCM)
* Multidimensional Item Response Theory (MIRT) Models
* Item Response Theory (IRT) Models
* Structural Equation Models (SEM)

We currently use [Cytoscape](https://cytoscape.org/) for graph building and [NIMBLE](https://r-nimble.org/) for Markov Chain Monte Carlo (MCMC) estimation. However, a core design philosophy of `pgdcm` is extensibility, allowing developers to swap out the MCMC sampler with other estimation algorithms in the future.

To interact with the graph building component, you will need to have Cytoscape installed and running on your system, as well as the **RCy3** R package. Using the Cytoscape template file that we provide ensures that the graph is built correctly for the estimation engine. Once a graph is built in Cytoscape, we use `igraph` for other operations.

We also provide many `igraph` edit functions in this package that can be used for graph building and graph editing. These are especially useful if you prefer a code-based workflow instead of Cytoscape, or if you want to eliminate the dependency on Cytoscape entirely.

*(Tip: You can use `pgdcm::get_Cyto_template()` in R to automatically copy this template into your working directory).*

## Installation

To install the package using `renv`, run the following command:

```R
renv::install("coinslab/pgdcm")
```

Alternatively, you can install the package using the `remotes` package:

```R
install.packages("remotes")
remotes::install_github("coinslab/pgdcm")
```
