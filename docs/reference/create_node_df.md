# Create a Standardized Node DataFrame

Helper function to generate a well-formatted node `data.frame`.

## Usage

``` r
create_node_df(name, type, compute = "dina")
```

## Arguments

- name:

  Character vector of node identifiers.

- type:

  Character vector of node types (e.g., "Task", "Attribute").

- compute:

  Character vector indicating the compute rule (default is "dina").

## Value

A `data.frame` formatted for graph construction.
