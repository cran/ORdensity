#' @title S4 class for representing potential differentially expressed genes
#'
#' @description An object of class ORdensity includes all potential differentially expressed genes
#' given microarray data measured in two experimental conditions.
#'
#' @name ORdensity-class
#' @rdname ORdensity-class
#' @exportClass ORdensity
#' @importFrom graphics legend plot points
#' @importFrom methods new
#' @importFrom stats quantile sd
#' @importFrom utils object.size
#' @importFrom doRNG %dorng%
#' @importFrom foreach %dopar%
#' @export findDEgenes
#' @export preclusteredData
#' @exportClass ORdensity
#'
#' @slot Exp_cond_1 Matrix including microarray data measured under experimental condition 1.
#' @slot Exp_cond_2 matrix including microarray data measured under experimental condition 2.
#' @slot labels  Vector of characters identifying the genes, by default
#' rownames(Exp_cond_1) is inherited. If NULL,
#' the genes are named ‘Gene1’, ..., ‘Genen' according to the order given in \code{Exp_cond_1}.
#' @slot B Numeric value indicating the number of permutations. By default, \code{B}=100.
#' @slot scale Logical value to indicate whether the scaling of the difference of quantiles should be done.
#' @slot alpha Numeric value  used  by  the  method  to  calculate  the percentile \eqn{(1-\alpha)100} of all the elements of the matrix  with  the  permuted  samples. By default 0.05.
#' @slot fold Numeric value, by default \code{fold}=10. It controls the number of partitions.
#' @slot probs Vector of numerics. It sets the quantiles to be considered. By default
#' \code{probs = c(0.25, 0.5, 0.75)}.
#' @slot weights Vector of numerics. It controls the weights given to the quantiles set in \code{probs}. 
#' By default  \code{weights = c(1/4, 1/2, 1/4)}.
#' @slot numneighbours Numeric value to set the number of nearest neighbours. By default \code{numneighbours=10}.
#' @slot numclustoseek Numeric value to set the number of maximum clusters to consider. By default \code{numclustoseek=10}.
#' @slot out List containing the potential DE genes and their characteristics.
#' @slot OR  Outlyingness index (See Martínez-Otzeta, J. M. et al. 2020;  Irigoien, I., and Arenas, C. 2018).
#' @slot FP Average number of false positive permuted cases in the neighbourhood  (See Martínez-Otzeta, J. M. et al. 2020;  Irigoien, I., and Arenas, C. 2018).
#' @slot dFP Average density of false positive permuted cases in the neighbourhood  (See  Martínez-Otzeta, J. M. et al. 2020; Irigoien, I., and Arenas, C. 2018).
#' @slot char Matrix holding internal computations. Non-developers should left this parameter as default.
#' @slot bestKclustering Number of clusters for partitioning the data. It is advisable to let the object to automatically estimate the best partition.
#' @slot verbose Boolean indicating if log messages are going to be printed.
#' @slot parallel Boolean indicating if parallel process is used.
#' @slot nprocs Integer indicating the number of processors to be used. If nprocs is 0 or negative, the number of processors detected in the machine is used.
#' @slot replicable Boolean indicating if the same seed is used for the pseudorandom number generation.
#' @slot seed Integer used as seed by the pseudorandom number generator.
#' @examples
#' # To create an instance of a class ORdensity given data from 2 experimental conditions
#' simexpr_reduced <- simexpr[c(1:15,101:235),]
#' x <- simexpr_reduced[, 3:32]
#' y <- simexpr_reduced[, 33:62]
#' EXC.1 <- as.matrix(x)
#' EXC.2 <- as.matrix(y)
#' myORdensity <- new("ORdensity", Exp_cond_1 = EXC.1, Exp_cond_2 = EXC.2, B = 20)

ORdensity <- setClass(
	"ORdensity",
	slots = c(Exp_cond_1="matrix", Exp_cond_2="matrix", labels="character", 
	          B="numeric", scale="logical", alpha="numeric", 
	          fold="numeric", probs="numeric", weights="numeric", numneighbours="numeric", numclustoseek="numeric",
	          out="list", OR="numeric", FP="numeric", dFP="numeric", char="data.frame", bestKclustering = "numeric", 
	          verbose="logical", parallel="logical", nprocs="numeric", replicable="logical", seed="numeric"),
	prototype = list(Exp_cond_1=matrix(), Exp_cond_2=matrix(), labels=character(), 
	                 B=numeric(), scale=logical(), alpha=numeric(), 
	                 fold=numeric(), probs=numeric(), weights=numeric(), numneighbours=numeric(), numclustoseek=numeric(), 
	                 out=list(), OR=numeric(), FP=numeric(), dFP=numeric(), char=data.frame(), bestKclustering = numeric(), 
	                 verbose=logical(), parallel=logical(), nprocs=numeric(), replicable=logical(), seed=numeric())
)

