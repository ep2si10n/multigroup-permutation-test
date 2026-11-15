<div align="center">

# permk

**Permutation tests for comparing k independent groups in R. No normality assumptions required.**

[![R-CMD-check](https://github.com/ep2si10n/multigroup-permutation-test/actions/workflows/R-CMD-check.yml/badge.svg)](https://github.com/ep2si10n/multigroup-permutation-test/actions/workflows/R-CMD-check.yml)
![R](https://img.shields.io/badge/R-package-276DC3?logo=r&logoColor=white)
![Dependencies](https://img.shields.io/badge/dependencies-base%20R%20only-brightgreen)
[![License: MIT](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE.md)

</div>

## Overview

ANOVA and the t-test are the default tools for comparing groups, but they rely on assumptions (normal data, equal
variances) that real data often breaks: small samples, skewed distributions, outliers, counts.

Permutation tests avoid those assumptions. If the groups really don't differ, the group labels are interchangeable, so
shuffling them thousands of times shows what the statistic looks like under the null hypothesis. The p-value is simply
how often the shuffled data look at least as extreme as the real data.

**permk** packages that idea for the k-group case. It has a global test to ask "do the groups differ at all?" and a
post-hoc step to ask "which pairs differ?", with proper multiple-comparison correction.

## Features

- **Global k-sample test** with the F statistic, Kruskal–Wallis H, the range of group means, or **any statistic you
  write**.
- **Pairwise post-hoc tests** on the difference of means, medians or any location function. One- or two-sided.
- **Multiple-comparison correction** with Holm by default, or any method supported by `p.adjust()`.
- **Valid p-values.** It uses the `(b + 1) / (m + 1)` estimator from Phipson & Smyth (2010), which never reports an
  impossible p = 0.
- **`print` and `plot` methods.** The plot shows the null distribution with the observed statistic marked.
- **Base R only.** No dependencies to install.

## Installation

```r
# install.packages("remotes")
remotes::install_github("ep2si10n/multigroup-permutation-test")
```

## Usage

### Do the groups differ?

```r
library(permk)

res <- perm_test(PlantGrowth$weight, PlantGrowth$group, nperm = 9999, seed = 1)
res
#>   k-sample permutation test
#>
#> groups:    ctrl, trt1, trt2
#> statistic: F = 4.8461
#> p-value:   ≈ 0.017  (9999 permutations)

plot(res)
```

The permutation p-value (≈ 0.017) agrees closely with the classical ANOVA (p = 0.016). That is expected here, because
`PlantGrowth` is well behaved. The two diverge when the parametric assumptions don't hold.

### Which pairs differ?

```r
pairwise_perm_test(PlantGrowth$weight, PlantGrowth$group, seed = 1)
```

The result is a data frame with one row per pair: the observed difference, the raw p-value and the Holm-adjusted
p-value.

### Robust alternatives

```r
# rank-based global test
perm_test(InsectSprays$count, InsectSprays$spray, stat = "kruskal", seed = 1)

# compare medians instead of means
pairwise_perm_test(InsectSprays$count, InsectSprays$spray, fun = median, seed = 1)

# bring your own statistic
perm_test(PlantGrowth$weight, PlantGrowth$group,
          stat = function(x, g) var(tapply(x, g, median)))
```

## API

| Function | Purpose |
|---|---|
| `perm_test(x, g, stat = "F", nperm = 9999, seed = NULL)` | Global test across all groups |
| `pairwise_perm_test(x, g, fun = mean, alternative = "two.sided", nperm = 9999, p.adjust.method = "holm", seed = NULL)` | All pairwise comparisons |

Full documentation: `?perm_test` and `?pairwise_perm_test`.

## Validation

The test suite runs on every push via `R CMD check` and checks that:

- the F and Kruskal–Wallis statistics match `stats::anova()` and `stats::kruskal.test()` exactly;
- on `PlantGrowth`, the permutation p-value agrees with classical ANOVA;
- under the null hypothesis, the false-positive rate at α = 0.05 stays near its nominal level;
- a real shift between groups is detected;
- adjusted p-values are never smaller than raw ones, and one-sided tests point the right way;
- invalid inputs (non-numeric data, length mismatch, a single group, missing values) fail with clear messages.

## History

This started in 2023 as a script for a statistics course. In 2026 it was rewritten as an installable package. The
rewrite added a true k-group test (the original only compared the first two groups), post-hoc comparisons, input
validation, tests and continuous integration.

## References

- Good, P. (2005). *Permutation, Parametric, and Bootstrap Tests of Hypotheses* (3rd ed.). Springer.
- Phipson, B., & Smyth, G. K. (2010). *Permutation p-values should never be zero*. Statistical Applications in
  Genetics and Molecular Biology, 9(1).
- Holm, S. (1979). *A simple sequentially rejective multiple test procedure*. Scandinavian Journal of Statistics, 6(2).

## Contributing

Issues and pull requests are welcome. Before opening a PR, please run the checks locally:

```bash
Rscript -e 'devtools::check()'   # or: R CMD build . && R CMD check permk_*.tar.gz
```

## License

Released under the [MIT License](LICENSE.md).
