# Convert Adjacency Matrix directly to igraph

Convert Adjacency Matrix directly to igraph

## Usage

``` r
AdjMatrix2iGraph(Adj, compute = "dina")
```

## Arguments

- Adj:

  A data.frame adjacency matrix evaluating structural transitions.

- compute:

  Character. Default compute rule applied iteratively.

## Value

A directed `igraph` object.
