# =============================================================================
# Graph_Editor.R
# Description: Interactive Graph Editor functions imported from collaborator.
# =============================================================================

library(igraph)
source(file.path("R", "Graph_Helpers.R"))
source(file.path("R", "Graph_Constructors.R"))

igrapheditversion <- "IGRAPHEDIT: VERSION 2.4 (revised 3/1/2026)"

#' Check Legal Edges
#'
#' @param igraphnodes A dataframe of nodes
#' @param igraphedges A dataframe of edges
#' @return A list of bad edges
#' @export
checklegaledges <- function(igraphnodes, igraphedges) {
  badedgelist <- c()
  nredges <- length(igraphedges$from)
  if (nredges > 0) {
    for (k in 1:nredges) {
      sourceedgesinnodelist <- which(igraphedges$from[k] == igraphnodes$name | igraphedges$from[k] == igraphnodes$id)
      targetedgesinnodelist <- which(igraphedges$to[k] == igraphnodes$name | igraphedges$to[k] == igraphnodes$id)
      nrbadsourcedges <- length(sourceedgesinnodelist)
      nrbadtargetedges <- length(targetedgesinnodelist)
      abadedge <- (nrbadsourcedges == 0) | (nrbadtargetedges == 0)
      if (abadedge) {
        badedgelist <- c(badedgelist, paste0(igraphedges$from[k], "->", igraphedges$to[k]))
      }
    }
  }
  return(badedgelist)
}

#' Read Igraph from Files
#'
#' @param FilePrefix The prefix for the nodes and edges files
#' @return An igraph object
#' @export
readigraph <- function(FilePrefix) {
  edgefilename <- paste0(FilePrefix, "edges.csv")
  nodefilename <- paste0(FilePrefix, "nodes.csv")

  if (file.exists(edgefilename) & file.exists(nodefilename)) {
    igraphedges <- read.csv(edgefilename, header = TRUE, stringsAsFactors = FALSE)
    igraphnodes <- read.csv(nodefilename, header = TRUE, stringsAsFactors = FALSE)
    badedgelist <- checklegaledges(igraphnodes, igraphedges)
    if (length(badedgelist) > 0) {
      writeLines("-----------------------------", stdout())
      fileupdateinfo <- paste0('Please check that column headers are "name" or "id" for node name in node file')
      writeLines(fileupdateinfo, stdout())
      fileupdateinfo <- paste0('Please check edge file column headers are "from" and "to" or "source" and "target"')
      writeLines(fileupdateinfo, stdout())
      fileupdateinfo <- paste0('Some nodes in the edge file \"', edgefilename, '\" were not found in the node file \"', nodefilename, '\"')
      writeLines(fileupdateinfo, stdout())
      fileupdateinfo2 <- paste0("Here is a list of the edges which included undefined nodes:")
      writeLines(fileupdateinfo2, stdout())
      print(badedgelist)
      writeLines("------------------------------", stdout())
      theigraph <- NULL
      Sys.sleep(10)
    } else {
      # Standardize names back to older igraphedit expected "from"/"to" or "name" when converting to igraph
      if ("id" %in% names(igraphnodes)) names(igraphnodes)[names(igraphnodes) == "id"] <- "name"
      if ("source" %in% names(igraphedges)) names(igraphedges)[names(igraphedges) == "source"] <- "from"
      if ("target" %in% names(igraphedges)) names(igraphedges)[names(igraphedges) == "target"] <- "to"

      theigraph <- graph_from_data_frame(igraphedges, directed = TRUE, vertices = igraphnodes)
    }

    # Setup a Backup directory if necessary and make backups
    ifelse(!dir.exists("BACKUP"), dir.create("BACKUP"), NA)

    maxbackups <- 15
    backupfoldername <- "BACKUP"
    deletefilepattern <- "\\.csv$"
    files_to_delete <- list.files(path = backupfoldername, pattern = deletefilepattern, full.names = TRUE, recursive = FALSE)
    if (length(files_to_delete) > maxbackups) {
      print("Cleaning up backup directory...will delete following old versions of files in 10 seconds...")
      print(files_to_delete)
      Sys.sleep(12)
      file.remove(files_to_delete)
    }

    # Make the BACKUP File
    nowtime <- Sys.time()
    timestamp <- format(nowtime, "%m%d%y%H%M")
    backupfilename <- paste0(FilePrefix, "BACKUP", timestamp)
    fullbackuppath <- file.path("BACKUP", backupfilename)
    writeigraph(fullbackuppath, theigraph)
  } else {
    fileupdateinfo <- paste0('Either the file \"', edgefilename, '\" or \"', nodefilename, '\" was not found.')
    writeLines(fileupdateinfo, stdout())
    theigraph <- NULL
  }
  return(theigraph)
}