#' @name summary.ORdensity
#' @title Summary function implemented by ORdensity class 
#' @description This function clusters the potential differentially expressed (DE) genes among them 
#' so that the real DE genes can be distinguish from the not DE genes.
#' @param object An object of \code{\link{ORdensity}} class.
#' @param numclusters By default \code{NULL}, it inherits from the ORdensity \code{object}. 
#' Optionally, an integer number indicating number of clusters.
#' @param ... Optional arguments inherited from the generic \code{\link{summary}} method.
#' @details Once the potential DE genes are identified, the real DE genes and the not real DE genes or
#' false positives must be distinguished. Since the real DE genes must have high OR values along with
#' low FP and dFP values, and on the contrary, the false DE genes must have low OR values but high FP and dFP values,
#' a clustering of all the potential DE genes is carried out. The clustering is based on build-on variables OR, FP and dFP 
#' (see class \code{ORdensity}) which are scaled. The clustering algorithm is   \code{\link{pam}} and by default
#' the number of clusters in the partition is obtained by \code{\link{silhouette}}. With parameter \code{numclusters} the number
#' of clusters in the partition can be customized.
#' @return  A list with \eqn{k} lists where \eqn{k} is the best number of clusters found. 
#' The clusters are ordered based on their importance according to the mean OR values of the clusters 
#' (greater is the mean OR value of the cluster more important are the genes in the cluster).
#' The first one is the most important, the last one the less important. Each list has elements:
#' \itemize{
#' \item \code{numberOfGenes}: Number of genes in the cluster.
#' \item \code{CharacteristicsCluster}: Matrix with mean values and standard deviation of variables OR, FP and dFP for each cluster.
#' \item \code{Genes}: Identification of the genes in the cluster.
#' }
#' @examples
#' # Read data from 2 experimental conditions
#' simexpr_reduced <- simexpr[c(1:15,101:235),]
#' x <- simexpr_reduced[, 3:32]
#' y <- simexpr_reduced[, 33:62]
#' EXC.1 <- as.matrix(x)
#' EXC.2 <- as.matrix(y)
#' myORdensity <- new("ORdensity", Exp_cond_1 = EXC.1, Exp_cond_2 = EXC.2, B = 20)
#' summary(myORdensity)
#' @rdname summary.ORdensity
#' @exportS3Method summary ORdensity

setGeneric("summary.ORdensity", function(object, numclusters=NULL, ...) standardGeneric("summary.ORdensity"))

setMethod("summary.ORdensity",
          signature = "ORdensity",
          definition = function(object, numclusters=NULL, ...){
            KForClustering <- object@bestKclustering
            if (!is.null(numclusters))
            {
              KForClustering <- numclusters
            }
	    d <- distances::distances(scale(object@char))
            clustering <- cluster::pam(d[1:(dim(d)[2]), 1:(dim(d)[2])], KForClustering, diss = TRUE)$clustering
            result_prov <- list()
            meanOR <- rep(NA, KForClustering)
            CharClus <- list()
            aux <- matrix(NA, nrow=2, ncol=3, dimnames=list(c("mean", "sd"), c("OR", "FP", "dFP")))
            for (k in 1:KForClustering)
            {
              result_prov[[k]] <- object@out$summary[clustering==k,]
              aux[1, 1] <- mean(result_prov[[k]][,'OR'])
              aux[2, 1] <- sd(result_prov[[k]][,'OR'])
              aux[1, 2] <- mean(result_prov[[k]][,'FP'])
              aux[2, 2] <- sd(result_prov[[k]][,'FP'])
              aux[1, 3] <- mean(result_prov[[k]][,'dFP'])
              aux[2, 3] <- sd(result_prov[[k]][,'dFP'])
              CharClus[[k]] <- aux
              meanOR[k] <- aux[1, 1]
            }
            
            clusters_ordering <- order(as.numeric(meanOR), decreasing = TRUE)
            clusters <- list()
            for (k in 1:KForClustering)
            {
              clusters[[k]] <- result_prov[[clusters_ordering[k]]]
            }
            DFgenes <- list()
            for (k in 1:KForClustering)
            {
              DFgenes[[k]] <- list( "numberOfGenes"=length(clusters[[k]][,'id']), 
                                    "CharacteristicsCluster"=CharClus[[k]], "genes"=sort(clusters[[k]][,'id']))
            }
            cat("The ORdensity method has found that the optimal clustering of the data consists of",object@bestKclustering,
		"clusters, computed from a maximum of", object@numclustoseek,"when the ORdensity object was created\n")
            if (!is.null(numclusters))
            {
              cat("The user has chosen a clustering of",numclusters,"clusters\n")
            }
            names(DFgenes) <- paste("Cluster", 1:KForClustering, sep="")
            return (DFgenes)
          }
)

