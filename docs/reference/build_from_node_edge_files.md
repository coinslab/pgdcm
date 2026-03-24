# Build Graph from Node and Edge Files

Constructs a directed `igraph` object from separate node and edge CSV
lists.

## Usage

``` r
build_from_node_edge_files(NodesFile, EdgesFile)
```

## Arguments

- NodesFile:

  Character. Path to the CSV file containing node definitions.

- EdgesFile:

  Character. Path to the CSV file containing edge definitions.

## Value

A topologically sorted `igraph` object.