#' Write Igraph to Files
#'
#' @param FilePrefix The prefix for the nodes and edges files
#' @param theigraph The igraph object to write
#' @export
writeigraph <- function(FilePrefix, theigraph) {
  edgefilename <- paste0(FilePrefix, "edges.csv")
  nodefilename <- paste0(FilePrefix, "nodes.csv")
  igraphedges <- as_data_frame(theigraph, what = "edges")
  igraphnodes <- as_data_frame(theigraph, what = "vertices")

  write.csv(igraphedges, edgefilename, row.names = FALSE)
  write.csv(igraphnodes, nodefilename, row.names = FALSE)
  fileupdateinfo <- paste0('Files \"', edgefilename, '\" and \"', nodefilename, '\" updated.')
  writeLines(fileupdateinfo, stdout())
}

#' View Parents and Children
#'
#' @param theigraph The igraph object
#' @param nodechoice The node to view
#' @export
viewparentsandchildren <- function(theigraph, nodechoice) {
  childnode <- V(theigraph)[V(theigraph)$name == nodechoice]
  if (length(childnode) > 0) {
    theparentnodes <- neighbors(theigraph, v = nodechoice, mode = "in")
    thechildnodes <- neighbors(theigraph, v = nodechoice, mode = "out")
    parentsandchildnodes <- union(childnode, union(theparentnodes, thechildnodes))
    parentsandchildsubgraph <- induced_subgraph(theigraph, v = parentsandchildnodes)
    # plot(parentsandchildsubgraph)
    nodelist <- parentsandchildnodes
    plot(parentsandchildsubgraph, main = paste0("Neighbors of Node ", nodechoice))
  } else {
    plot(theigraph, main = "Entire Competency and Evidence Graph")
    nodelist <- V(theigraph)
  }

  # print out node names
  nrnodes <- length(nodelist)
  for (k in 1:nrnodes) {
    nodeinfo <- V(theigraph)[nodelist[k]]$details
    if (is.null(nodeinfo)) nodeinfo <- "No details"
    nodename <- V(theigraph)[nodelist[k]]$name
    print(paste0(nodename, ":  ", nodeinfo))
  }
}

#' Add Edge
#'
#' @param theigraph The igraph object
#' @param fromnodechoice The source node
#' @param tonodechoice The target node
#' @param colornickname The color nickname
#' @return The updated igraph object
#' @export
edgeadd <- function(theigraph, fromnodechoice, tonodechoice, colornickname) {
  colorchoice <- switch(colornickname,
    "r" = "red",
    "b" = "blue",
    "g" = "green",
    "p" = "purple",
    "o" = "orange",
    "black"
  )
  okfromnodechoice <- (fromnodechoice %in% V(theigraph)$name)
  oktonodechoice <- (tonodechoice %in% V(theigraph)$name)

  if (okfromnodechoice & oktonodechoice) {
    newedge <- data.frame(from = fromnodechoice, to = tonodechoice, color = colorchoice)
    igraphedges <- as_data_frame(theigraph, what = "edges")
    igraphnodes <- as_data_frame(theigraph, what = "vertices")

    # Make sure column names map nicely
    if (!("color" %in% names(igraphedges))) igraphedges$color <- "black"

    combinededges <- rbind(igraphedges, newedge)

    combinedgraph <- graph_from_data_frame(combinededges, directed = TRUE, vertices = igraphnodes)

    # Important: Recalculate topological sort after adding edges
    theigraph <- enforce_topo_sort(combinedgraph)
  } else {
    print("----------------------------------------------------------------------------------------------------")
    print("*************************** Illegal Node Choice. Graph Not Modified.")
    print("----------------------------------------------------------------------------------------------------")
  }
  return(theigraph)
}

#' Delete Edge
#'
#' @param theigraph The igraph object
#' @param fromnodechoice The source node
#' @param tonodechoice The target node
#' @return The updated igraph object
#' @export
edgedelete <- function(theigraph, fromnodechoice, tonodechoice) {
  okfromnodechoice <- (fromnodechoice %in% V(theigraph)$name)
  oktonodechoice <- (tonodechoice %in% V(theigraph)$name)
  if (okfromnodechoice & oktonodechoice) {
    igraphedges <- as_data_frame(theigraph, what = "edges")
    igraphnodes <- as_data_frame(theigraph, what = "vertices")

    # Handle possible column name aliases from vs source
    f_col <- if ("from" %in% names(igraphedges)) "from" else "source"
    t_col <- if ("to" %in% names(igraphedges)) "to" else "target"

    selectededge <- (igraphedges[[t_col]] == tonodechoice) & (igraphedges[[f_col]] == fromnodechoice)
    leftoveredges <- igraphedges[!selectededge, ]
    theigraph <- graph_from_data_frame(leftoveredges, directed = TRUE, vertices = igraphnodes)

    # Recalculate topological sort after removing edges
    theigraph <- enforce_topo_sort(theigraph)
  }
  return(theigraph)
}