#' @name preclusteredData
#' @param object Object of class \code{"\link[=ORdensity-class]{ORdensity}"}.
#' @param verbose Boolean indicating if log messages are going to be printed.
#' @rdname preclusteredData
#' @docType methods
setGeneric("preclusteredData", function(object, verbose=TRUE) standardGeneric("preclusteredData"))
#' @title Preprocessed description of all the identified potential DE genes
#' 
#' @description This function returns the description of all the identified 
#' potential DE genes in terms of variables OR, FP, and dFP in one only table so that 
#' the interesed user can perform her own clustering analysis.
#' 
#' @param object Object of class \code{\link[=ORdensity-class]{ORdensity}}.
#' @param verbose Boolean indicating if log messages are going to be printed.
#' @return \code{\link{data.frame}} with all potential DE genes.
#' @examples
#' # Read data from 2 experimental conditions
#' simexpr_reduced <- simexpr[c(1:15,101:235),]
#' x <- simexpr_reduced[, 3:32]
#' y <- simexpr_reduced[, 33:62]
#' EXC.1 <- as.matrix(x)
#' EXC.2 <- as.matrix(y)
#' myORdensity <- new("ORdensity", Exp_cond_1 = EXC.1, Exp_cond_2 = EXC.2, B = 20)
#' # dataframe with all potential DE genes:
#' preclusteredData(myORdensity)
#' @rdname preclusteredData
#' @docType methods
#' @export
setMethod("preclusteredData",
          signature = "ORdensity",
          definition = function(object, verbose=TRUE){
              prop <- object@out$prop
              neighbours <- prop[3]
              p0 <- prop[2]
              preclustered_data <- as.data.frame(object@out$summary)
              preclustered_data$DifExp <- NULL
              preclustered_data$minFP <- NULL
              preclustered_data$maxFP <- NULL
              preclustered_data$radius <- NULL
              preclustered_data$Strong <- ifelse(preclustered_data$FP == 0, "S", "-")
              preclustered_data$Relaxed <- ifelse(preclustered_data$FP < p0 * neighbours, "R", "-")
              if (verbose) {
                cat("Columns \"Strong\" and \"Relaxed\" show the genes identified as DE genes\n")
                cat("They denote the strong selection (FP=0) with S and the relaxed selection (FP < expectedFalsePositives) with F\n")
              }
              preclustered_data
          }
)

setMethod("show",
           signature = "ORdensity",
           definition = function(object) {
             preClustering <- preclusteredData(object, verbose=FALSE)
             numGenes <- nrow(preClustering)
             cat("The ORdensity method has detected", numGenes, "potential DE genes\n", sep = " ")
           }
)

#' @name plot.ORdensity
#' @title Plot function implemented by ORdensity class 
#' @description Plots a representation of the potential genes based on OR, FP and dFP. 
#' @param x Object of class \code{\link[=ORdensity-class]{ORdensity}}.
#' @param numclusters By default \code{NULL}, it inherits from the \code{x}. Optionally,
#' an integer number indicating number of clusters the genes are partitioned.
#' @param ... Optional arguments inherited from the generic \code{\link{plot}} method.
#' @return  Displays a plot with a representation of the potential genes based on OR (vertical axis),
#' FP (horizontal axis) and dFP (size of the symbol is inversely proportional to its value). Moreover,
#' genes identified as DE by the relaxed selection are represented by the symbol \eqn{\bigtriangleup}.
#' @examples
#' # Read data from 2 experimental conditions
#' simexpr_reduced <- simexpr[c(1:15,101:235),]
#' x <- simexpr_reduced[, 3:32]
#' y <- simexpr_reduced[, 33:62]
#' EXC.1 <- as.matrix(x)
#' EXC.2 <- as.matrix(y)
#' myORdensity <- new("ORdensity", Exp_cond_1 = EXC.1, Exp_cond_2 = EXC.2, B = 20)
#' plot(myORdensity)
#' @rdname plot.ORdensity
#' @exportS3Method plot ORdensity

