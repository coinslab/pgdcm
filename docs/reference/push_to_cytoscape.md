# Push Graph to Cytoscape

Sends the graph structure to a running Cytoscape instance for
visualization.

## Usage

``` r
push_to_cytoscape(network, ..., base.url = "http://localhost:1234/v1")
```

## Arguments

- network:

  An `igraph` object or a `data.frame` of nodes.

- ...:

  Additional arguments passed to `createNetworkFromIgraph` or
  `createNetworkFromDataFrames`.

- base.url:

  Character. The base URL for the Cytoscape REST API. Default is
  `"http://localhost:1234/v1"`.

## Value

Invisible SUID of the created network in Cytoscape.
