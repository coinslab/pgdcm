library(nimble)
code <- nimbleCode({
  for(i in 1:10) {
    p[i] ~ dunif(0,1)
    X[i] ~ dbern(p[i])
  }
})
X_data <- rep(1, 10)
model <- nimbleModel(code, data = list(X = X_data))
conf <- configureMCMC(model)
res <- runCrossValidate(conf, k = 2, foldFunction = "random", lossFunction = "MSE", MCMCcontrol = list(niter = 50, nburnin=10))
print("FINISHED MSE!")
