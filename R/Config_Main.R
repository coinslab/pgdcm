# =============================================================================
# Config_Main.R
# Description: Public interface for generating unified nimble configurations.
# =============================================================================

library(igraph)

# ── Validation ───────────────────────────────────────────────────────────────
#' Validate Graph against Dataset
#'
#' Replicates the strict, verbose validation from legacy functions to catch
#' dataset/node alignment issues early.
#'
#' @param graph An \code{igraph} object representing the conceptual architecture.
#' @param dataframe A \code{data.frame} of raw responses matching graph Tasks.
#'
#' @return Boolean indicating if validation passed. Prints warnings if it fails.
#' @export
validate_graph_and_data <- function(graph, dataframe) {
    # Get list of all graph nodes
    graphnodelist <- V(graph)$name
    
    # Get list of data set nodes
    dataframeheaderlist <- names(dataframe)
    datanodelist <- dataframeheaderlist[-1]  # all headers except column 1 (e.g. ID)
    
    tasknodelist <- V(graph)[tolower(V(graph)$type) != "attribute"]$name
    
    usermessage <- c()
    spacerline <- "------------------------------"
    
    # Get list of duplicate data nodes
    is_duplicate <- duplicated(datanodelist)
    dataduplicatelist <- datanodelist[is_duplicate]
    if (length(dataduplicatelist) > 0){
        themessage <- "WARNING! Following duplicate data nodes were found in dataset:"
        usermessage <- c(usermessage, themessage, dataduplicatelist, spacerline)
    }
    
    # Get list of the task nodes in graph which are not in the data nodes list
    tasknodesnotindata <- setdiff(tasknodelist, datanodelist)
    if (length(tasknodesnotindata) > 0){
        themessage <- "WARNING! Following task-nodes in graph were not found in the dataset:"
        usermessage <- c(usermessage, themessage, tasknodesnotindata, spacerline)
    }
    
    # Get list of the data nodes in data file which are not in the task nodes list
    datanodesnotintask <- setdiff(datanodelist, tasknodelist)
    if (length(datanodesnotintask) > 0){
        themessage <- "WARNING! Following data nodes in dataset were not in the task-nodes in graph:"
        usermessage <- c(usermessage, themessage, datanodesnotintask, spacerline)
    }
    
    if (length(usermessage) > 0) {
        print(usermessage)
        Sys.sleep(30)
        return(FALSE)
    }
    
    return(TRUE)
}

# ── Main Entry ───────────────────────────────────────────────────────────────
#' Build Model Configuration
#'
#' The primary entry point for bridging the structural \code{igraph} topology
#' and the observational data frame into a compiled Nimble configuration list.
#' Automatically detects the exact model geometry to invoke the appropriate compiler.
#'
#' @param graph An \code{igraph} object representing the conceptual architecture.
#' @param dataframe A \code{data.frame} of raw responses matching graph Tasks.
#'
#' @return A configuration list encompassing Nimble constants, initialization functions,
#'    data references, and source model file trajectories.
#' @export
build_model_config <- function(graph, dataframe) {
    if (!validate_graph_and_data(graph, dataframe)) {
        stop("Graph/Data validation failed. See warnings above.")
    }

    info <- get_graph_info(graph)

    # Align dataset columns with task nodes
    X_mat <- as.matrix(dataframe)
    
    dataidsortlist <- c()
    task_names <- V(graph)[tolower(V(graph)$type) == "task"]$name
    for (tname in task_names) {
        colid <- which(names(dataframe) == tname)
        dataidsortlist <- c(dataidsortlist, colid)
    }

    # First column is usually respondent ID or similar, we keep it then add sorted data
    new_dataframe <- dataframe[, c(1, dataidsortlist), drop = FALSE]
    
    X <- as.matrix(new_dataframe[, -1, drop = FALSE])

    m_type <- determine_model_type(info)
    print(paste("Detected Model Type:", m_type))

    # Helper function to find the model files whether running from source or installed package
    get_model_path <- function(filename) {
        path <- system.file("models", filename, package = "pgdcm")
        if (path == "") path <- file.path("inst", "models", filename)
        return(path)
    }

    if (m_type == "SEM") {
        cfg <- configure_sem(info, X)
        cfg$code_file <- get_model_path("loglinearSEM.R")
        cfg$model_object <- "loglinearSEM"
    } else {
        cfg <- configure_dcm(info, X)
        cfg$code_file <- get_model_path("loglinearBN.R")
        cfg$model_object <- "loglinearBN"
    }

    cfg$graph <- graph
    cfg$type <- m_type

    return(cfg)
}
