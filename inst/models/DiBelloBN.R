#' Calculate Mixed Condensation Rule for Diagnostics Classification Models (DCM)
#'
#' This nimbleFunction calculates the latent predictor (condensation rule) for a
#' node in a Bayesian network, accommodating a mix of continuous and discrete
#' parent nodes. It implements logic for Gated DINA (Mixed Non-Compensatory),
#' DINM (Compensatory), and DINO (Disjunctive) models.
#'
#' @param weights A vector of weights (Q-matrix entries or adjacency matrix weights)
#'        indicating which parent nodes are prerequisites.
#' @param attributes A vector of the current values of the parent nodes.
#' @param nrbetaroot The number of root nodes (continuous latent abilities).
#'        Indices <= `nrbetaroot` are treated as continuous covariates.
#'        Indices > `nrbetaroot` are treated as discrete skills (0 or 1).
#' @param isDINA Indicator flag (1 or 0) for the DINA (Non-Compensatory) rule.
#' @param isDINO Indicator flag (1 or 0) for the DINO (Disjunctive) rule.
#' @param isDINM Indicator flag (1 or 0) for the DINM (Compensatory) rule.
#'
#' @details
#' - **DINA (Gated)**: First checks if all required *discrete* skills are present
#'   (the "Gate"). If they are, it passes through the sum of the *continuous*
#'   abilities. If the gate is closed (missing discrete skills), it applies a
#'   severe penalty (-10.0), effectively dropping the probability of success to 0.
#' - **DINM**: Calculates the ratio of accumulated parent values to the total
#'   required weight.
#' - **DINO**: Returns 1 if any prerequisite has a value > 0, otherwise 0.
#'
#' @return A deterministic double representing the condensed input value to be
#'         passed into the logistic regression equation `ilogit(slope * value - intercept)`.
# Define Helper Function for Mixed Logic
calc_mixed_kernel <- nimbleFunction(
    run = function(sum_cont = double(0), sum_disc = double(0), req_disc = double(0), sum_input = double(0), has_cont = double(0),
                   isDINA = double(0), isDINO = double(0), isDINM = double(0)) {
        
        sum_total <- sum_cont + sum_disc

        # DINA Logic (Mixed/Gated Non-Compensatory)
        gate <- (sum_disc == req_disc)
        val_dina <- 0.0

        if (has_cont == 1.0) {
            if (gate == 1.0) {
                val_dina <- sum_cont
            } else {
                val_dina <- -10.0
            }
        } else {
            val_dina <- gate
        }

        # DINM (Compensatory)
        val_dinm <- sum_total / max(1.0, sum_input)

        # DINO (Mixed/Gated Disjunctive)
        dino_gate <- 0.0
        if (req_disc == 0.0) {
            dino_gate <- 1.0
        } else if (sum_disc > 0.0) {
            dino_gate <- 1.0
        }

        val_dino <- 0.0
        if (has_cont == 1.0) {
            if (dino_gate == 1.0) {
                val_dino <- sum_cont
            } else {
                val_dino <- -10.0
            }
        } else {
            val_dino <- dino_gate
        }

        returnType(double(0))
        return(isDINA * val_dina + isDINO * val_dino + isDINM * val_dinm)
    }
)

DiBelloBN <- nimbleCode({
    # --- Priors ---

    # 1. Priors for Root Attributes (Intercepts only / OR Latent Ability)
    if (isContinuousHO == 0) {
        # Standard Binary Root Attribute
        for (m in 1:nrbetaroot) {
            beta_root[m] ~ dnorm(mean = beta_prior_mean[m, 1], sd = beta_prior_std[m, 1])
        }
    }
    # If isContinuousHO == 1, the root attribute is the Latent Variable itself,
    # which is standard normal for each participant (see Likelihood section).

    # 2. Priors for Attribute Transitions (Slopes and Intercepts)
    # Only for dependent attributes (from nrbetaroot + 1 to nrattributenodes)
    if (nrattributenodes > nrbetaroot) {
        for (k in (nrbetaroot + 1):nrattributenodes) {
            theta[k, 1] ~ T(dnorm(mean = theta_prior_mean[k, 1], sd = theta_prior_std[k, 1]), 0, Inf) # Slope
            theta[k, 2] ~ dnorm(mean = theta_prior_mean[k, 2], sd = theta_prior_std[k, 2]) # Intercept
        }
    }

    # 3. Priors for Items (Slopes and Intercepts)
    for (j in 1:nrtasknodes) {
        lambda[j, 1] ~ T(dnorm(mean = lambda_prior_mean[j, 1], sd = lambda_prior_std[j, 1]), 0, Inf) # Slope
        lambda[j, 2] ~ dnorm(mean = lambda_prior_mean[j, 2], sd = lambda_prior_std[j, 2]) # Intercept
    }

    # --- Likelihood ---

    for (i in 1:nrparticipants) {
        # A. Root Attributes (Zero Attribute Nodes)
        for (m in 1:nrbetaroot) {
            if (isContinuousHO == 1) {
                # Higher-Order Continuous Latent Variable (General Ability)
                attributenodes[i, m] ~ dnorm(0, 1)
            } else {
                # Standard Parameterization: P = ilogit(-Intercept)
                atprob[i, m] <- ilogit(-beta_root[m])
                attributenodes[i, m] ~ dbern(atprob[i, m])
            }
        }

        # B. Dependent Attributes (Hierarchy)
        if (nrattributenodes > nrbetaroot) {
            for (k in (nrbetaroot + 1):nrattributenodes) {
                sum_cont_node[i, k] <- sum(is_cont_parent[k, 1:(k - 1)] * attributenodes[i, 1:(k - 1)])
                sum_disc_node[i, k] <- sum(is_disc_parent[k, 1:(k - 1)] * attributenodes[i, 1:(k - 1)])

                psival[i, k] <- calc_mixed_kernel(
                    sum_cont = sum_cont_node[i, k],
                    sum_disc = sum_disc_node[i, k],
                    req_disc = req_disc[k],
                    sum_input = sum_input[k],
                    has_cont = has_cont[k],
                    isDINA = isDINA[k],
                    isDINO = isDINO[k],
                    isDINM = isDINM[k]
                )

                # Probability using specific theta parameters for this attribute
                atprob[i, k] <- ilogit(theta[k, 1] * psival[i, k] - theta[k, 2])
                attributenodes[i, k] ~ dbern(atprob[i, k])
            }
        }

        # C. Task Nodes (Observed Data)
        for (j in 1:nrtasknodes) {
            # Task nodes use standard kernels
            sum_cont_task[i, j] <- sum(is_cont_parent[nrattributenodes + j, 1:CDMattnodesmax] * attributenodes[i, 1:CDMattnodesmax])
            sum_disc_task[i, j] <- sum(is_disc_parent[nrattributenodes + j, 1:CDMattnodesmax] * attributenodes[i, 1:CDMattnodesmax])

            phival[i, j] <- calc_mixed_kernel(
                sum_cont = sum_cont_task[i, j],
                sum_disc = sum_disc_task[i, j],
                req_disc = req_disc[nrattributenodes + j],
                sum_input = sum_input[nrattributenodes + j],
                has_cont = has_cont[nrattributenodes + j],
                isDINA = isDINA[nrattributenodes + j],
                isDINO = isDINO[nrattributenodes + j],
                isDINM = isDINM[nrattributenodes + j]
            )

            # Probability using specific lambda parameters for this item
            taskprob[i, j] <- ilogit(lambda[j, 1] * phival[i, j] - lambda[j, 2])
            X[i, j] ~ dbern(taskprob[i, j])
        }
    }
})
