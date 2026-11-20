# RHbreak

<!-- badges: start -->
[![R-CMD-check](https://github.com/Tangmj/RHbreak/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/Tangmj/RHbreak/actions/workflows/R-CMD-check.yaml)
<!-- badges: end -->

基于 `rpkgs/rpkg.template` 搭建的最小 R 包，收录 `rpkgs/RHtests` 中
`R/Component.R` 的三个工具函数：

- `RemoveSeasonal()`：按日历日（MMDD）去除季节循环，返回季节均值与距平；
- `LS_OneBreak()`：单变点分段线性回归（同斜率、不同截距）；
- `LS_MultiBreaks()`：多变点分段线性回归（同斜率、不同截距）。

## Installation

``` r
remotes::install_github("Tangmj/RHbreak")
```

## Example

``` r
library(RHbreak)

x <- 1:40
y <- 2 + 0.5 * x + c(rep(0, 20), rep(5, 20))
fit <- LS_OneBreak(y, x, Ic = 20)
fit$coef
fit$SSE
```
