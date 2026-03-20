# Validate Graph Compute Nodes

Ensures that all nodes in the graph have a supported compute property.

## Usage

``` r
validate_graph_compute_nodes(graph)
```

## Arguments

- graph:

  An `igraph` object.

## Value

Boolean indicating if validation passed. Throws an error if unsupported
nodes are found.
