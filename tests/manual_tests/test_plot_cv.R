library(nimble)

# simple model
code <- nimbleCode({
  for(i in 1:10) {
    p[i] ~ dunif(0,1)
    X[i] ~ dbern(p[i])
  }
})
X_data <- rep(1, 10)
model <- nimbleModel(code, data = list(X = X_data))
conf <- configureMCMC(model, monitors = c("X"))
res <- runCrossValidate(conf, k = 2, foldFunction = "random", returnSamples = TRUE, MCMCcontrol = list(niter = 50, nburnin=10))

for(i in 1:2) {
  samps <- as.matrix(res$samples[[i]])
  # find columns of X that vary
  X_cols <- grep("^X\\[", colnames(samps), value=TRUE)
  vars <- apply(samps[,X_cols], 2, var)
  held_out <- names(vars)[vars > 0]
  print(paste("Fold", i, "held out:"))
  print(held_out)
}
