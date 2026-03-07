# =============================================================================
# Graph_Constructors.R
# Description: Native list/dataframe parsing to igraphs for various scenarios.
# =============================================================================

library(igraph)

#' Build Graph from a Q-Matrix
#'
#' Constructs a bipartite \code{igraph} object from a standard Q-matrix file.
#'
#' @param QMatrixFile Character. Path to the CSV file containing the Q-matrix.
#' @param DefaultAttributeCompute Character. Default compute rule for attributes. Default is "zscore".
#' @param DefaultTaskCompute Character. Default compute rule for tasks. Default is "dina".
#'
#' @return A topologically sorted \code{igraph} object representing the Q-matrix structure.
#' @export
build_from_q_matrix <- function(QMatrixFile, DefaultAttributeCompute = "dina", DefaultTaskCompute = "dina") {
    print(paste("Building from Q-Matrix:", QMatrixFile))
    Q <- read.csv(QMatrixFile, row.names = 1, check.names = FALSE)
    TaskNames <- rownames(Q)
    AttributeNames <- colnames(Q)

    AttNodes <- create_node_df(AttributeNames, "Attribute", DefaultAttributeCompute)
    TaskNodes <- create_node_df(TaskNames, "Task", DefaultTaskCompute)
    AllNodes <- rbind(AttNodes, TaskNodes)

    Edges <- data.frame(from = character(), to = character(), color = character(), stringsAsFactors = FALSE)
    for (t in TaskNames) {
        for (a in AttributeNames) {
            if (Q[t, a] == 1) {
                Edges <- rbind(Edges, create_edge_df(a, t))
            }
        }
    }

    g <- graph_from_data_frame(Edges, directed = TRUE, vertices = AllNodes)
    g <- enforce_topo_sort(g)

    return(g)
}

#' Build Graph from an Adjacency Matrix
#'
#' Constructs a directed \code{igraph} object from an adjacency matrix.
#' Identifies "Task" nodes based on columns present in the dataset.
#'
#' @param AdjMatrixFile Character. Path to the CSV file containing the square adjacency matrix.
#' @param DataFileCols Character vector. Names of columns present in the observational data, used to map "Task" nodes.
#' @param DefaultAttributeCompute Character. Default compute rule for attributes. Default is "zscore".
#' @param DefaultTaskCompute Character. Default compute rule for tasks. Default is "dina".
#'
#' @return A topologically sorted \code{igraph} object.
#' @export
build_from_adjacency <- function(AdjMatrixFile, DataFileCols, DefaultAttributeCompute = "zscore", DefaultTaskCompute = "dina") {
    print(paste("Building from Adjacency Matrix:", AdjMatrixFile))
    Adj <- read.csv(AdjMatrixFile, row.names = 1, check.names = FALSE)
    NodeNames <- rownames(Adj)

    if (!all(rownames(Adj) == colnames(Adj))) stop("Adjacency Matrix must be square.")

    DataCols <- DataFileCols

    Category <- rep("Attribute", length(NodeNames))
    Compute <- rep(DefaultAttributeCompute, length(NodeNames))

    for (i in seq_along(NodeNames)) {
        if (NodeNames[i] %in% DataCols) {
            Category[i] <- "Task"
            Compute[i] <- DefaultTaskCompute
        }
    }

    Nodes <- create_node_df(NodeNames, Category, Compute)
    Edges <- data.frame(from = character(), to = character(), color = character(), stringsAsFactors = FALSE)

    for (i in 1:nrow(Adj)) {
        for (j in 1:ncol(Adj)) {
            if (Adj[i, j] == 1) {
                Edges <- rbind(Edges, create_edge_df(NodeNames[i], NodeNames[j]))
            }
        }
    }

    g <- graph_from_data_frame(Edges, directed = TRUE, vertices = Nodes)
    g <- enforce_topo_sort(g)
    return(g)
}

#' Build Graph from Node and Edge Files
#'
#' Constructs a directed \code{igraph} object natively from separate node and edge CSV lists.
#'
#' @param NodesFile Character. Path to the CSV file containing node definitions.
#' @param EdgesFile Character. Path to the CSV file containing edge definitions.
#'
#' @return A topologically sorted \code{igraph} object.
#' @export
build_from_node_edge_files <- function(NodesFile, EdgesFile) {
    print(paste("Building from native nodes/edges lists:", NodesFile, EdgesFile))
    nodes <- read.csv(NodesFile, stringsAsFactors = FALSE)
    edges <- read.csv(EdgesFile, stringsAsFactors = FALSE)

    # Ensure uniform column mapping
    if ("id" %in% colnames(nodes)) colnames(nodes)[colnames(nodes) == "id"] <- "name"
    if ("category" %in% colnames(nodes)) colnames(nodes)[colnames(nodes) == "category"] <- "type"

    if ("source" %in% colnames(edges)) colnames(edges)[colnames(edges) == "source"] <- "from"
    if ("target" %in% colnames(edges)) colnames(edges)[colnames(edges) == "target"] <- "to"

    g <- graph_from_data_frame(edges, directed = TRUE, vertices = nodes)
    g <- enforce_topo_sort(g)

    return(g)
}
