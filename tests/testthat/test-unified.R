# =============================================================================
# tests/testthat/test-unified.R
# =============================================================================

test_that("SEM Model Detection", {
    nodes <- data.frame(
        id = c("A1", "A2", "T1", "T2"),
        type = c("Attribute", "Attribute", "Task", "Task"),
        compute = c("zscore", "zscore", "zscore", "zscore"),
        stringsAsFactors = FALSE
    )
    edges <- data.frame(
        source = c("A1", "A2", "A1", "A2"),
        target = c("T1", "T2", "A2", "T1"),
        color = "black", stringsAsFactors = FALSE
    )
    data_df <- data.frame(id = 1:5, T1 = rnorm(5), T2 = rnorm(5))

    g <- graph_from_data_frame(edges, directed = TRUE, vertices = nodes)
    g <- enforce_topo_sort(g)

    config <- build_model_config(g, data_df)

    expect_equal(config$type, "SEM")
    expect_equal(config$constants$SEMdoZscoreAttribute, 1)
})

test_that("Traditional DCM Detection", {
    nodes <- data.frame(
        id = c("A1", "A2", "T1", "T2"),
        type = c("Attribute", "Attribute", "Task", "Task"),
        compute = c("dina", "dina", "dina", "dina"),
        stringsAsFactors = FALSE
    )
    edges <- data.frame(
        source = c("A1", "A2"),
        target = c("T1", "T2"),
        color = "black", stringsAsFactors = FALSE
    )
    data_df <- data.frame(id = 1:5, T1 = rbinom(5, 1, 0.5), T2 = rbinom(5, 1, 0.5))

    g <- graph_from_data_frame(edges, directed = TRUE, vertices = nodes)
    g <- enforce_topo_sort(g)
    config <- build_model_config(g, data_df)

    expect_equal(config$type, "DCM")
    expect_equal(config$constants$isContinuousHO, 0)
    expect_equal(config$constants$nrbetaroot, 2)
})

test_that("BayesNet DCM Detection", {
    nodes <- data.frame(
        id = c("A1", "A2", "T1"),
        type = c("Attribute", "Attribute", "Task"),
        compute = c("dina", "dina", "dina"),
        stringsAsFactors = FALSE
    )
    edges <- data.frame(
        source = c("A1", "A1", "A2"),
        target = c("A2", "T1", "T1"),
        color = "black", stringsAsFactors = FALSE
    )
    data_df <- data.frame(id = 1:5, T1 = rbinom(5, 1, 0.5))

    g <- graph_from_data_frame(edges, directed = TRUE, vertices = nodes)
    g <- enforce_topo_sort(g)
    config <- build_model_config(g, data_df)

    expect_equal(config$type, "DCM")
    expect_equal(config$constants$isContinuousHO, 0)
    expect_equal(config$constants$nrbetaroot, 1)
})

test_that("Higher-Order DCM Detection", {
    nodes <- data.frame(
        id = c("Theta", "A1", "A2", "T1"),
        type = c("Attribute", "Attribute", "Attribute", "Task"),
        compute = c("zscore", "dina", "dina", "dina"),
        stringsAsFactors = FALSE
    )
    edges <- data.frame(
        source = c("Theta", "Theta", "A1", "A2"),
        target = c("A1", "A2", "T1", "T1"),
        color = "black", stringsAsFactors = FALSE
    )
    data_df <- data.frame(id = 1:5, T1 = rbinom(5, 1, 0.5))

    g <- graph_from_data_frame(edges, directed = TRUE, vertices = nodes)
    g <- enforce_topo_sort(g)
    config <- build_model_config(g, data_df)

    expect_equal(config$type, "DCM")
    expect_equal(config$constants$isContinuousHO, 1)
    expect_equal(config$constants$nrbetaroot, 1)
})

test_that("MIRT Detection", {
    nodes <- data.frame(
        id = c("Theta1", "Theta2", "T1", "T2"),
        type = c("Attribute", "Attribute", "Task", "Task"),
        compute = c("zscore", "zscore", "dina", "dina"),
        stringsAsFactors = FALSE
    )
    edges <- data.frame(
        source = c("Theta1", "Theta2"),
        target = c("T1", "T2"),
        color = "black", stringsAsFactors = FALSE
    )
    data_df <- data.frame(id = 1:5, T1 = rbinom(5, 1, 0.5), T2 = rbinom(5, 1, 0.5))

    g <- graph_from_data_frame(edges, directed = TRUE, vertices = nodes)
    g <- enforce_topo_sort(g)
    config <- build_model_config(g, data_df)

    expect_equal(config$type, "DCM")
    expect_equal(config$constants$isContinuousHO, 1)
    expect_equal(config$constants$nrbetaroot, 2)
})

