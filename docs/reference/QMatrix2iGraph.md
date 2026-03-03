# Convert Q-Matrix directly to igraph

Convert Q-Matrix directly to igraph

## Usage

``` r
QMatrix2iGraph(Q, compute = "dina")
```

## Arguments

- Q:

  A data.frame acting as the Q-Matrix, where the first column contains
  Task IDs and remaining columns are Attributes.

- compute:

  Character. Compute rule applied uniformly to tasks and attributes.
  Default is "dina".

## Value

A directed `igraph` object.
