# Extract Edges Table from Graph

Extracts the edge list from an `igraph` object and formats it into a
standardized edges `data.frame`.

## Usage

``` r
get_EdgesTable(graph)
```

## Arguments

- graph:

  An `igraph` object.

## Value

A `data.frame` containing the edges with columns `source` and `target`.
