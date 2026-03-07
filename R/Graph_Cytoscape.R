# =============================================================================
# Graph_Cytoscape.R
# Description: REST API payload handling and edge list mapping specific
# to Cytoscape visualization.
# =============================================================================

library(igraph)

#' Push Graph to Cytoscape
#'
#' Sends the graph structure to a running Cytoscape instance for visualization.
#'
#' @param ... Arguments passed to \code{createNetworkFromDataFrames}.
#' @param base.url Character. The base URL for the Cytoscape REST API. Default is \code{"http://localhost:1234/v1"}.
#'
#' @return Invisible SUID of the created network in Cytoscape.
#' @export
push_to_cytoscape <- function(..., base.url = "http://localhost:1234/v1") {
    if (!requireNamespace("RCy3", quietly = TRUE)) stop("Please install RCy3 to use Cytoscape.")
    library(RCy3)
    suid <- createNetworkFromDataFrames(..., base.url = base.url)
    setVisualStyle("Directed", base.url = base.url)
    invisible(suid)
}

#' Extract Nodes Table from Graph
#'
#' Extracts the vertex attributes from an \code{igraph} object and formats them
#' into a standardized nodes \code{data.frame}.
#'
#' @param graph An \code{igraph} object.
#'
#' @return A \code{data.frame} containing the nodes with columns \code{id}, \code{type}, and \code{compute}.
#' @export
get_NodesTable <- function(graph) {
    df <- as_data_frame(graph, what = "vertices")
    colnames(df)[colnames(df) == "name"] <- "id"
    cols_to_keep <- intersect(c("id", "type", "compute"), colnames(df))
    df[, cols_to_keep, drop = FALSE]
}

#' Extract Edges Table from Graph
#'
#' Extracts the edge list from an \code{igraph} object and formats it
#' into a standardized edges \code{data.frame}.
#'
#' @param graph An \code{igraph} object.
#'
#' @return A \code{data.frame} containing the edges with columns \code{source} and \code{target}.
#' @export
get_EdgesTable <- function(graph) {
    df <- as_data_frame(graph, what = "edges")
    colnames(df)[colnames(df) == "from"] <- "source"
    colnames(df)[colnames(df) == "to"] <- "target"
    cols_to_keep <- intersect(c("source", "target"), colnames(df))
    df[, cols_to_keep, drop = FALSE]
}

#' Push Standalone Task Nodes to Cytoscape
#'
#' Pushes an orphaned list of task nodes directly to Cytoscape without edges.
#'
#' @param task_names Character vector of task node IDs.
#' @param compute Character. Default compute rule. Default is "dina".
#'
#' @export
Tasks2CytoNodes <- function(task_names, compute = "dina") {
    nodes <- data.frame(
        id = task_names,
        type = rep("task", length(task_names)),
        compute = rep(compute, length(task_names)),
        stringsAsFactors = FALSE
    )
    edges <- data.frame(
        source = character(0),
        target = character(0),
        interaction = character(0),
        stringsAsFactors = FALSE
    )
    push_to_cytoscape(nodes, edges)
    message(sprintf("✓ %d task nodes pushed to Cytoscape", length(task_names)))
}

#' Convert Q-Matrix directly to igraph
#'
#' @param Q A data.frame acting as the Q-Matrix, where the first column contains Task IDs and remaining columns are Attributes.
#' @param compute Character. Compute rule applied uniformly to tasks and attributes. Default is "dina".
#'
#' @return A directed \code{igraph} object.
#' @export
QMatrix2iGraph <- function(Q, compute = "dina") {
    tasks <- as.character(Q[[1]])
    attrs <- colnames(Q)[-1]

    # Build uniform nodes table
    nodes <- data.frame(
        name = c(tasks, attrs),
        type = c(rep("task", length(tasks)), rep("attribute", length(attrs))),
        compute = rep(compute, length(tasks) + length(attrs)),
        stringsAsFactors = FALSE
    )

    # Build edges where Q == 1
    edges <- data.frame(from = character(), to = character(), interaction = character(), stringsAsFactors = FALSE)
    for (i in seq_along(tasks)) {
        for (j in seq_along(attrs)) {
            if (Q[i, j + 1] == 1) {
                # Edge goes FROM attribute TO task
                edges <- rbind(edges, data.frame(
                    from = attrs[j],
                    to = tasks[i],
                    stringsAsFactors = FALSE
                ))
            }
        }
    }

    # Create the igraph object
    g <- graph_from_data_frame(d = edges, vertices = nodes, directed = TRUE)
    g <- enforce_topo_sort(g)
    return(g)
}

