#import "@local/modern-cug-report:0.1.3": *
#show: doc => template(doc, footer: "水文气象学", header: "")

#let pkgs = (title: "R 包开发实践：从模板到 GitHub 自动化测试",)

= 实践目标

以 `rpkgs/rpkg.template` 为骨架，将 `rpkgs/RHtests` 中 `R/Component.R`
的函数移植为独立 R 包 `RHbreak`，补齐 roxygen2 文档与 testthat 单元测试，
推送至 GitHub 由 R-CMD-check 自动验证。

= 操作步骤

== 克隆模板

```bash
git clone --depth 1 https://github.com/rpkgs/rpkg.template.git RHbreak
cd RHbreak
```

克隆后目录已自带 `DESCRIPTION`、`NAMESPACE`、`.github/workflows/R-CMD-check.yaml`、
`tests/testthat.R`，因此只需替换内容而非从零搭建。

== 移植函数

从 `https://github.com/rpkgs/RHtests/blob/master/R/Component.R` 取得三个函数：

- `RemoveSeasonal(y, t_mmdd)`：按日历日（MMDD）分组求均值并扣除，得到距平序列；
- `LS_OneBreak(Y, X, Ic)`：单变点分段线性回归，两段共享斜率、截距不同；
- `LS_MultiBreaks(Y, X, Ips)`：多变点版本，用 0/1 哑变量构造分段项；

三者共用内部求解器 `lm_solve()`，其核心是 `stats::.lm.fit()`，
直接对设计矩阵做最小二乘，比 `lm()` 更快，适合变点扫描这类需要反复拟合的场景。

== 修改包元数据

将 `DESCRIPTION` 的 `Package` 改为 `RHbreak`，重写 `Title`、`Description`；
删除模板对 `magrittr` 的依赖（本项目未使用管道），仅保留 `Suggests: testthat`。
同时删除模板自带的示例文件（`R/rpkg.template-package.R`、`man/rpkg.template-package.Rd`、
`tests/testthat/test-hello.R`、`data-raw/DATASET.R`），避免残留引用。

== 编写文档

在 `R/Component.R` 中为每个函数补充 roxygen2 注释块：`@param`、`@return`、
`@export`、`@examples`，内部函数 `lm_solve()` 用 `@noRd` 隐藏。
随后生成文档与命名空间：

```r
roxygen2::roxygenise()
```

该命令由注释自动产出 `man/*.Rd` 与 `NAMESPACE`，无需手写。

== 编写测试

`tests/testthat/` 下新增两个测试文件，构造*已知答案*的合成数据：

- `test-RemoveSeasonal.R`：周期序列去季节后距平应为 0；`mu` 必须按 MMDD 升序；
- `test-LS_breaks.R`：单变点能否还原真实斜率与截距跳变（`SSE` 接近 0）、
  `Ic = NA` 时退化为普通线性回归、多变点系数正确、`only.SSE = TRUE` 的返回结构。

```r
testthat::test_local()   # 19 个断言全部通过
```

== 本地检查与推送

```bash
R CMD build RHbreak
R CMD check --no-manual RHbreak_0.1.0.tar.gz   # Status: OK
git add -A && git commit -m "add Component.R, docs, tests"
git push -u origin master
```

推送后 GitHub Actions 自动触发 `R-CMD-check`（Windows + Ubuntu，R release），
约 2–3 min 返回结果。

= 遇到的问题

+ *`NAMESPACE` 残留 `import(magrittr)`*：roxygen2 只管理自己生成的条目，
  但模板包级文件 `R/rpkg.template-package.R` 里仍有 `@import magrittr`，
  未删该文件时重新生成会持续写回该行。删除旧包级文件、与 `DESCRIPTION`
  保持一致后才彻底消失。
+ *`R CMD check` 报 NOTE*：`Undefined global functions or variables: .lm.fit`。
  `lh` 求解器使用了 `stats` 的隐藏函数，需在包级注释中显式声明
  `@importFrom stats .lm.fit`，由 roxygen2 写入 `NAMESPACE`。
+ *roxygen2 未写入 `NAMESPACE`*：注释块首行误写成普通注释 `#` 而非 `#'`，
  导致整个块被忽略，表现为文档正常、命名空间缺失。改正前缀即可。
+ *Windows 下无 Rtools*：无法从源码编译，改用 Posit Package Manager 的
  预编译二进制（`https://packagemanager.posit.co/cran/latest`）安装
  `roxygen2` 与 `testthat`。
+ *包名含点*：`rpkg.template` 这类带点的包名合法但不推荐，重命名为 `RHbreak`，
  并同步修改 `tests/testthat.R` 中的 `library()` 与 `test_check()`。

= 结果

#table(
  columns: (auto, auto),
  [项目], [结果],
  [`testthat::test_local()`], [19 通过 / 0 失败],
  [`R CMD build`], [成功生成 `RHbreak_0.1.0.tar.gz`],
  [`R CMD check --no-manual`], [Status: OK（0 error / 0 warning / 0 note）],
  [GitHub Actions], [R-CMD-check 运行通过],
)

= 小结

模板化的关键是「只改内容、不动骨架」：`DESCRIPTION` 定依赖、roxygen 注释
生成文档与 `NAMESPACE`、testthat 用构造数据自证正确性、CI 负责跨平台回归。
文档与测试都交给 AI 生成后，人工复核的重点落在两处：函数语义是否被注释准确
表达，以及测试是否真的能捕捉错误（把变点位置改错一位，测试必须失败），
否则「全绿」只是装饰。
