# Build Model Configuration

The primary entry point for bridging the structural `igraph` topology
and the observational data frame into a compiled Nimble configuration
list. Automatically detects the exact model geometry to invoke the
appropriate compiler.

## Usage

``` r
build_model_config(graph, dataframe)
```

## Arguments

- graph:

  An `igraph` object representing the conceptual architecture.

- dataframe:

  A `data.frame` of raw responses matching graph Tasks.

## Value

A configuration list encompassing Nimble constants, initialization
functions, data references, and source model file trajectories.
