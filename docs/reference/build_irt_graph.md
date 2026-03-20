# Build Graph for an IRT Model

Constructs a single-attribute `igraph` object directly from a list of
task names, bypassing the need for a Q-matrix file. All tasks are
assumed to require the single ability.

## Usage

``` r
build_irt_graph(
  task_names,
  ability_name = "Theta",
  default_task_compute = "dina"
)
```

## Arguments

- task_names:

  Character vector. Names of the tasks (columns from the dataset).

- ability_name:

  Character. Name of the single latent trait. Default is "Theta".

- default_task_compute:

  Character. Default compute rule for tasks. Default is "dina".

## Value

A topologically sorted `igraph` object representing the IRT structure.
