# DCM Workflow

## Unified DCM Workflow

This vignette demonstrates the new unified architecture running a DCM
model. Note that DCM subtypes (HigherOrder, BayesNet, Traditional, MIRT,
IRT) are automatically determined.

### 1. Setup

``` r
# library(pgdcm)

# If running locally without installing:
source("R/GraphBuilder.R")
source("R/ModelConfig.R")
source("R/Workflow.R")

# Helper to find data files whether installed or running locally
get_data_path <- function(filename) {
    path <- system.file("extdata", filename, package = "pgdcm")
    if (path == "") path <- paste0("inst/extdata/", filename)
    return(path)
}
```

### 2. Build the Graph

``` r
print("Building Graph from Q-Matrix...")
graph_res <- build_from_q_matrix(
    QMatrixFile = get_data_path("Q_dummy.csv"),
    DefaultAttributeCompute = "dina", # discrete DCM
    DefaultTaskCompute = "dina"
)
```

### 3. Create Model Configuration

``` r
print("Creating DCM Model Configuration...")

DataDF <- read.csv(get_data_path("Data_dummy.csv"))

config <- build_model_config(graph_res, DataDF)
print(paste("Configured Model Type:", config$type))
```

### 4. Run Integrated Workflow

``` r
print("Starting Integrated Workflow...")

estimation_config <- list(
    niter = 500,
    nburnin = 100,
    chains = 2,
    prior_sims = 50,
    post_sims = 50
)

results <- run_pgdcm_auto(
    config = config,
    estimation_config = estimation_config,
    prefix = "Unified_DCM_Example"
)
```
