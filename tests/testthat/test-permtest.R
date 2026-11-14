test_that("F statistic matches stats::anova", {
  fit <- stats::anova(stats::lm(weight ~ group, data = PlantGrowth))
  expect_equal(f_stat(PlantGrowth$weight, PlantGrowth$group), fit$`F value`[1])
})

test_that("Kruskal statistic matches stats::kruskal.test without ties", {
  set.seed(1)
  x <- rnorm(30)
  g <- factor(rep(c("a", "b", "c"), each = 10))
  expect_equal(kruskal_stat(x, g), unname(stats::kruskal.test(x, g)$statistic))
})

test_that("permutation p-value agrees with classical ANOVA on PlantGrowth", {
  res <- perm_test(PlantGrowth$weight, PlantGrowth$group, nperm = 4000, seed = 42)
  anova_p <- stats::anova(stats::lm(weight ~ group, data = PlantGrowth))$`Pr(>F)`[1]
  expect_s3_class(res, "perm_test")
  expect_lt(abs(res$p.value - anova_p), 0.01)
})

test_that("p-values are valid and reproducible", {
  set.seed(3)
  x <- rnorm(40)
  g <- rep(letters[1:4], 10)
  a <- perm_test(x, g, nperm = 500, seed = 7)
  b <- perm_test(x, g, nperm = 500, seed = 7)
  expect_identical(a$p.value, b$p.value)
  expect_gt(a$p.value, 0)
  expect_lte(a$p.value, 1)
})

test_that("a clear effect gives a small p-value, the null does not", {
  set.seed(4)
  g <- rep(c("a", "b", "c"), each = 15)
  shifted <- rnorm(45) + c(a = 0, b = 0, c = 3)[g]
  expect_lt(perm_test(shifted, g, nperm = 999, seed = 1)$p.value, 0.01)
  null_p <- vapply(1:30, function(s) {
    perm_test(rnorm(45), g, nperm = 199, seed = s)$p.value
  }, numeric(1))
  expect_lt(mean(null_p < 0.05), 0.2)
})

test_that("custom statistics are accepted", {
  res <- perm_test(PlantGrowth$weight, PlantGrowth$group,
                   stat = function(x, g) stats::var(tapply(x, g, median)), nperm = 200, seed = 1)
  expect_equal(res$stat, "custom")
})

test_that("pairwise tests return one row per pair with adjusted >= raw p-values", {
  res <- pairwise_perm_test(PlantGrowth$weight, PlantGrowth$group, nperm = 999, seed = 1)
  expect_equal(nrow(res), 3)
  expect_true(all(res$p.adjusted >= res$p.value))
  trt <- res[res$group1 == "trt1" & res$group2 == "trt2", ]
  expect_lt(trt$p.value, 0.05)
})

test_that("one-sided alternatives point the right way", {
  x <- c(1:10, 11:20)
  g <- rep(c("low", "high"), each = 10)
  res_less <- pairwise_perm_test(x, g, alternative = "less", nperm = 999, seed = 1)
  res_greater <- pairwise_perm_test(x, g, alternative = "greater", nperm = 999, seed = 1)
  # levels sort alphabetically: group1 = "high", group2 = "low", difference = 10 > 0
  expect_lt(res_greater$p.value, 0.01)
  expect_gt(res_less$p.value, 0.9)
})

test_that("bad inputs fail loudly", {
  expect_error(perm_test("a", "b"), "numeric")
  expect_error(perm_test(1:3, c("a", "b")), "same length")
  expect_error(perm_test(1:3, rep("a", 3)), "two groups")
  expect_error(perm_test(c(1, NA, 3), c("a", "b", "a")), "Missing")
})
