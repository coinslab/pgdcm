# SEM Workflow

## Unified SEM Workflow

This vignette demonstrates the new unified architecture running an SEM
model.

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
print("Building Graph from Files...")
graph_res <- build_from_node_edge_files(
    NodesFile = get_data_path("Znodes.csv"),
    EdgesFile = get_data_path("Zedges.csv")
)
```

### 3. Create Model Configuration

``` r
print("Creating SEM Model Configuration...")

library(readxl)
DataDF <- read_excel(get_data_path("Zdata.xlsx"))

config <- build_model_config(graph_res, DataDF)
print(paste("Configured Model Type:", config$type))
```

### 4. Run Integrated Workflow

``` r
print("Starting Integrated Workflow...")

estimation_config <- list(
    niter = 2000,
    nburnin = 500,
    chains = 2,
    prior_sims = 50,
    post_sims = 50
)

results <- run_pgdcm_auto(
    config = config,
    estimation_config = estimation_config,
    prefix = "Unified_SEM_Example"
)
```
