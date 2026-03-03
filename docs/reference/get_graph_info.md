# Extract Graph Information

Evaluates the `igraph` object to extract dimensional structural
properties, adjacency matrices, and compute rules required for Nimble
configuration.

## Usage

``` r
get_graph_info(g)
```

## Arguments

- g:

  An `igraph` object containing "Attribute" and "Task" nodes.

## Value

A list containing properties such as `nrnodes`, `nrattributenodes`,
`nrtasknodes`, and boolean flags for compute rules (e.g., `isDINA`).
