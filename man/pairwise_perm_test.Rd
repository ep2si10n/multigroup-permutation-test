\name{pairwise_perm_test}
\alias{pairwise_perm_test}
\title{Pairwise two-sample permutation tests with multiplicity correction}
\description{
Runs a permutation test for every pair of groups on the difference of a location
statistic, then adjusts the p-values with \code{\link[stats]{p.adjust}}.
}
\usage{
pairwise_perm_test(x, g, fun = mean, alternative = c("two.sided", "less", "greater"),
                   nperm = 9999, p.adjust.method = "holm", seed = NULL)
}
\arguments{
\item{x}{Numeric vector of observations.}
\item{g}{Grouping vector, same length as \code{x}.}
\item{fun}{Location function applied to each group, e.g. \code{mean} or \code{median}.}
\item{alternative}{\code{"two.sided"}, \code{"less"} or \code{"greater"} for \code{fun(group1) - fun(group2)}.}
\item{nperm}{Number of random permutations per pair.}
\item{p.adjust.method}{Any method accepted by \code{\link[stats]{p.adjust}}.}
\item{seed}{Optional integer seed for reproducibility.}
}
\value{
A data frame with one row per pair: groups, observed difference, raw and adjusted p-values.
}
\examples{
pairwise_perm_test(InsectSprays$count, InsectSprays$spray, nperm = 999, seed = 1)
}
