# Validate Graph against Dataset

Replicates the strict, verbose validation from legacy functions to catch
dataset/node alignment issues early.

## Usage

``` r
validate_graph_and_data(graph, dataframe)
```

## Arguments

- graph:

  An `igraph` object representing the conceptual architecture.

- dataframe:

  A `data.frame` of raw responses matching graph Tasks.

## Value

Boolean indicating if validation passed. Prints warnings if it fails.