#' Change Layout
#'
#' @param theigraph The igraph object
#' @param layoutchoicestring The layout choice string
#' @export
LayoutChange <- function(theigraph, layoutchoicestring) {
  layoutchoice <- switch(layoutchoicestring,
    "st" = {
      plot(theigraph, layout = layout_as_star, main = "Competency and Evidence Graph")
    },
    "tr" = {
      plot(theigraph, layout = layout_as_tree, main = "Competency and Evidence Graph")
    },
    "ci" = {
      plot(theigraph, layout = layout_in_circle, main = "Competency and Evidence Graph")
    },
    "ni" = {
      plot(theigraph, layout = layout_nicely, main = "Competency and Evidence Graph")
    },
    "sp" = {
      plot(theigraph, layout = layout_on_sphere, main = "Competency and Evidence Graph")
    },
    "dh" = {
      plot(theigraph, layout = layout_with_dh, main = "Competency and Evidence Graph")
    },
    "fr" = {
      plot(theigraph, layout = layout_with_fr, main = "Competency and Evidence Graph")
    },
    "gm" = {
      plot(theigraph, layout = layout_with_gem, main = "Competency and Evidence Graph")
    },
    "kk" = {
      plot(theigraph, layout = layout_with_kk, main = "Competency and Evidence Graph")
    },
    "lg" = {
      plot(theigraph, layout = layout_with_lgl, main = "Competency and Evidence Graph")
    },
    "md" = {
      plot(theigraph, layout = layout_with_mds, main = "Competency and Evidence Graph")
    },
    "sg" = {
      plot(theigraph, layout = layout_with_sugiyama, main = "Competency and Evidence Graph")
    },
    "bp" = {
      plot(theigraph, layout = layout_as_bipartite, main = "Competency and Evidence Graph")
    },
  )
}

#' Run Interactive Graph Editor
#'
#' @export
igraphedit <- function(FilePrefix) {
  print(igrapheditversion)
  quitloop <- 0
  theigraph <- NULL
  while (quitloop == 0) {
    userchoice <- readline("r)ead, v)iew, a)dd, d)elete, l)ayout, q)uit: ")
    result <- switch(userchoice,
      "r" = {
        theigraph <- readigraph(FilePrefix)
        if (!is.null(theigraph)) plot(theigraph, main = "Competency and Evidence Graph")
      },
      "v" = {
        if (is.null(theigraph)) {
          print("Read graph first.")
          next
        }
        nodechoice <- readline("View neighbors of which node (e.g., A1)?: ")
        viewparentsandchildren(theigraph, nodechoice)
      },
      "a" = {
        if (is.null(theigraph)) {
          print("Read graph first.")
          next
        }
        fromnodechoice <- readline("ADD edge originating from node (e.g., A1)?: ")
        tonodechoice <- readline("Edge destination node (e.g., X2)?: ")
        colorchoice <- readline("Edge color? (e.g., r)ed,b)lue,g)reen,p)urple,o)range [enter/default=black])?: ")
        if (colorchoice == "") {
          colorchoice <- "black"
        }
        theigraph <- edgeadd(theigraph, fromnodechoice, tonodechoice, colorchoice)
        writeigraph(FilePrefix, theigraph)
        viewparentsandchildren(theigraph, tonodechoice)
      },
      "d" = {
        if (is.null(theigraph)) {
          print("Read graph first.")
          next
        }
        fromnodechoice <- readline("DELETE edge originating from node (e.g., A1)?: ")
        tonodechoice <- readline("Edge destination node (e.g., X2)?: ")
        theigraph <- edgedelete(theigraph, fromnodechoice, tonodechoice)
        writeigraph(FilePrefix, theigraph)
        viewparentsandchildren(theigraph, tonodechoice)
      },
      "l" = {
        if (is.null(theigraph)) {
          print("Read graph first.")
          next
        }
        layoutchoicestring <- readline("Layout (e.g., st,tr,ci,ni,sp,dh,fr,gm,kk,lg,md,sg)?: ")
        LayoutChange(theigraph, layoutchoicestring)
      },
      "q" = {
        quitloop <- 1
      }
    )
  }
  return(theigraph)
}