test_that("IRT Detection", {
    nodes <- data.frame(
        id = c("Theta", "T1", "T2"),
        type = c("Attribute", "Task", "Task"),
        compute = c("zscore", "dina", "dina"),
        stringsAsFactors = FALSE
    )
    edges <- data.frame(
        source = c("Theta", "Theta"),
        target = c("T1", "T2"),
        color = "black", stringsAsFactors = FALSE
    )
    data_df <- data.frame(id = 1:5, T1 = rbinom(5, 1, 0.5), T2 = rbinom(5, 1, 0.5))

    g <- graph_from_data_frame(edges, directed = TRUE, vertices = nodes)
    g <- enforce_topo_sort(g)
    config <- build_model_config(g, data_df)

    expect_equal(config$type, "DCM")
    expect_equal(config$constants$isContinuousHO, 1)
    expect_equal(config$constants$nrbetaroot, 1)
})

test_that("Graph Construction and IRT graph setup", {
    tasks <- c("T1", "T2", "T3")
    g <- build_irt_graph(tasks, ability_name = "Theta")
    expect_s3_class(g, "igraph")
    expect_equal(length(V(g)), 4)
    expect_equal(length(E(g)), 3)
})

test_that("generate_ppc_plots handles NULL filename gracefully", {
    simMeans <- 0.5
    simRowMeans <- t(matrix(0.5, 2, 2))
    simColMeans <- t(matrix(0.5, 2, 2))
    avgSimM2 <- matrix(0.2, 2, 2)
    obsColMeans <- c(0.4, 0.6)
    obsRowMeans <- c(0.4, 0.6)
    obsMean <- 0.5
    M2_obs <- t(matrix(0.2, 2, 2))

    # Check that plotting to NULL doesn't crash (rendering inline)
    # Wrap in pdf device so headless tests don't fail looking for X11 / graphics dev
    tmp <- tempfile(fileext = ".pdf")
    pdf(tmp)
    expect_silent(generate_ppc_plots(NULL, "Test", simMeans, simRowMeans, simColMeans, avgSimM2, obsColMeans, obsRowMeans, obsMean, M2_obs))
    dev.off()
})

test_that("check_mcmc_convergence handles typical mcmc lists", {
    m1 <- matrix(rnorm(100), 50, 2)
    colnames(m1) <- c("var1", "var2")
    m2 <- matrix(rnorm(100), 50, 2)
    colnames(m2) <- c("var1", "var2")

    mc_list <- coda::mcmc.list(coda::mcmc(m1), coda::mcmc(m2))
    conv <- check_mcmc_convergence(mc_list, blocksize = 10, burninperiod = 5)
    expect_type(conv$converged, "logical")
})

test_that("MCMC Workflow executes without error on small data", {
    skip_on_cran()
    nodes <- data.frame(
        id = c("Theta", "T1", "T2"),
        type = c("Attribute", "Task", "Task"),
        compute = c("zscore", "dina", "dina"),
        stringsAsFactors = FALSE
    )
    edges <- data.frame(
        source = c("Theta", "Theta"),
        target = c("T1", "T2"),
        color = "black", stringsAsFactors = FALSE
    )
    # Extremely small data
    data_df <- data.frame(id = 1:5, T1 = rbinom(5, 1, 0.5), T2 = rbinom(5, 1, 0.5))
    g <- graph_from_data_frame(edges, directed = TRUE, vertices = nodes)
    g <- enforce_topo_sort(g)

    config <- build_model_config(g, data_df)
    est_config <- list(niter = 20, nburnin = 5, chains = 1, prior_sims = NULL, post_sims = NULL)

    res <- run_pgdcm_auto(config, estimation_config = est_config, prefix = "test_run")

    expect_type(res, "list")
    expect_true(!is.null(res$mapped_parameters))

    unlink("test_run_item_parameters.csv")
    unlink("test_run_mapped_parameters.csv")
    unlink("test_run_skill_profiles.csv")
})
