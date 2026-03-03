# Build Graph from an Adjacency Matrix

Constructs a directed `igraph` object from an adjacency matrix.
Identifies "Task" nodes based on columns present in the dataset.

## Usage

``` r
build_from_adjacency(
  AdjMatrixFile,
  DataFileCols,
  DefaultAttributeCompute = "zscore",
  DefaultTaskCompute = "dina"
)
```

## Arguments

- AdjMatrixFile:

  Character. Path to the CSV file containing the square adjacency
  matrix.

- DataFileCols:

  Character vector. Names of columns present in the observational data,
  used to map "Task" nodes.

- DefaultAttributeCompute:

  Character. Default compute rule for attributes. Default is "zscore".

- DefaultTaskCompute:

  Character. Default compute rule for tasks. Default is "dina".

## Value

A topologically sorted `igraph` object.
