test_that("RemoveSeasonal 去除季节循环", {
  y <- rep(c(1, 2, 3), 3) + 0.1
  out <- RemoveSeasonal(y, rep(1:3, 3))

  expect_named(out, c("mu", "anomaly"))
  expect_equal(out$mu, rep(c(1.1, 2.1, 3.1), 1))
  expect_equal(out$anomaly, rep(0, 9), tolerance = 1e-12)
  expect_length(out$anomaly, length(y))
})

test_that("RemoveSeasonal 按 MMDD 升序排列 mu", {
  y <- c(10, 20, 10, 20)
  t_mmdd <- c(200, 100, 200, 100)
  out <- RemoveSeasonal(y, t_mmdd)

  expect_equal(names(out$mu), NULL)
  # 顺序按 t_mmdd 升序：100 在前，200 在后
  expect_equal(out$mu, c(20, 10))
})
