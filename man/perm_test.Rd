\name{perm_test}
\alias{perm_test}
\title{Global k-sample permutation test}
\description{
Tests whether the distribution of \code{x} differs across the groups in \code{g}
by permuting group labels. Unlike a classical ANOVA it makes no normality assumption.
}
\usage{
perm_test(x, g, stat = "F", nperm = 9999, seed = NULL)
}
\arguments{
\item{x}{Numeric vector of observations.}
\item{g}{Grouping vector (coerced to factor), same length as \code{x}, at least two groups.}
\item{stat}{\code{"F"} (default), \code{"kruskal"}, \code{"range_means"}, or a function
\code{f(x, g)} returning a single number where larger means more different.}
\item{nperm}{Number of random permutations.}
\item{seed}{Optional integer seed for reproducibility.}
}
\value{
An object of class \code{perm_test} with the observed statistic, the null
distribution and the p-value. It has \code{print} and \code{plot} methods.
}
\examples{
res <- perm_test(PlantGrowth$weight, PlantGrowth$group, nperm = 2000, seed = 1)
res
plot(res)
}