setGeneric("plot.ORdensity", function(x, numclusters = x@bestKclustering, ...) standardGeneric("plot.ORdensity"))

setMethod("plot.ORdensity",
  signature = "ORdensity",
  definition = function(x, numclusters = x@bestKclustering, ...){
    d <- distances::distances(scale(x@char))
    clustering <- cluster::pam(d[1:(dim(d)[2]), 1:(dim(d)[2])], numclusters, diss = TRUE)$clustering
    legend_text <- sprintf("cluster %s",seq(1:numclusters))
    
    prop <- x@out$prop
    neighbours <- prop[3]
    p0 <- prop[2]
    preclustered_data <- as.data.frame(x@out$summary)
    selec <- preclustered_data$FP < p0 * neighbours
    
    plot(x@FP, x@OR, type="n",main="Potential genes",xlab="FP",ylab="OR")
    points(x@FP[selec], x@OR[selec], pch=2, cex=1/(0.5+x@dFP),  col = clustering[selec])
    points(x@FP[!selec], x@OR[!selec], cex=1/(0.5+x@dFP[!selec]),  col = clustering[!selec])
    legend("topright", legend=legend_text, pch=16, col=unique(clustering))
    }
  )

#' @name findDEgenes
#' @title Clustering of the potential differentially expressed (DE) genes 
#' @param object An object of \code{\link{ORdensity}} class.
#' @param numclusters By default \code{NULL}, it inherits from the \code{object}. Optionally,
#' an integer number indicating number of clusters.
#' @rdname findDEgenes
#' @docType methods
setGeneric("findDEgenes", function(object, numclusters=NULL) standardGeneric("findDEgenes"))
#' @title findDEgenes
#' @description This function clusters the potential differentially expressed (DE) genes among them 
#' so that the real DE genes can be distinguished from the not DE genes.
#' @param object An object of \code{\link{ORdensity}} class.
#' @param numclusters By default \code{NULL}, it inherits from the \code{object} parameter. 
#' Optionally, an integer number indicating number of clusters.
#' @return  A list composed by \eqn{k} lists where \eqn{k} is the best number of clusters found. 
#' The clusters are ordered based on their importance according to the mean OR values of the clusters 
#' (the greater the mean OR value of the cluster the more important are the genes in the cluster).
#' The first one is the most important, the last one the less important. Each list has elements:
#' \itemize{
#' \item \code{numberOfGenes}: Number of genes in the cluster.
#' \item \code{CharacteristicsCluster}: Matrix with mean values and standard deviation of variables OR, FP and dFP for each cluster.
#' \item \code{Genes}: Identification of the genes in the cluster.
#' }
#' @examples
#' # Read data from 2 experimental conditions
#' simexpr_reduced <- simexpr[c(1:15,101:235),]
#' x <- simexpr_reduced[, 3:32]
#' y <- simexpr_reduced[, 33:62]
#' EXC.1 <- as.matrix(x)
#' EXC.2 <- as.matrix(y)
#' myORdensity <- new("ORdensity", Exp_cond_1 = EXC.1, Exp_cond_2 = EXC.2, B = 20)
#' out <- findDEgenes(myORdensity)
#' # For instance, characteristics of cluster1, likely composed of true DE genes 
#' out[[1]]
#' # It is also possible to choose the number of clusters
#' out <- findDEgenes(myORdensity, 5)
#' @rdname findDEgenes
#' @docType methods
#' @export
setMethod("findDEgenes",
          signature = "ORdensity",
          definition = function(object, numclusters=NULL){
            KForClustering <- object@bestKclustering
            if (!is.null(numclusters))
            {
              KForClustering <- numclusters
            }
            prop <- object@out$prop
            neighbours <- prop[3]
            p0 <- prop[2]
            preclustered_data <- as.data.frame(object@out$summary)
            preclustered_data$DifExp <- NULL
            preclustered_data$minFP <- NULL
            preclustered_data$maxFP <- NULL
            preclustered_data$radius <- NULL
            preclustered_data$Strong <- ifelse(preclustered_data$FP == 0, "S", "-")
            preclustered_data$Relaxed <- ifelse(preclustered_data$FP < p0 * neighbours, "R", "-")
	    d <- distances::distances(scale(object@char))
            clustering <- cluster::pam(d[1:(dim(d)[2]), 1:(dim(d)[2])], KForClustering, diss = TRUE)$clustering
            result_prov <- list()
            meanOR <- list()
            for (k in 1:KForClustering)
            {
              result_prov[[k]] <- preclustered_data[clustering==k,]
              result_prov[[k]] <- result_prov[[k]][,!colnames(result_prov[[k]]) %in% c("DifExp",  "minFP", "maxFP", "radius")]
              meanOR[[k]] <- mean(result_prov[[k]][,'OR'])
            }
            clusters_ordering <- order(as.numeric(meanOR), decreasing = TRUE)
            clusters <- list()
            for (k in 1:KForClustering)
            {
              clusters[[k]] <- result_prov[[clusters_ordering[k]]]
            }
            prop <- object@out$prop
            neighbours <- prop[3]
            p0 <- prop[2]
            cat("The ORdensity method has found that the optimal clustering of the data consists of", object@bestKclustering,"clusters\n\n")
            return(list("neighbours"=neighbours, "expectedFalsePositiveNeighbours"=p0*neighbours, "clusters"=clusters))
          }
)

