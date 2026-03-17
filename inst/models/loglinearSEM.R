loglinearSEM <- nimbleCode({
    # --- Priors ---

    # 1. Intercepts (alpha) for all nodes
    for (k in 1:nrnodes) {
        alpha[k] ~ dnorm(mean = alpha_prior_mean[k], sd = alpha_prior_std[k])
    }

    # 2. Weights (beta) for all potential edges
    for (k in 1:nrnodes) {
        for (j in 1:nrnodes) {
            beta[k, j] ~ dnorm(mean = beta_prior_mean[k, j], sd = beta_prior_std[k, j])
        }
    }

    # --- Likelihood ---

    for (i in 1:nrparticipants) {
        # ---------------------------------------------------------
        # PART A: Attribute Nodes (Latent)
        # ---------------------------------------------------------

        # k = 1 Case
        linear_pred_att[i, 1] <- alpha[1]
        if (SEMdoZscoreAttribute) {
            attributenodes[i, 1] ~ dnorm(mean = linear_pred_att[i, 1], sd = 1)
        }
        if (SEMdoPercentileAttribute) {
            attributenodes[i, 1] ~ dbern(ilogit(1.702 * linear_pred_att[i, 1]))
        }
        if (SEMdoBinaryAttribute) {
            attributenodes[i, 1] ~ dbern(ilogit(linear_pred_att[i, 1]))
        }

        # k = 2...attdim Case
        if (attdim >= 2) {
            for (k in 2:attdim) {
                # Depends on 1:(k-1)
                linear_pred_att[i, k] <- alpha[k] + sum(beta[k, 1:(k - 1)] * CDMmatrix[k, 1:(k - 1)] * attributenodes[i, 1:(k - 1)])

                if (SEMdoZscoreAttribute) {
                    attributenodes[i, k] ~ dnorm(mean = linear_pred_att[i, k], sd = 1)
                }
                if (SEMdoPercentileAttribute) {
                    attributenodes[i, k] ~ dbern(ilogit(1.702 * linear_pred_att[i, k]))
                }
                if (SEMdoBinaryAttribute) {
                    attributenodes[i, k] ~ dbern(ilogit(linear_pred_att[i, k]))
                }
            }
        }

        # ---------------------------------------------------------
        # PART B: Task Nodes (Observed X)
        # ---------------------------------------------------------

        # 1. Calc Input from Attributes (All tasks)
        for (j in 1:nrtasknodes) {
            input_from_atts[i, j] <- sum(beta[attdim + j, 1:attdim] * CDMmatrix[attdim + j, 1:attdim] * attributenodes[i, 1:attdim])
        }

        # 2. Calc Input from Tasks

        # j = 1 Case
        input_from_tasks[i, 1] <- 0

        # j = 2...nrtasknodes Case
        if (nrtasknodes >= 2) {
            for (j in 2:nrtasknodes) {
                # Depends on tasks 1...(j-1) which are cols 1...(j-1) of X
                # and nodes attdim+1 ... attdim+j-1
                input_from_tasks[i, j] <- sum(beta[attdim + j, (attdim + 1):(attdim + j - 1)] * CDMmatrix[attdim + j, (attdim + 1):(attdim + j - 1)] * X[i, 1:(j - 1)])
            }
        }

        # 3. Total Prediction and Distribution
        for (j in 1:nrtasknodes) {
            linear_pred_task[i, j] <- alpha[attdim + j] + input_from_atts[i, j] + input_from_tasks[i, j]

            if (SEMdoZscoreTask) {
                X[i, j] ~ dnorm(mean = linear_pred_task[i, j], sd = 1)
            }
            if (SEMdoPercentileTask) {
                X[i, j] ~ dbern(ilogit(1.702 * linear_pred_task[i, j]))
            }
            if (SEMdoBinaryTask) {
                X[i, j] ~ dbern(ilogit(linear_pred_task[i, j]))
            }
        }
    }
})
