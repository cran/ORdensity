% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/ORdensity.R
\docType{class}
\name{ORdensity-class}
\alias{ORdensity-class}
\alias{ORdensity}
\title{S4 class for representing potential differentially expressed genes}
\description{
An object of class ORdensity includes all potential differentially expressed genes
given microarray data measured in two experimental conditions.
}
\section{Slots}{

\describe{
\item{\code{Exp_cond_1}}{Matrix including microarray data measured under experimental condition 1.}

\item{\code{Exp_cond_2}}{matrix including microarray data measured under experimental condition 2.}

\item{\code{labels}}{Vector of characters identifying the genes, by default
rownames(Exp_cond_1) is inherited. If NULL,
the genes are named ‘Gene1’, ..., ‘Genen' according to the order given in \code{Exp_cond_1}.}

\item{\code{B}}{Numeric value indicating the number of permutations. By default, \code{B}=100.}

\item{\code{scale}}{Logical value to indicate whether the scaling of the difference of quantiles should be done.}

\item{\code{alpha}}{Numeric value  used  by  the  method  to  calculate  the percentile \eqn{(1-\alpha)100} of all the elements of the matrix  with  the  permuted  samples. By default 0.05.}

\item{\code{fold}}{Numeric value, by default \code{fold}=10. It controls the number of partitions.}

\item{\code{probs}}{Vector of numerics. It sets the quantiles to be considered. By default
\code{probs = c(0.25, 0.5, 0.75)}.}

\item{\code{weights}}{Vector of numerics. It controls the weights given to the quantiles set in \code{probs}. 
By default  \code{weights = c(1/4, 1/2, 1/4)}.}

\item{\code{numneighbours}}{Numeric value to set the number of nearest neighbours. By default \code{numneighbours=10}.}

\item{\code{numclustoseek}}{Numeric value to set the number of maximum clusters to consider. By default \code{numclustoseek=10}.}

\item{\code{out}}{List containing the potential DE genes and their characteristics.}

\item{\code{OR}}{Outlyingness index (See Martínez-Otzeta, J. M. et al. 2020;  Irigoien, I., and Arenas, C. 2018).}

\item{\code{FP}}{Average number of false positive permuted cases in the neighbourhood  (See Martínez-Otzeta, J. M. et al. 2020;  Irigoien, I., and Arenas, C. 2018).}

\item{\code{dFP}}{Average density of false positive permuted cases in the neighbourhood  (See  Martínez-Otzeta, J. M. et al. 2020; Irigoien, I., and Arenas, C. 2018).}

\item{\code{char}}{Matrix holding internal computations. Non-developers should left this parameter as default.}

\item{\code{bestKclustering}}{Number of clusters for partitioning the data. It is advisable to let the object to automatically estimate the best partition.}

\item{\code{verbose}}{Boolean indicating if log messages are going to be printed.}

\item{\code{parallel}}{Boolean indicating if parallel process is used.}

\item{\code{nprocs}}{Integer indicating the number of processors to be used. If nprocs is 0 or negative, the number of processors detected in the machine is used.}

\item{\code{replicable}}{Boolean indicating if the same seed is used for the pseudorandom number generation.}

\item{\code{seed}}{Integer used as seed by the pseudorandom number generator.}
}}

\examples{
# To create an instance of a class ORdensity given data from 2 experimental conditions
simexpr_reduced <- simexpr[c(1:15,101:235),]
x <- simexpr_reduced[, 3:32]
y <- simexpr_reduced[, 33:62]
EXC.1 <- as.matrix(x)
EXC.2 <- as.matrix(y)
myORdensity <- new("ORdensity", Exp_cond_1 = EXC.1, Exp_cond_2 = EXC.2, B = 20)
}
