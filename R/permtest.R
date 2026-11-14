#' Statistics for k-sample comparisons
#'
#' Built-in statistics used by perm_test(). Each takes a numeric vector and a factor.
#' @noRd
f_stat <- function(x, g) {
  n <- tabulate(g)
  means <- vapply(split(x, g), mean, numeric(1))
  grand <- mean(x)
  between <- sum(n * (means - grand)^2) / (nlevels(g) - 1)
  within <- sum((x - means[as.integer(g)])^2) / (length(x) - nlevels(g))
  between / within
}

kruskal_stat <- function(x, g) {
  r <- rank(x)
  n <- tabulate(g)
  rbar <- vapply(split(r, g), mean, numeric(1))
  N <- length(x)
  12 / (N * (N + 1)) * sum(n * (rbar - (N + 1) / 2)^2)
}

range_means_stat <- function(x, g) {
  m <- vapply(split(x, g), mean, numeric(1))
  max(m) - min(m)
}

resolve_stat <- function(stat) {
  if (is.function(stat)) return(stat)
  switch(match.arg(stat, c("F", "kruskal", "range_means")),
    F = f_stat, kruskal = kruskal_stat, range_means = range_means_stat
  )
}

# (1 + extreme) / (nperm + 1): never returns 0 (Phipson & Smyth, 2010).
perm_p_value <- function(null, observed, alternative) {
  extreme <- switch(alternative,
    greater   = sum(null >= observed - 1e-12),
    less      = sum(null <= observed + 1e-12),
    two.sided = sum(abs(null - mean(null)) >= abs(observed - mean(null)) - 1e-12)
  )
  (extreme + 1) / (length(null) + 1)
}

#' Global k-sample permutation test
#'
#' Tests whether the distribution of `x` differs across the groups in `g` by
#' permuting group labels. Unlike a classical ANOVA, it makes no normality assumption.
#'
#' @param x Numeric vector of observations.
#' @param g Grouping vector (coerced to factor), same length as `x`, at least two groups.
#' @param stat `"F"` (default), `"kruskal"`, `"range_means"`, or a function `f(x, g)`
#'   returning a single number where larger means "more different".
#' @param nperm Number of random permutations.
#' @param seed Optional integer seed for reproducibility.
#' @return An object of class `perm_test` with the observed statistic, the null
#'   distribution and the p-value. Has `print` and `plot` methods.
#' @examples
#' res <- perm_test(PlantGrowth$weight, PlantGrowth$group, nperm = 2000, seed = 1)
#' res
#' plot(res)
#' @export
perm_test <- function(x, g, stat = "F", nperm = 9999, seed = NULL) {
  g <- check_inputs(x, g)
  fun <- resolve_stat(stat)
  if (!is.null(seed)) set.seed(seed)
  observed <- fun(x, g)
  null <- vapply(seq_len(nperm), function(i) fun(x, sample(g)), numeric(1))
  structure(list(
    statistic = observed, null = null, p.value = perm_p_value(null, observed, "greater"),
    stat = if (is.function(stat)) "custom" else stat, nperm = nperm, groups = levels(g)
  ), class = "perm_test")
}

#' Pairwise two-sample permutation tests with multiplicity correction
#'
#' Runs a permutation test for every pair of groups on the difference of a
#' location statistic, then adjusts p-values with [stats::p.adjust()].
#'
#' @inheritParams perm_test
#' @param fun Location function applied to each group (default `mean`, e.g. `median`).
#' @param alternative `"two.sided"`, `"less"` or `"greater"` for `fun(group1) - fun(group2)`.
#' @param p.adjust.method Any method accepted by [stats::p.adjust()] (default `"holm"`).
#' @return A data frame with one row per pair: groups, observed difference, raw and adjusted p-values.
#' @examples
#' pairwise_perm_test(InsectSprays$count, InsectSprays$spray, nperm = 999, seed = 1)
#' @export
pairwise_perm_test <- function(x, g, fun = mean, alternative = c("two.sided", "less", "greater"),
                               nperm = 9999, p.adjust.method = "holm", seed = NULL) {
  g <- check_inputs(x, g)
  alternative <- match.arg(alternative)
  if (!is.null(seed)) set.seed(seed)
  pairs <- utils::combn(levels(g), 2)
  rows <- lapply(seq_len(ncol(pairs)), function(j) {
    a <- pairs[1, j]
    b <- pairs[2, j]
    keep <- g %in% c(a, b)
    xs <- x[keep]
    gs <- droplevels(g[keep])
    diff_fun <- function(lbl) fun(xs[lbl == a]) - fun(xs[lbl == b])
    observed <- diff_fun(gs)
    null <- vapply(seq_len(nperm), function(i) diff_fun(sample(gs)), numeric(1))
    data.frame(group1 = a, group2 = b, difference = observed,
               p.value = perm_p_value(null, observed, alternative))
  })
  out <- do.call(rbind, rows)
  out$p.adjusted <- stats::p.adjust(out$p.value, method = p.adjust.method)
  out
}

check_inputs <- function(x, g) {
  if (!is.numeric(x)) stop("`x` must be numeric.", call. = FALSE)
  if (length(x) != length(g)) stop("`x` and `g` must have the same length.", call. = FALSE)
  if (anyNA(x) || anyNA(g)) stop("Missing values are not allowed.", call. = FALSE)
  g <- droplevels(as.factor(g))
  if (nlevels(g) < 2) stop("Need at least two groups.", call. = FALSE)
  g
}

#' @export
print.perm_test <- function(x, ...) {
  cat("\n  k-sample permutation test\n\n")
  cat(sprintf("groups:    %s\n", paste(x$groups, collapse = ", ")))
  cat(sprintf("statistic: %s = %.4f\n", x$stat, x$statistic))
  cat(sprintf("p-value:   %.4g  (%d permutations)\n\n", x$p.value, x$nperm))
  invisible(x)
}

#' @export
plot.perm_test <- function(x, ...) {
  graphics::hist(x$null, breaks = 40, col = "#cfdcef", border = "white",
                 main = "Permutation null distribution", xlab = x$stat,
                 xlim = range(c(x$null, x$statistic)), ...)
  graphics::abline(v = x$statistic, col = "#c0392b", lwd = 3)
  invisible(x)
}
