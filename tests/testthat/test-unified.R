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
