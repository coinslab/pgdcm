devtools::load_all()

set.seed(123)
N <- 100
K <- 2
J <- 4
Q <- matrix(0, J, K)
Q[1,1] <- 1; Q[2,2] <- 1; Q[3,1] <- 1; Q[3,2] <- 1; Q[4,1] <- 1

g <- QMatrix2iGraph(Q, compute = "dina")
X <- matrix(rbinom(N * J, 1, 0.5), N, J)
df <- data.frame(ID = 1:N, X)
colnames(df)[2:(J+1)] <- paste0("Task", 1:J)
igraph::V(g)$name[tolower(igraph::V(g)$type) == "task"] <- paste0("Task", 1:J)

config <- build_model_config(g, df)
X_mat <- as.matrix(df[,-1])
colnames(X_mat) <- paste0("Task", 1:J)

res <- run_predictive_check(config, X_mat, n_sim = 2, prefix = NULL)

print("Observed Col Means:")
print(res$obsColMeans)
print("Simulated Col Means:")
print(res$simColMeans)
print(paste("Are they identical?", identical(res$obsColMeans, colMeans(res$simColMeans))))