getQuantilesDifferencesWeighted <- function(positiveCases, negativeCases, scale, weights, probs){
  numGenes <- dim(positiveCases)[1]
  quantilesPositiveCases <- t(apply(positiveCases, 1, quantile, probs=probs))
  quantilesNegativeCases <- t(apply(negativeCases, 1, quantile, probs=probs))
  quantilesDifferences <- cbind(quantilesPositiveCases - quantilesNegativeCases)
  numProbs <- length(probs)
  if(scale){
    interquartileRangePositiveCases <- quantilesPositiveCases[,3]-quantilesPositiveCases[,1]
    interquartileRangeNegativeCases  <- quantilesNegativeCases[,3]-quantilesNegativeCases[,1]
    maxInterquartileRange <- apply(cbind(interquartileRangePositiveCases, interquartileRangeNegativeCases), 1, max)
    if(any(maxInterquartileRange==0))
    {stop('Can\'t scale the data')}
    quantilesDifferences <- quantilesDifferences/maxInterquartileRange
  }
  quantilesDifferencesWeighted <- quantilesDifferences*matrix(rep(weights, numGenes), byrow=TRUE, ncol=numProbs)
  return (quantilesDifferencesWeighted)
}

getBootstrapSample <- function(allCases, numPositiveCases)
{
  numCases <- dim(allCases)[2]
  s1 <- sample(1:numCases, numPositiveCases, replace=FALSE)
  s2 <- (1:numCases)[-s1]
  aux1 <- allCases[, s1]
  aux2 <- allCases[, s2]
  return(list("positives"=aux1, "negatives"=aux2))
}

getOR <- function(distMatrix)
{	
  # vgR <- Rfast::med(distMatrix^2)/2
  vgR <- (Rfast::med(distMatrix)^2)/2
  I <- apply(distMatrix, 1,  IindexRobust, vg=vgR)
  OR <- 1/I
  return(OR)
}

