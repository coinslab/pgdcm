# Build Model Configuration

The primary entry point for bridging the structural `igraph` topology
and the observational data frame into a compiled Nimble configuration
list. Automatically detects the exact model geometry to invoke the
appropriate compiler.

## Usage

``` r
build_model_config(graph, dataframe, priors = NULL)
```

## Arguments

- graph:

  An `igraph` object representing the conceptual architecture.

- dataframe:

  A `data.frame` of raw responses matching graph Tasks.

- priors:

  Optional list of prior specifications. See `configure_dcm` or
  `configure_sem` for details.

## Value

A configuration list encompassing Nimble requirements. The list
contains:

- `constants`: A list of graph constants (e.g., node counts, adjacency
  matrices, priors).

- `inits`: A list containing initial values for MCMC sampling (e.g.,
  `beta_root`, `theta`, `lambda`).

- `monitors`: A character vector of node names to monitor during MCMC.

- `data`: A list containing the aligned observational response matrix
  `X`.

- `code_file`: The resolved absolute path to the underlying Nimble model
  generator script.

- `model_object`: A character string denoting the name of the function
  to invoke (e.g., `"DiBelloBN"`).

- `graph`: The fully verified and topologically sorted `igraph` object.

- `type`: A character string denoting the detected architecture (e.g.,
  `"DCM"`, `"SEM"`).
