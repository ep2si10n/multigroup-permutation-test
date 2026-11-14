# permk — Permutation Tests for k Independent Samples

[![R-CMD-check](https://github.com/ep2si10n/multigroup-permutation-test/actions/workflows/R-CMD-check.yml/badge.svg)](https://github.com/ep2si10n/multigroup-permutation-test/actions/workflows/R-CMD-check.yml)

A small R package for **distribution-free comparison of several groups**. Use it when ANOVA or t-test
assumptions (normality, equal variances) are doubtful, or when you need a statistic with no closed-form
null distribution.

## Features

- **`perm_test()`**: global k-sample test. Under H₀ the group labels are exchangeable, so the package permutes them
  and builds the null distribution of:
  - the **F statistic** (default),
  - the **Kruskal–Wallis H**,
  - the **range of group means**,
  - or **any function `f(x, g)` you supply**.
- **`pairwise_perm_test()`**: post-hoc two-sample tests for every pair of groups (difference of means, medians or
  any location function). One- or two-sided, with **Holm** (or any `p.adjust`) correction for multiple comparisons.
- **Valid p-values** via the `(b + 1) / (m + 1)` estimator (Phipson & Smyth, 2010). They are never exactly 0.
- `print` and `plot` methods. The plot shows the null histogram with the observed statistic marked.
- Input validation, reproducible results through `seed`, and a testthat suite checked on every push with R CMD check.

## Installation

```r
# install.packages("remotes")
remotes::install_github("ep2si10n/multigroup-permutation-test")
```

## Example

```r
library(permk)

# Do the three PlantGrowth groups differ?
res <- perm_test(PlantGrowth$weight, PlantGrowth$group, nperm = 9999, seed = 1)
res          # permutation p ≈ 0.017, close to the classical ANOVA p = 0.016
plot(res)

# Which pairs differ? Holm-adjusted post-hoc tests
pairwise_perm_test(PlantGrowth$weight, PlantGrowth$group, seed = 1)

# Robust version: medians and a rank statistic
perm_test(InsectSprays$count, InsectSprays$spray, stat = "kruskal", seed = 1)
pairwise_perm_test(InsectSprays$count, InsectSprays$spray, fun = median, seed = 1)

# Custom statistic: spread of the group medians
perm_test(PlantGrowth$weight, PlantGrowth$group,
          stat = function(x, g) var(tapply(x, g, median)))
```

## How it is validated

The test suite (`tests/testthat`) checks that:

- the F and Kruskal–Wallis statistics match `stats::anova` and `stats::kruskal.test` exactly;
- the permutation p-value on `PlantGrowth` agrees with classical ANOVA;
- under the null hypothesis, the rejection rate at α = 0.05 stays close to nominal;
- a real shift between groups is detected;
- Holm-adjusted p-values are never below the raw ones, and one-sided alternatives point the right way;
- bad inputs raise clear errors.

## History

Started in 2023 as a statistics coursework script. That version mixed Markdown and R in one file, so it did not run,
and despite its name it only compared the first two groups. The 2026 rewrite turned it into an installable package
with a true k-sample test, post-hoc pairwise comparisons, tests and CI.
