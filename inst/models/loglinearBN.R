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
    run = function(weights = double(1), attributes = double(1), num_attr = double(0), nrbetaroot = double(0),
                   isDINA = double(0), isDINO = double(0), isDINM = double(0)) {
        # Initialize accumulators for continuous and discrete parents
        sum_cont <- 0.0 # Sum of continuous attribute values (e.g. latent ability)
        sum_disc <- 0.0 # Sum of discrete attribute values (skills the student has)
        req_disc <- 0.0 # Total required discrete attributes for this node

        sum_total <- 0.0 # Total sum of all inputs (for DINM/DINO)
        sum_input <- 0.0 # Total possible input weights (for DINM)
        has_cont <- 0.0 # Flag indicating if there's a continuous parent

        n <- num_attr

        # Loop through each prerequisite for this node
        for (p in 1:n) {
            val <- weights[p] * attributes[p]
            sum_total <- sum_total + val
            sum_input <- sum_input + weights[p]

            # If this attribute is a prerequisite (weight != 0)
            if (weights[p] != 0) {
                # Check if this parent is a continuous root attribute vs a discrete skill
                # Root attributes (indices <= nrbetaroot) are treated as continuous/latent
                if (p <= nrbetaroot) {
                    sum_cont <- sum_cont + val
                    has_cont <- 1.0
                } else {
                    # Dependent attributes (indices > nrbetaroot) are discrete (0 or 1)
                    sum_disc <- sum_disc + val
                    req_disc <- req_disc + weights[p]
                }
            }
        }

        # DINA Logic (Mixed/Gated Non-Compensatory)
        # First, check the "Gate": does the student have all required discrete skills?
        gate <- (sum_disc == req_disc)
        val_dina <- 0.0

        if (has_cont == 1.0) {
            # Mixed or Pure Continuous Case
            if (gate == 1.0) {
                # If they have the discrete skills, the continuous ability passes through
                val_dina <- sum_cont
            } else {
                # If they lack the discrete skills, apply a massive penalty (-10)
                # so the logistic probability plummets to near zero
                val_dina <- -10.0
            }
        } else {
            # Pure Discrete Case (No continuous parents)
            # Standard DINA: 1 if all prerequisites met, 0 otherwise
            val_dina <- gate
        }

        # DINM (Compensatory)
        # Simple ratio of possessed prerequisites over total required prerequisites
        # (Works naturally with continuous abilities as well)
        val_dinm <- sum_total / max(1, sum_input)

        # DINO (Mixed/Gated Disjunctive)
        # Check the "Gate": does the student have AT LEAST ONE required discrete skill?
        # (If no discrete skills are required, the gate is open by default)
        dino_gate <- 0.0
        if (req_disc == 0.0) {
            dino_gate <- 1.0
        } else if (sum_disc > 0.0) {
            dino_gate <- 1.0
        }

        val_dino <- 0.0
        if (has_cont == 1.0) {
            # Mixed or Pure Continuous Case
            if (dino_gate == 1.0) {
                # They possess at least one prerequisite skill -> Continuous ability passes through
                val_dino <- sum_cont
            } else {
                # They lack ALL prerequisite skills -> Severe penalty
                val_dino <- -10.0
            }
        } else {
            # Pure Discrete Case
            # Standard DINO: 1 if at least one prerequisite met, 0 otherwise
            val_dino <- dino_gate
        }

        returnType(double(0))
        # Return the final kernel value based on which model is active
        # Only one of isDINA, isDINO, isDINM should be 1, others 0
        return(isDINA * val_dina + isDINO * val_dino + isDINM * val_dinm)
    }
)

loglinearBN <- nimbleCode({
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
                # Calculate Kernel using Custom Function to handle Mixed Inputs
                # Using 1:(k-1) properly ensures Nimble does not see a bidirectional DAG cycle. 
                # Because k is dynamic in the loop, Nimble handles 1:1 boundaries correctly here without the C++ bug.
                psival[i, k] <- calc_mixed_kernel(
                    weights = CDMmatrix[k, 1:(k - 1)],
                    attributes = attributenodes[i, 1:(k - 1)],
                    num_attr = k - 1,
                    nrbetaroot = isContinuousHO * nrbetaroot, # Only treat roots as continuous if HO/MIRT/IRT
                    isDINA = isDINA[k],
                    isDINO = isDINO[k],
                    isDINM = isDINM[k]
                )

                # Probability using specific theta parameters for this attribute
                # theta[k, 1] is Slope, theta[k, 2] is Intercept
                atprob[i, k] <- ilogit(theta[k, 1] * psival[i, k] - theta[k, 2])
                attributenodes[i, k] ~ dbern(atprob[i, k])
            }
        }

        # C. Task Nodes (Observed Data)
        for (j in 1:nrtasknodes) {
            # Task nodes use standard kernels
            phival[i, j] <- calc_mixed_kernel(
                weights = CDMmatrix[nrattributenodes + j, 1:CDMattnodesmax],
                attributes = attributenodes[i, 1:CDMattnodesmax],
                num_attr = nrattributenodes,
                nrbetaroot = isContinuousHO * nrbetaroot, # Dynamically handle MIRT/IRT continuous inputs to items
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
