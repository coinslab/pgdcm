# Determine Model Type

Classifies the type of model (SEM vs DCM) explicitly by evaluating the
structure of the latent attributes and tasks.

## Usage

``` r
determine_model_type(info)
```

## Arguments

- info:

  A list of graph properties returned by `get_graph_info`.

## Value

A character string denoting the model type ("SEM" or "DCM").
