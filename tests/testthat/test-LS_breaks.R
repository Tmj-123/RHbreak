test_that("LS_OneBreak 恢复真实的变点与共同斜率", {
  X <- 1:40
  Y <- 2 + 0.5 * X + c(rep(0, 20), rep(5, 20))
  fit <- LS_OneBreak(Y, X, Ic = 20)

  expect_named(fit, c("coef", "fitted", "resi", "SSE"))
  # 斜率在两段中相同，且等于 0.5
  expect_equal(unname(fit$coef[2]), 0.5)
  # 第二段的截距高出 5
  expect_equal(unname(fit$coef[3]), 5)
  expect_equal(fit$fitted, as.vector(Y), tolerance = 1e-8)
  expect_equal(fit$SSE, 0, tolerance = 1e-16)
  expect_length(fit$resi, length(Y))
})

test_that("LS_OneBreak 在 Ic = NA 时退化为普通线性回归", {
  X <- 1:10
  Y <- 3 + 2 * X
  fit <- LS_OneBreak(Y, X, Ic = NA)

  expect_length(fit$coef, 2)
  expect_equal(unname(fit$coef), c(3, 2), tolerance = 1e-8)
})

test_that("LS_MultiBreaks 处理多个变点", {
  X <- 1:60
  shift <- c(rep(0, 20), rep(4, 20), rep(-3, 20))
  Y <- 1 + 0.2 * X + shift
  fit <- LS_MultiBreaks(Y, X, Ips = c(20, 40, 60))

  # 1 个公共斜率 + 1 个平均截距 + 2 个分段偏移
  expect_length(fit$coef, 4)
  expect_equal(unname(fit$coef[2]), 0.2, tolerance = 1e-8)
  expect_equal(unname(fit$coef[3:4]), c(4, -3), tolerance = 1e-8)
  expect_equal(fit$fitted, as.vector(Y), tolerance = 1e-8)
})

test_that("only.SSE 只返回残差平方和", {
  X <- 1:10
  Y <- 1 + X + rnorm(10)
  expect_named(LS_OneBreak(Y, X, 5, only.SSE = TRUE), "SSE")
})