compute.ORdensity <-  function(object, B=100, scale=FALSE, alpha=0.05, fold=floor(B/10), probs=c(0.25, 0.5, 0.75), weights=c(1/4,1/2,1/4), numneighbours = 10, verbose=FALSE, 
                       parallel = FALSE, nprocs = 0, replicable = TRUE, seed = 0) {
	    a <- system.time ({
	    bootstrap_time_estimated <- FALSE
	      
	    positiveCases <- as.matrix(object@Exp_cond_1)
		  negativeCases <- as.matrix(object@Exp_cond_2)
		  numGenes <- dim(positiveCases)[1]
		  
		  cat("An object of size", format(object.size(1.0) * numGenes * numGenes / 7, unit="auto"), "is going to be created in memory. ")
		  cat("If the parallel option is enabled, as many objects of that size as the number of processes chosen ")
		  cat("are going to be created at the same time. Please consider that when running this code.\n")
		  
		  numPositiveCases <- dim(positiveCases)[2]
		  numNegativeCases <- dim(negativeCases)[2]
		  numCases <- numPositiveCases + numNegativeCases
		  numProbs <- length(probs)
		  numFolds <- fold})
	    
		  if (verbose) {print('Time after first chunk'); print(a)}

		  b <- system.time ({
		  quantilesDifferencesWeighted <- getQuantilesDifferencesWeighted(positiveCases, negativeCases, scale, weights, probs)
      })

		  if (verbose) {print('Time after second chunk'); print(b)}

		  c <- system.time ({
		    d <- distances::distances(quantilesDifferencesWeighted)
		    Dxy <- d[1:(dim(d)[2]), 1:(dim(d)[2])]
		    })

		  if (verbose) {print('Time after third chunk'); print(c)}

		  d2time <- system.time ({
		  allCases <- cbind(positiveCases, negativeCases)
		  ORbootstrap <- matrix(0, nrow=numGenes, ncol=B)
		  quantilesDifferencesWeighted.null <- array(0, dim=c(numGenes, numProbs, B))

		  if (parallel)
		  {
		    if (replicable){
		      set.seed(seed)
		    }
	    nproc <- parallel::detectCores()
      cl <- NULL
	    if (as.integer(nprocs) > 0)
	    {
	      # cl <- parallel::makeForkCluster(as.integer(nprocs)) # this only worked in Linux
	      cl <- parallel::makeCluster(as.integer(nprocs))
	    }
      else 
      {
        # cl <- parallel::makeForkCluster(nproc) # this only worked in Linux
        cl <- parallel::makeCluster(nproc)
      }
		  doParallel::registerDoParallel(cl)
      res_par <- foreach::foreach(b = 1:B, .combine = 'c', .options.RNG=seed) %dorng% {
        bootstrapSample <- getBootstrapSample(allCases, numPositiveCases)
  			res_one <- list()
  			res_one[[1]] <- getQuantilesDifferencesWeighted(bootstrapSample$positives, bootstrapSample$negatives, scale, weights, probs)
  			d <- distances::distances(res_one[[1]])
  			res_one[[2]] <- getOR(d[1:(dim(d)[2]), 1:(dim(d)[2])])
  			res_one
		  }
      parallel::stopCluster(cl)

      for (b in 1:B) {
        quantilesDifferencesWeighted.null[ , ,b] <- res_par[[b*2-1]]
        ORbootstrap[, b] <- res_par[[b*2]]
      }
		} # end if
		else
		{
		  if (replicable){
        set.seed(seed)
		  }
		  for (b in 1:B)
		  {
		    w <- system.time({
		      w1 <- system.time({
		    bootstrapSample <- getBootstrapSample(allCases, numPositiveCases)})
		      if (verbose) {print('Time after a non-parallel bootstrap replication (step 1)'); print(w1)}
		      w2 <- system.time({
		    quantilesDifferencesWeighted.null[ , ,b] <- getQuantilesDifferencesWeighted(bootstrapSample$positives, bootstrapSample$negatives, scale, weights, probs)})
		      if (verbose) {print('Time after a non-parallel bootstrap replication (step 2)'); print(w2)}
		      w3 <- system.time({
		        d <- distances::distances(quantilesDifferencesWeighted.null[,,b])
		       ORbootstrap[, b] <- getOR(d[1:(dim(d)[2]), 1:(dim(d)[2])])
		      if (verbose) {print('Time after a non-parallel bootstrap replication (step 3)'); print(w3)}
		    })
		    })
		    if (!bootstrap_time_estimated)
		    {
		      bootstrap_time_estimated <- TRUE
		      bootstrap_time <- w['elapsed']
		      cat("A bootstrap replication takes", bootstrap_time, "seconds, and you have requested", B, "bootstrap replications.\n")
		    }
		    if (verbose) {print('Time after a non-parallel bootstrap replication'); print(w)}
		  }
		}
   })
		  if (verbose) {print('Time after fourth chunk'); print(d2time)}

		# OR values for original data
		  e <- system.time ({
		  ORoriginal <- getOR(Dxy)

		# Find cut point
		   cutPoint <- (sort(c(ORbootstrap)))[floor((1-alpha)*numGenes*B)]

		# Find individuals beyond threshold
		   suspicious <- ORoriginal > cutPoint
		   numSuspicious <- sum(suspicious)

		   # the indices are in the form (case, bootstrap_sample)
		  indicesBiDimORbootstrapBeyondCutPoint <- which(ORbootstrap > cutPoint, arr.ind=TRUE)
		  
		  numORbootstrapBeyondCutPoint <- dim(indicesBiDimORbootstrapBeyondCutPoint)[1]
		  
		  # vector of integers (assigned fold) of size numGenes * B * alpha
		  assignFoldToBootstrapBeyondCutPoint <- sample(1:numFolds, numORbootstrapBeyondCutPoint, replace=TRUE) #
		  
		  # create a zero-filled 3D matrix with a 2D matrix of dim (numSuspicious, 3) for each fold
		  # created to store FPneighbourghood, densityFP and radius
		  originalDataFPStatistics <- array(0, dim=c(numSuspicious, 3, numFolds)) })

		  if (verbose) {print('Time after fifth chunk'); print(e)}

		  globalquantilesDifferencesWeighted.null <- quantilesDifferencesWeighted.null
		  
		  f <- system.time ({
		  for (j in 1:numFolds)
		  {
		    # for every fold, we see how is the distribution of the OR statistic along the boostrap samples and the original ones
		      currentFold <- assignFoldToBootstrapBeyondCutPoint == j
		      numInCurrentFold <- sum(currentFold)
		      quantilesBootstrapFold <- matrix(0, nrow=numInCurrentFold, ncol=numProbs)
		      cont <- 1
		      indicesBeyondCutPointCurrentFold <- (1:numORbootstrapBeyondCutPoint)[currentFold]
		      for (i in indicesBeyondCutPointCurrentFold)
		      {
  			   numGene <- indicesBiDimORbootstrapBeyondCutPoint[i, 1]
  			   numBootstrap <- indicesBiDimORbootstrapBeyondCutPoint[i, 2]
  			   quantilesBootstrapFold[cont, ] <- quantilesDifferencesWeighted.null[numGene, , numBootstrap]
  			   cont <- cont + 1
		      }
		      quantilesOriginalPlusBootstrapFold <- rbind(quantilesDifferencesWeighted[suspicious, ], quantilesBootstrapFold)
		      # after joining the original data with the bootstrap, we need the labels to find which is which
		      label <- c(rep(1, numSuspicious), rep(0, numInCurrentFold))

		      d <- distances::distances(quantilesOriginalPlusBootstrapFold)
		      Dmix <- d[1:(dim(d)[2]), 1:(dim(d)[2])]
		      originalDataFPStatisticsByFold <- matrix(0, nrow=numSuspicious, ncol=3)
		      colnames(originalDataFPStatisticsByFold) <- c( "FPneighbourghood", "densityFP", "radius")

		      DOriginal <- Dmix[1:numSuspicious, ]
		      for(i in 1:numSuspicious)
		      {
		        originalDataFPStatisticsByFold[i, ] <- c(density(DOriginal[i, -i], label=label[-i], numneighbours))
		      }
		      originalDataFPStatistics[ , , j] <- originalDataFPStatisticsByFold
		  } # end for (j in 1:numFolds)
		    })

		  if (verbose) {print('Time after sixth chunk'); print(f)}

		  g <- system.time ({
		    # means with respect to the folds
		    originalDataFPStatisticsMeans <- t(plyr::aaply(originalDataFPStatistics, c(2,1), mean))
		    originalDataFPNeighboursStats <- t(apply(originalDataFPStatistics[, 1, ], 1, function(x){c(min(x), mean(x), max(x))}))
		    percentageSuspiciousOverPositives <- numSuspicious/(numSuspicious+numORbootstrapBeyondCutPoint/numFolds)
		    percentageBoostrapOverPositives <- (numORbootstrapBeyondCutPoint/numFolds)/(numSuspicious+numORbootstrapBeyondCutPoint/numFolds)
		    
		    diffOverExpectedFPNeighbours <- originalDataFPStatisticsMeans[, 1] - percentageBoostrapOverPositives * numneighbours
		    labelGenes <- object@labels
		    genes <- labelGenes[suspicious]
		    finalResult <- data.frame("id"=genes, "OR"=ORoriginal[suspicious], "DifExp"=diffOverExpectedFPNeighbours,
		                              "minFP"=originalDataFPNeighboursStats[,1], "FP"= originalDataFPNeighboursStats[,2],
		                              "maxFP"=originalDataFPNeighboursStats[,3], "dFP"=originalDataFPStatisticsMeans[, 2],
		                              "radius"=originalDataFPStatisticsMeans[, 3])
		    finalResult$id <- as.character(finalResult$id)
		    row.names(finalResult) <- NULL
		    finalOrdering <- order(finalResult[, 3], -finalResult[, 2])
		   })

		   if (verbose) {print('Time after seventh chunk'); print(g)}

		   object@out <- list("summary"=finalResult[finalOrdering, ], "ns"=numSuspicious, "prop"=c(percentageSuspiciousOverPositives, percentageBoostrapOverPositives , numneighbours))
		}

