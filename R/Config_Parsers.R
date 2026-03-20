# =============================================================================
# Config_Parsers.R
# Description: Structural parsers that translate an igraph into numeric constraints.
# =============================================================================


# ── Information Extraction ───────────────────────────────────────────────────
#' Extract Graph Information
#'
#' Evaluates the \code{igraph} object to extract dimensional structural properties,
#' adjacency matrices, and compute rules required for Nimble configuration.
#'
#' @param g An \code{igraph} object containing "Attribute" and "Task" nodes.
#'
#' @return A list containing properties such as \code{nrnodes}, \code{nrattributenodes},
#'   \code{nrtasknodes}, and boolean flags for compute rules (e.g., \code{isDINA}).
#' @export
get_graph_info <- function(g) {
    CDMmatrix <- t(as_adjacency_matrix(g, sparse = FALSE, type = "both"))

    # Filter for attributes (latent skills)
    attr_nodes <- V(g)[tolower(V(g)$type) == "attribute"]
    comp_graph <- induced_subgraph(g, attr_nodes)
    comp_matrix <- t(as_adjacency_matrix(comp_graph, sparse = FALSE, type = "both"))

    # Root nodes (In-degree 0 in the competency graph)
    root_indices <- which(degree(comp_graph, mode = "in") == 0)

    task_nodes <- V(g)[tolower(V(g)$type) == "task"]

    # Flags for DCM computation types (per node)
    isDINA <- as.numeric(tolower(V(g)$compute) == "dina")
    isDINO <- as.numeric(tolower(V(g)$compute) == "dino")
    isDINM <- as.numeric(tolower(V(g)$compute) == "dinm")

    # Deeper Structural Dimension Extraction
    nrnodes <- length(V(g))
    parentlocs <- matrix(data = 0, nrow = nrnodes, ncol = nrnodes)
    nrparents <- matrix(data = 0, nrow = 1, ncol = nrnodes)
    parentlist <- list()
    for (k in 1:nrnodes) {
        nrparents[k] <- sum(CDMmatrix[k, 1:nrnodes])
        parentsnodek <- which(CDMmatrix[k, 1:nrnodes] == 1)
        parentlist <- c(parentlist, list(parentsnodek))
        if (nrparents[k] > 0) {
            parentlocs[k, 1:nrparents[k]] <- parentsnodek
        }
    }
    inputparentlocs <- cbind(rep(length(attr_nodes) + 1, nrnodes), parentlocs)
    nrnodeinputs <- rowSums(CDMmatrix)

    subvecdims <- nrparents + 1
    startbetadim <- matrix(data = 0, nrow = 1, ncol = nrnodes)
    endbetadim <- matrix(data = 0, nrow = 1, ncol = nrnodes)
    startbetadim[1] <- 1
    endbetadim[1] <- subvecdims[1]
    if (nrnodes > 1) {
        for (k in 2:nrnodes) {
            startbetadim[k] <- 1 + sum(subvecdims[1:(k - 1)])
            endbetadim[k] <- startbetadim[k] + subvecdims[k] - 1
        }
    }

    list(
        graph = g,
        matrix = CDMmatrix,
        comp_graph = comp_graph,
        comp_matrix = comp_matrix,
        nrnodes = length(V(g)),
        nrattributenodes = length(attr_nodes),
        nrtasknodes = length(task_nodes),
        nrbetaroot = length(root_indices),
        isDINA = isDINA,
        isDINO = isDINO,
        isDINM = isDINM,
        attr_computes = tolower(attr_nodes$compute),
        parentlocs = parentlocs,
        nrparents = nrparents,
        parentlist = parentlist,
        inputparentlocs = inputparentlocs,
        nrnodeinputs = nrnodeinputs,
        subvecdims = subvecdims,
        startbetadim = startbetadim,
        endbetadim = endbetadim
    )
}

# ── Model Type Determination ─────────────────────────────────────────────────
#' Determine Model Type
#'
#' Classifies the type of model (SEM vs DCM) explicitly by evaluating
#' the structure of the latent attributes and tasks.
#'
#' @param info A list of graph properties returned by \code{get_graph_info}.
#'
#' @return A character string denoting the model type ("SEM" or "DCM").
#' @export
determine_model_type <- function(info) {
    # Check if all tasks are discrete (logit/dina style) vs continuous
    tasks_continuous <- all(tolower(V(info$graph)[tolower(V(info$graph)$type) == "task"]$compute) == "zscore")
    tasks_all_cdm <- all(tolower(V(info$graph)[tolower(V(info$graph)$type) == "task"]$compute) %in% c("dina", "dino", "dinm"))

    # Check attributes
    all_attr_continuous <- all(info$attr_computes %in% c("zscore", "continuous"))
    all_attr_pattern <- all(info$attr_computes == "pattern")

    if (tasks_continuous && all_attr_continuous) {
        return("SEM")
    }
    if (all_attr_pattern && tasks_all_cdm) {
        return("LCDCM")
    }

    return("DCM")
}
