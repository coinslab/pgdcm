# =============================================================================
# Graph_Helpers.R
# Description: Standardizing structural topologies and dataframe conversions.
# =============================================================================


#' Create a Standardized Node DataFrame
#'
#' Helper function to generate a well-formatted node \code{data.frame}.
#'
#' @param name Character vector of node identifiers.
#' @param type Character vector of node types (e.g., "Task", "Attribute").
#' @param compute Character vector indicating the compute rule (default is "dina").
#'
#' @return A \code{data.frame} formatted for graph construction.
#' @export
create_node_df <- function(name, type, compute = "dina") {
    data.frame(
        name = name,
        type = type,
        compute = compute,
        stringsAsFactors = FALSE
    )
}

#' Create a Standardized Edge DataFrame
#'
#' Helper function to generate a well-formatted edge \code{data.frame}.
#'
#' @param from Character vector of source node identifiers.
#' @param to Character vector of target node identifiers.
#'
#' @return A \code{data.frame} formatted for graph construction.
#' @export
create_edge_df <- function(from, to) {
    data.frame(
        from = from,
        to = to,
        color = "black",
        stringsAsFactors = FALSE
    )
}

#' Enforce Topological Sort on Attributes
#'
#' Topologically sorts the Attribute nodes in a graph and appends the Task nodes.
#' Useful for ensuring attributes are processed in dependency order.
#'
#' @param g An \code{igraph} object containing "Attribute" and "Task" nodes.
#'
#' @return A new \code{igraph} object with vertices ordered topologically.
#' @export
enforce_topo_sort <- function(g) {
    V(g)$type_id <- ifelse(tolower(V(g)$type) == "attribute", 1, 2)
    AttNodes <- V(g)[tolower(V(g)$type) == "attribute"]

    if (length(AttNodes) > 0) {
        g_att <- induced_subgraph(g, AttNodes)
        sorted_att_indices <- topo_sort(g_att, mode = "out")
        sorted_att_names <- V(g_att)[sorted_att_indices]$name

        OtherNodes <- V(g)[tolower(V(g)$type) != "attribute"]
        other_names <- OtherNodes$name

        final_order_names <- c(sorted_att_names, other_names)
        new_indices <- match(V(g)$name, final_order_names)
        g_sorted <- permute(g, new_indices)
        
        return(g_sorted)
    }
    return(g)
}
