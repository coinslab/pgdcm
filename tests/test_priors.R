# Test Script for Prior Implementation

pkgload::load_all(".")
library(igraph)

# Create a mock graph
nodes <- data.frame(
    name = c("Att1", "Att2", "Task1", "Task2", "Task3"),
    type = c("Attribute", "Attribute", "Task", "Task", "Task"),
    compute = rep("binary", 5)
)

edges_df <- data.frame(
    from = c("Att1", "Att1", "Att2", "Att2"),
    to = c("Att2", "Task1", "Task2", "Task3"),
    weights = c(1, 1, 1, 1),
    weight_type = rep("required", 4)
)

# Need to save the files first to use the function
tmp_nodes <- file.path(tempdir(), "test_nodes.csv")
tmp_edges <- file.path(tempdir(), "test_edges.csv")

write.csv(nodes, tmp_nodes, row.names=FALSE)
write.csv(edges_df, tmp_edges, row.names=FALSE)
g <- build_from_node_edge_files(tmp_nodes, tmp_edges)

# Create mock data
set.seed(42)
df <- data.frame(
    id = 1:5,
    Task1 = rbinom(5, 1, 0.5),
    Task2 = rbinom(5, 1, 0.5),
    Task3 = rbinom(5, 1, 0.5)
)

print("--- Testing DCM with NULL priors ---")
cfg_null <- build_model_config(g, df)
print(cfg_null$constants$beta_prior_mean)
print(cfg_null$constants$theta_prior_mean)
print(cfg_null$constants$lambda_prior_mean)

print("--- Testing DCM with common priors ---")
common_priors <- list(beta = c(0, 5), theta = c(1, 3), lambda = c(2, 4))
cfg_common <- build_model_config(g, df, priors = common_priors)
print(cfg_common$constants$beta_prior_mean)
print(cfg_common$constants$theta_prior_std)
print(cfg_common$constants$lambda_prior_std)

print("--- Testing DCM with individual array priors ---")
array_priors <- list(
    beta_mean = c(3),
    beta_std = c(1),
    theta_mean = matrix(c(0,0, 0,0), nrow=2, byrow=TRUE),
    theta_std = matrix(c(1,1, 1,1), nrow=2, byrow=TRUE),
    lambda_mean = matrix(c(1,1, 2,2, 3,3), nrow=3, byrow=TRUE),
    lambda_std = matrix(c(0.5,0.5, 0.5,0.5, 0.5,0.5), nrow=3, byrow=TRUE)
)
cfg_array <- build_model_config(g, df, priors = array_priors)
print(cfg_array$constants$beta_prior_mean)
print(cfg_array$constants$theta_prior_std)
print(cfg_array$constants$lambda_prior_mean)

print("--- Testing execution with manual priors ---")
# Very short run just to test execution
res <- run_pgdcm_auto(cfg_array, estimation_config = list(niter=20, nburnin=5, chains=2), prefix = file.path(tempdir(), "test_run"))
print(res$WAIC)
