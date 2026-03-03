# Build Graph from a Q-Matrix

Constructs a bipartite `igraph` object from a standard Q-matrix file.

## Usage

``` r
build_from_q_matrix(
  QMatrixFile,
  DefaultAttributeCompute = "zscore",
  DefaultTaskCompute = "dina"
)
```

## Arguments

- QMatrixFile:

  Character. Path to the CSV file containing the Q-matrix.

- DefaultAttributeCompute:

  Character. Default compute rule for attributes. Default is "zscore".

- DefaultTaskCompute:

  Character. Default compute rule for tasks. Default is "dina".

## Value

A topologically sorted `igraph` object representing the Q-matrix
structure.
