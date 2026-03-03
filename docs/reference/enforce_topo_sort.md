# Enforce Topological Sort on Attributes

Topologically sorts the Attribute nodes in a graph and appends the Task
nodes. Useful for ensuring attributes are processed in dependency order.

## Usage

``` r
enforce_topo_sort(g)
```

## Arguments

- g:

  An `igraph` object containing "Attribute" and "Task" nodes.

## Value

A new `igraph` object with vertices ordered topologically.
