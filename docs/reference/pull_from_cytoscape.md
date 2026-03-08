# Pull Graph from Cytoscape

Pulls the current active network from Cytoscape, converts it to an
igraph object, and enforces a topological sort so it can be safely
compiled by the nimble BN/SEM engines.

## Usage

``` r
pull_from_cytoscape(
  network.title = NULL,
  base.url = "http://localhost:1234/v1"
)
```

## Arguments

- network.title:

  Character. The name of the network in Cytoscape to pull. If NULL,
  pulls the currently active network.

- base.url:

  Character. The base URL for the Cytoscape REST API. Default is
  `"http://localhost:1234/v1"`.

## Value

A topologically sorted `igraph` object.
