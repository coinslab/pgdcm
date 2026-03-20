## ----setup, message=FALSE, warning=FALSE, eval=FALSE--------------------------
# # Load required libraries
# library(RCy3)
# library(igraph)
# library(readxl)
# library(pgdcm)
# 
# # Verify connection to Cytoscape
# cytoPort <- "http://localhost:1234/v1"
# cytoscapePing(cytoPort)


## ----scen1-push, eval=FALSE---------------------------------------------------
# # Read the X matrix
# X <- read_excel("testdatafile.xlsx", sheet = 1)
# message(sprintf("Loaded X matrix: %d students × %d items", nrow(X), ncol(X) - 1))
# 
# # Drop the Subject column; remaining columns are the task (item) names
# task_names <- colnames(X)[-1]
# 
# # Build nodes from task names and push to Cytoscape
# Tasks2CytoNodes(task_names)


## ----scen1-pull, eval=FALSE---------------------------------------------------
# # Fetch the active network from Cytoscape
# myNetwork1 <- pull_from_cytoscape(base.url = cytoPort)
# 
# # Extract clean node and edge tables using our utilities
# nodes_table1 <- get_NodesTable(myNetwork1)
# edges_table1 <- get_EdgesTable(myNetwork1)
# 
# # Check out what we got!
# head(nodes_table1)
# head(edges_table1)
# 
# # Save the network for later
# write_graph(myNetwork1, "Scenario1_network.graphml", format = "graphml")


## ----scen2-push, eval=FALSE---------------------------------------------------
# # Define a mock Q-Matrix
# Q_mock <- data.frame(
#     Task = c("Q1", "Q2", "Q3", "Q4", "Q5"),
#     A1 = c(1, 0, 1, 1, 0),
#     A2 = c(0, 1, 1, 0, 1),
#     stringsAsFactors = FALSE
# )
# 
# # Build igraph and push to Cytoscape simultaneously
# g_qmatrix <- QMatrix2CytoNodes(Q_mock, title = "Scenario2_QMatrix")


## ----scen2-pull, eval=FALSE---------------------------------------------------
# myNetwork2 <- pull_from_cytoscape(base.url = cytoPort)
# 
# # Fetching the nodes and edges from the network in Cytoscape
# nodes_table2 <- get_NodesTable(myNetwork2)
# edges_table2 <- get_EdgesTable(myNetwork2)
# 
# # Displaying the nodes and edges in R
# knitr::kable(nodes_table2, caption = "Nodes Table")
# knitr::kable(edges_table2, caption = "Edges Table")
# 
# # We comment out write_graph here during rendering so it doesn't constantly overwrite your file
# # write_graph(myNetwork2, "Scenario2_network.graphml", format = "graphml")


## ----scen3-push, eval=FALSE---------------------------------------------------
# # Define a mock Adjacency Matrix
# Adj_mock <- data.frame(
#     Node = c("A1", "A2", "Q1", "Q2"),
#     A1 = c(0, 1, 1, 0),
#     A2 = c(0, 0, 0, 1),
#     Q1 = c(0, 0, 0, 0),
#     Q2 = c(0, 0, 0, 0),
#     stringsAsFactors = FALSE
# )
# 
# # Build igraph and push to Cytoscape simultaneously
# g_adj <- AdjMatrix2CytoNodes(Adj_mock, title = "Scenario3_AdjMatrix")


## ----scen3-pull, eval=FALSE---------------------------------------------------
# # Pull the completed graph down from Cytoscape
# myNetwork3 <- pull_from_cytoscape(base.url = cytoPort)
# 
# # (Optional) Extract the raw tables for visual inspection
# nodes_table3 <- get_NodesTable(myNetwork3)
# edges_table3 <- get_EdgesTable(myNetwork3)
# 
# knitr::kable(nodes_table3, caption = "Nodes Data")
# knitr::kable(edges_table3, caption = "Edges Data")
# 
# # Save the final structured graph as a GraphML file
# write_graph(myNetwork3, "Final_Competency_Model.graphml", format = "graphml")


## ----scen4-build, eval=FALSE--------------------------------------------------
# # Read your previously saved nodes and edges
# # (Assuming they were saved using write.csv(nodes_table, "my_nodes.csv", row.names=FALSE))
# 
# # Rebuild the igraph object directly
# myNetwork4 <- build_from_node_edge_files(
#     NodesFile = "my_nodes.csv",
#     EdgesFile = "my_edges.csv"
# )
# 


## ----scen4-push, eval=FALSE---------------------------------------------------
# # Load the CSVs as raw data.frames
# loaded_nodes <- read.csv("my_nodes.csv", stringsAsFactors = FALSE)
# loaded_edges <- read.csv("my_edges.csv", stringsAsFactors = FALSE)
# 
# # Push the components right back into the visual canvas!
# push_to_cytoscape(
#     nodes = loaded_nodes,
#     edges = loaded_edges,
# )