setValidity("ORdensity", function(object) {
  valid <- TRUE
  msg <- NULL
  if (length(object@Exp_cond_1) == 0) {
    valid <- FALSE
    msg <- c(msg, "There is no Exp_cond_1 data")
  }
  if (length(object@Exp_cond_2) == 0) {
    valid <- FALSE
    msg <- c(msg, "There is no Exp_cond_2 data")
  }
  if (nrow(object@Exp_cond_1) != nrow(object@Exp_cond_2)) {
    valid <- FALSE
    msg <- c(msg, "Exp_cond_1 and Exp_cond_2 number of rows do not match")
  }
  if (length(probs) != length(weights)) {
    valid <- FALSE
    msg <- c(msg, "probs and weights lengths do not match")
  }
  if (valid) TRUE else msg
}
)

setMethod("initialize", "ORdensity", function(.Object, Exp_cond_1, Exp_cond_2, labels = rownames(Exp_cond_1), B=100, scale=FALSE, alpha=0.05, 
                                              fold=floor(B/10), probs=c(0.25, 0.5, 0.75), weights=c(1/4,1/2,1/4), numneighbours = 10, 
                                              numclustoseek = 10,
                                              out, OR, FP, dFP, char, bestKclustering, verbose = FALSE, 
                                              parallel = FALSE, nprocs = 0, replicable = TRUE, seed = 0) {
  .Object@Exp_cond_1 <- Exp_cond_1
  .Object@Exp_cond_2 <- Exp_cond_2
  if (is.null(labels))
  { 
    .Object@labels<- paste("Gene", 1:nrow(Exp_cond_1), sep="")
  }
  else
  {
    .Object@labels <- labels
  }
  .Object@B <- B
  .Object@scale <- scale
  .Object@alpha <- alpha
  .Object@fold <- fold
  .Object@probs <- probs
  .Object@weights <- weights
  .Object@numneighbours <- numneighbours
  .Object@numclustoseek <- numclustoseek
  .Object@verbose <- verbose
  .Object@parallel <- parallel
  .Object@nprocs <- nprocs
  .Object@replicable <- replicable
  .Object@seed <- seed
  .Object@out <- compute.ORdensity(.Object, B = .Object@B, scale = .Object@scale, alpha = .Object@alpha, fold = .Object@fold, 
                                   probs = .Object@probs, weights = .Object@weights, numneighbours = .Object@numneighbours,
                                   verbose = .Object@verbose, parallel = .Object@parallel, nprocs = .Object@nprocs, replicable = .Object@replicable, 
                                   seed = .Object@seed)
  .Object@OR <- .Object@out$summary[, "OR"]
  .Object@FP <- .Object@out$summary[, "FP"]
  .Object@dFP <- .Object@out$summary[, "dFP"]
  .Object@char <- data.frame(.Object@OR, .Object@FP, .Object@dFP)
  .Object@bestKclustering <- findbestKclustering(.Object)
  .Object
})

findbestKclustering <- function(object){
            s <- rep(NA, object@numclustoseek)
            # len(object@char) could be less than 10
            for (k in 2:object@numclustoseek)
            {
              d <- distances::distances(scale(object@char))
              aux <- cluster::pam(d[1:(dim(d)[2]), 1:(dim(d)[2])], k, diss = TRUE)
              s[k] <- mean(cluster::silhouette(aux)[, "sil_width"])
            }
            best_k <- which(s == max(s, na.rm = TRUE))
	    object@bestKclustering <- best_k
            return (best_k)
          }

density <- function(dx, label,  K=10)
{
  # false positive density in a K neighbors area
  # Input: 
  # dx0: distances from x0 to the rest of individual
  # label: label indicating whether suspicious (1) or null (0)
  # Output: density
  o <- order(dx)[1:K]
  r <- (dx[o])[K]
  # p <- sum(label[o]==0)/K
  p <- sum(label[o]==0)
  f <- p/r
  out <- c(p, f, r)
  out
}

IindexRobust <- function(di, vg){
   # I <- vg/Rfast::med(di^2)
   I <- vg/((Rfast::med(di))^2)
   I <- as.numeric(I)
   return(I)
   
 }

