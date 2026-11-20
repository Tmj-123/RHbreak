#' Remove the seasonal cycle by calendar day
#'
#' 对每个日历年日（MMDD）计算多年均值 `mu`，再从原序列中扣除，
#' 得到去季节序列 `anomaly`。
#'
#' @param y 观测序列。
#' @param t_mmdd 与 `y` 等长的月日标签（MMDD）。
#'
#' @return 列表，含按 MMDD 升序排列的季节均值 `mu` 与去季节序列 `anomaly`。
#' @export
#' @examples
#' y <- rep(1:4, 3) + rnorm(12)
#' RemoveSeasonal(y, rep(1:4, 3))
RemoveSeasonal <- function(y, t_mmdd) {
  inds <- sort(unique(t_mmdd)) # 月尺度最多 12 个，日尺度最多 366 个
  mu <- numeric(length(inds))
  anomaly <- numeric(length(y))
  for (i in seq_along(inds)) {
    ind <- which(t_mmdd == inds[i])
    mu[i] <- mean(y[ind], na.rm = TRUE)
    anomaly[ind] <- y[ind] - mu[i]
  }
  list(mu = mu, anomaly = anomaly)
}

#' Multiple breakpoints piecewise regression (same slope, different interception)
#'
#' @param Y 响应值（观测序列）。
#' @param X 自变量（通常为时间序列）。
#' @param Ips 各段末尾的位置，末位为序列长度。
#' @param ... 传给 `lm_solve()`。
#'
#' @return 列表，含 `coef`（系数）、`fitted`（拟合值）与
#' `resi`（残差）、`SSE`（残差平方和）。
#' @export
#' @examples
#' LS_MultiBreaks(1:10 + rnorm(10), 1:10, c(4, 10))
LS_MultiBreaks <- function(Y, X, Ips, ...) {
  n_breaks <- length(Ips) - 1
  design <- cbind(1, X - mean(X))
  for (i in seq_len(n_breaks)) {
    segment <- numeric(length(Y))
    segment[(Ips[i] + 1):Ips[i + 1]] <- 1
    design <- cbind(design, segment)
  }
  lm_solve(design, Y, ...)
}

#' Single-breakpoint piecewise regression (same slope, different interception)
#'
#' @param Y 响应值（观测序列）。
#' @param X 自变量（通常为时间序列）。
#' @param Ic 变点位置，`[1, Ic]` 与 `[Ic + 1, n]` 为两段；`NA` 表示无变点。
#' @param ... 传给 `lm_solve()`。
#'
#' @return 列表，含 `coef`、`fitted`、`resi` 与 `SSE`。
#' @export
#' @examples
#' LS_OneBreak(c(1:10, 11:20), 1:20, 10)
LS_OneBreak <- function(Y, X, Ic, ...) {
  n <- length(Y)
  design <- cbind(1, X)
  if (!is.na(Ic)) {
    design <- cbind(design, c(rep(0, Ic), rep(1, n - Ic)))
  }
  lm_solve(design, Y, ...)
}

#' Least squares solver based on `.lm.fit()`
#'
#' @param design 设计矩阵。
#' @param response 响应值。
#' @param only.SSE 若为 `TRUE`，仅返回残差平方和。
#' @param ... 预留参数。
#'
#' @return 列表，含 `coef`、`fitted`、`resi`、`SSE`；`only.SSE = TRUE`
#' 时仅含 `SSE`。
#' @keywords internal
#' @noRd
lm_solve <- function(design, response, only.SSE = FALSE, ...) {
  l <- .lm.fit(design, as.matrix(response))
  fitted <- design %*% l$coefficients
  SSE <- sum(l$residuals^2)
  if (only.SSE) {
    return(list(SSE = SSE))
  }
  list(
    coef = l$coefficients,
    fitted = as.vector(fitted),
    resi = l$residuals,
    SSE = SSE
  )
}
