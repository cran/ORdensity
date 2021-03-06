% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/ORdensity.R
\name{plot.ORdensity}
\alias{plot.ORdensity}
\title{Plot function implemented by ORdensity class}
\usage{
\method{plot}{ORdensity}(x, numclusters = x@bestKclustering, ...)
}
\arguments{
\item{x}{Object of class \code{\link[=ORdensity-class]{ORdensity}}.}

\item{numclusters}{By default \code{NULL}, it inherits from the \code{x}. Optionally,
an integer number indicating number of clusters the genes are partitioned.}

\item{...}{Optional arguments inherited from the generic \code{\link{plot}} method.}
}
\value{
Displays a plot with a representation of the potential genes based on OR (vertical axis),
FP (horizontal axis) and dFP (size of the symbol is inversely proportional to its value). Moreover,
genes identified as DE by the relaxed selection are represented by the symbol \eqn{\bigtriangleup}.
}
\description{
Plots a representation of the potential genes based on OR, FP and dFP.
}
\examples{
# Read data from 2 experimental conditions
simexpr_reduced <- simexpr[c(1:15,101:235),]
x <- simexpr_reduced[, 3:32]
y <- simexpr_reduced[, 33:62]
EXC.1 <- as.matrix(x)
EXC.2 <- as.matrix(y)
myORdensity <- new("ORdensity", Exp_cond_1 = EXC.1, Exp_cond_2 = EXC.2, B = 20)
plot(myORdensity)
}
