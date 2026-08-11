# =============================================================================
# Workflow_Simulation.R
# Description: Generates simulated data from a compiled Nimble configuration.
# =============================================================================

#' Simulate Data for Parameter Recovery
#'
#' Generates simulated response data and latent attributes based on a provided
#' model configuration. Can simulate from priors or fixed true parameters.
#'
#' @param config A model configuration list returned by \code{build_model_config}.
#' @param parameters Optional list of exact parameter values to use (e.g., \code{lambda}, \code{theta}, \code{beta_root}).
#'   If \code{NULL}, parameters are drawn randomly from the model's priors.
#' @param seed Optional integer to set the random seed for reproducibility.
#'
#' @return A list containing:
#' \itemize{
#'   \item \code{X}: The simulated $N \times J$ binary response matrix.
#'   \item \code{attributes}: The simulated $N \times K$ latent attribute matrix.
#'   \item \code{parameters}: A list of the parameters used to generate the data.
#' }
#' @export
simulate_data <- function(config, parameters = NULL, seed = NULL) {
    if (!is.null(seed)) set.seed(seed)
    
    source(config$code_file)
    model_code <- get(config$model_object)
    
    # Remove X from data so Nimble treats it as a node to simulate
    data_sim <- config$data
    data_sim$X <- NULL
    
    model_sim <- nimbleModel(
        code = model_code,
        constants = config$constants,
        data = data_sim,
        inits = config$inits,
        buildDerivs = FALSE
    )
    cmodel_sim <- compileNimble(model_sim)
    
    # Define the nodes we want to simulate
    params_in_model <- config$monitors
    
    if (!is.null(parameters)) {
        # Fix parameters to user-provided values
        for (pNode in names(parameters)) {
            try({
                cmodel_sim[[pNode]] <- parameters[[pNode]]
            }, silent = TRUE)
        }
        # Simulate only downstream nodes (attributes and X) given the fixed parameters
        nodesToSim <- cmodel_sim$getDependencies(names(parameters), self = FALSE, downstream = TRUE)
    } else {
        # Simulate everything (parameters, attributes, and X) from priors
        nodesToSim <- cmodel_sim$getDependencies(params_in_model, self = TRUE, downstream = TRUE)
    }
    
    cmodel_sim$simulate(nodesToSim)
    
    sim_X <- NULL
    sim_attributes <- NULL
    
    try({ sim_X <- cmodel_sim$X }, silent = TRUE)
    try({ sim_attributes <- cmodel_sim$attributenodes }, silent = TRUE)
    
    # Extract the parameters that were actually used
    used_parameters <- list()
    for (pNode in params_in_model) {
        if (pNode != "attributenodes" && pNode != "X") {
            try({
                used_parameters[[pNode]] <- cmodel_sim[[pNode]]
            }, silent = TRUE)
        }
    }
    
    # Add names to X and attributes for clarity
    task_names <- igraph::V(config$graph)[tolower(igraph::V(config$graph)$type) == "task"]$name
    attr_names <- igraph::V(config$graph)[tolower(igraph::V(config$graph)$type) == "attribute"]$name
    
    if (!is.null(sim_X)) colnames(sim_X) <- task_names
    if (!is.null(sim_attributes)) colnames(sim_attributes) <- attr_names
    
    return(list(
        X = sim_X,
        attributes = sim_attributes,
        parameters = used_parameters
    ))
}
