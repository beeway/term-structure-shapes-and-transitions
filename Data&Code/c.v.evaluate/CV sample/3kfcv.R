
set.seed(seed)

n_train <- 100
xy <- gen_data(n_train, beta, sigma_eps)
x <- xy$x
y <- xy$y

fitted_models <- apply(t(df), 2, function(degf) lm(y ~ ns(x, df = degf)))
mse <- sapply(fitted_models, function(obj) deviance(obj)/nobs(obj))

n_test <- 10000
xy_test <- gen_data(n_test, beta, sigma_eps)
pred <- mapply(function(obj, degf) predict(obj, data.frame(x = xy_test$x)), 
               fitted_models, df)
te <- sapply(as.list(data.frame(pred)), function(y_hat) mean((xy_test$y - y_hat)^2))

n_folds <- 10
folds_i <- sample(rep(1:n_folds, length.out = n_train))
cv_tmp <- matrix(NA, nrow = n_folds, ncol = length(df))
for (k in 1:n_folds) {
  test_i <- which(folds_i == k)
  train_xy <- xy[-test_i, ]
  test_xy <- xy[test_i, ]
  x <- train_xy$x
  y <- train_xy$y
  fitted_models <- apply(t(df), 2, function(degf) lm(y ~ ns(x, df = degf)))
  x <- test_xy$x
  y <- test_xy$y
  pred <- mapply(function(obj, degf) predict(obj, data.frame(ns(x, df = degf))), 
                 fitted_models, df)
  cv_tmp[k, ] <- sapply(as.list(data.frame(pred)), function(y_hat) mean((y - 
                                                                           y_hat)^2))
}
cv <- colMeans(cv_tmp)

#install.packages('Hmisc')
require(Hmisc)

plot(df, mse, type = "l", lwd = 2, col = gray(0.4), ylab = "Prediction error", 
     xlab = "Flexibilty (spline's degrees of freedom [log scaled])", main = paste0(n_folds, 
                                                                                   "-fold Cross-Validation"), ylim = c(0.1, 0.8), log = "x")
lines(df, te, lwd = 2, col = "darkred", lty = 2)
cv_sd <- apply(cv_tmp, 2, sd)/sqrt(n_folds)
errbar(df, cv, cv + cv_sd, cv - cv_sd, add = TRUE, col = "steelblue2", pch = 19, 
       lwd = 0.5)
lines(df, cv, lwd = 2, col = "steelblue2")
points(df, cv, col = "steelblue2", pch = 19)
legend(x = "topright", legend = c("Training error", "Test error", "Cross-validation error"), 
       lty = c(1, 2, 1), lwd = rep(2, 3), col = c(gray(0.4), "darkred", "steelblue2"), 
       text.width = 0.4, cex = 0.85)


### loocv

require(splines)

loocv_tmp <- matrix(NA, nrow = n_train, ncol = length(df))
for (k in 1:n_train) {
  train_xy <- xy[-k, ]
  test_xy <- xy[k, ]
  x <- train_xy$x
  y <- train_xy$y
  fitted_models <- apply(t(df), 2, function(degf) lm(y ~ ns(x, df = degf)))
  pred <- mapply(function(obj, degf) predict(obj, data.frame(x = test_xy$x)),
                 fitted_models, df)
  loocv_tmp[k, ] <- (test_xy$y - pred)^2
}
loocv <- colMeans(loocv_tmp)

plot(df, mse, type = "l", lwd = 2, col = gray(.4), ylab = "Prediction error",
     xlab = "Flexibilty (spline's degrees of freedom [log scaled])",
     main = "Leave-One-Out Cross-Validation", ylim = c(.1, .8), log = "x")
lines(df, cv, lwd = 2, col = "steelblue2", lty = 2)
lines(df, loocv, lwd = 2, col = "darkorange")
legend(x = "topright", legend = c("Training error", "10-fold CV error", "LOOCV error"),
       lty = c(1, 2, 1), lwd = rep(2, 3), col = c(gray(.4), "steelblue2", "darkorange"),
       text.width = .3, cex = .85)