#' Push Q-Matrix to Cytoscape
#'
#' @param Q A data.frame Q-Matrix setup.
#' @param compute Character. Default compute rule.
#' @param title Character. The Network Title in Cytoscape.
#'
#' @return SUID of pushed Cytoscape Network.
#' @export
QMatrix2CytoNodes <- function(Q, compute = "dina", title = "Scenario2_QMatrix") {
    g <- QMatrix2iGraph(Q, compute = compute)

    # Use our helpers to get RCy3-ready data frames
    nodes_table <- get_NodesTable(g)
    edges_table <- get_EdgesTable(g)

    push_to_cytoscape(nodes_table, edges_table, title = title, collection = "PGDCM Scenario 2")
    message(sprintf("✓ Pushed Q-Matrix network to Cytoscape: %d nodes, %d edges", vcount(g), ecount(g)))
    return(g)
}

#' Convert Adjacency Matrix directly to igraph
#'
#' @param Adj A data.frame adjacency matrix evaluating structural transitions.
#' @param compute Character. Default compute rule applied iteratively.
#'
#' @return A directed \code{igraph} object.
#' @export
AdjMatrix2iGraph <- function(Adj, compute = "dina") {
    node_names <- as.character(Adj[[1]])

    # Build uniform nodes table (type left empty/NA for user to fill)
    nodes <- data.frame(
        name = node_names,
        type = rep("Unspecified", length(node_names)),
        compute = rep(compute, length(node_names)),
        stringsAsFactors = FALSE
    )

    # Build edges where Adj == 1
    edges <- data.frame(from = character(), to = character(), interaction = character(), stringsAsFactors = FALSE)
    for (i in seq_along(node_names)) {
        col_names <- colnames(Adj)[-1]
        for (j in seq_along(col_names)) {
            if (Adj[i, j + 1] == 1) {
                # Edge goes FROM row node TO column node
                edges <- rbind(edges, data.frame(
                    from = node_names[i],
                    to = col_names[j],
                    interaction = "directed",
                    stringsAsFactors = FALSE
                ))
            }
        }
    }

    # Create the igraph object
    g <- graph_from_data_frame(d = edges, vertices = nodes, directed = TRUE)
    g <- enforce_topo_sort(g)
    return(g)
}

#' Push Adjacency Matrix to Cytoscape
#'
#' @param Adj A data.frame Adjacency Matrix setup.
#' @param compute Character. Default compute rule.
#' @param title Character. The Network Title in Cytoscape.
#'
#' @return SUID of pushed Cytoscape Network.
#' @export
AdjMatrix2CytoNodes <- function(Adj, compute = "dina", title = "Scenario3_AdjMatrix") {
    g <- AdjMatrix2iGraph(Adj, compute = compute)

    nodes_table <- get_NodesTable(g)
    edges_table <- get_EdgesTable(g)

    push_to_cytoscape(nodes_table, edges_table, title = title, collection = "PGDCM Scenario 3")
    message(sprintf("✓ Pushed Adjacency Matrix network to Cytoscape: %d nodes, %d edges", vcount(g), ecount(g)))
    return(g)
}

#' Pull Graph from Cytoscape
#'
#' Pulls the current active network from Cytoscape, converts it to an igraph object,
#' and enforces a topological sort so it can be safely compiled by the nimble BN/SEM engines.
#'
#' @param network.title Character. The name of the network in Cytoscape to pull. If NULL, pulls the currently active network.
#' @param base.url Character. The base URL for the Cytoscape REST API. Default is \code{"http://localhost:1234/v1"}.
#'
#' @return A topologically sorted \code{igraph} object.
#' @export
pull_from_cytoscape <- function(network.title = NULL, base.url = "http://localhost:1234/v1") {
    if (!requireNamespace("RCy3", quietly = TRUE)) stop("Please install RCy3 to use Cytoscape.")
    library(RCy3)

    # Check if network exists
    if (!is.null(network.title)) {
        net_list <- getNetworkList(base.url = base.url)
        if (!(network.title %in% net_list)) {
            stop(sprintf("Network '%s' not found in Cytoscape.", network.title))
        }
        # Set it as current so createIgraphFromNetwork targets it
        setCurrentNetwork(network = network.title, base.url = base.url)
    }

    # Pull raw network
    g_raw <- createIgraphFromNetwork(network = "current", base.url = base.url)
    message(sprintf("✓ Pulled network from Cytoscape: %d nodes, %d edges", vcount(g_raw), ecount(g_raw)))

    # Enforce Topological Sort for Nimble Compatibility
    g_sorted <- enforce_topo_sort(g_raw)
    message("✓ Enforced topological sort for Nimble compilation")

    return(g_sorted)
}
