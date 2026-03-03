# Extract Nodes Table from Graph

Extracts the vertex attributes from an `igraph` object and formats them
into a standardized nodes `data.frame`.

## Usage

``` r
get_NodesTable(graph)
```

## Arguments

- graph:

  An `igraph` object.

## Value

A `data.frame` containing the nodes with columns `id`, `type`, and
`compute`.
