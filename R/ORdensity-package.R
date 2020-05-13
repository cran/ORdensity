#' @name ORdensity-package
#' @title Automated discovery of differentially expressed genes
#' @description ORdensity is a package for the automated discovery of differentially expressed genes.
#' It makes use of the ORdensity method and the associated FP and dFP values to detect the
#' most likely differentially expressed (DE) genes. The details of the method are explained 
#' in (Martínez-Otzeta, J. M. et al. 2020;  Irigoien, I., and Arenas, C. 2018).
#'
#' @author José María Martínez Otzeta \email{josemaria.martinezo@@ehu.eus}
#' @author Itziar Irigoien \email{itziar.irigoien@@ehu.eus}
#' @author Concepción Arenas \email{carenas@@ub.edu}
#' @author Basilio Sierra \email{b.sierra@@ehu.eus}

#' @references Irigoien, I. and Arenas, C. (2018)
#' Identification of differentially expressed genes by means of outlier detection.
#' \emph{BMC Bioinformatics}, 19:317
#' @references Martínez-Otzeta, J. M., Irigoien, I., Sierra, B., & Arenas, C. (2020). ORdensity: user-friendly R package to identify differentially expressed genes. \emph{BMC Bioinformatics}, 21, 1-10.
#'
#' @examples
#' # There is an example dataframe called simexpr shipped with the package. This data is the
#' # result of a simulation of 100 differentially expressed genes in a pool of 1000 genes. It
#' # contains 1000 observations of 62 variables. Each row correspond to a gene and contains 62 values:
#' # DEgen, gap and the values for the gene expression in 30 positive cases and in 30 negative cases. 
#' # The DEgen field value is 1 for differentially expressed genes and 0 for those which are not.
#' #
#' # First, let us extract the samples from each experimental condition from the simexpr database.
#' # For the sake of brevity, we will work with a subset of the database
#' # 
#' simexpr_reduced <- simexpr[c(1:15,101:235),]
#' x <- simexpr_reduced[, 3:32]
#' y <- simexpr_reduced[, 33:62]
#' EXC.1 <- as.matrix(x)
#' EXC.2 <- as.matrix(y)
#' #
#' # To create an S4 object to perform the analysis, follow this command
#' #
#' myORdensity <- new("ORdensity", Exp_cond_1 = EXC.1, Exp_cond_2 = EXC.2, B = 20)
#' #
#' # where B = 20 is the number of bootstraps replicates.
#' #
#' # A summary of the object can be generated with the summary function.
#' # 
#' summary(myORdensity)
#' # 
#' # The summary tells us the estimated optimal clustering of the data, and the number of genes in
#' # each cluster, along with their names. The clusters are ordered in decreasig order according to
#' # the value of the mean of the OR statistic. We see that the mean is higher in the first cluster 
#' # than in the second one, which means that the first cluster is more likely composed of true 
#' # differentially expressed genes, and the second one less likely. With any number of clusters, the
#' # last ones are likely false negatives.
#' #
#' # If the researcher just wants to extract the differentially expressed genes detected by the
#' # ORdensity method, a call to findDEgenes will return a list with the clusters found, along with
#' # the values of the OR statistic corresponding to each gene, and an indicator showing if the gene
#' # fulfil the strong and/or relaxed selection requirements. Following (Irigoien, I., and Arenas, C.
#' # 2018), two types of differentially expressed gene selection can be made:
#' #
#' # ORdensity strong selection: take as differentially expressed genes those with a large OR value
#' # and with FP and dFP equal to 0.
#' #
#' # ORdensity relaxed selection: take as differentially expressed genes those with a large OR
#' # value and with small FP and dFP values. As a reference to look for small values the expected
#' # number of false positive neighbours is computed.
#' #
#' # The motivation of the clustering is to distinguish those false positives that score high in OR
#' # and low in meanFP and density, but are similar to other known false positives obtained by
#' # bootstrapping. The procedure is detailed in (Irigoien, I., and Arenas, C. 2018) and it uses the 
#' # PAM cluster procedure.
#' #
#' # After running this code
#' #
#' result <- findDEgenes(myORdensity)
#' #
#' # the method indicated the numbers of clusters in the optimal clustering, and then we could look
#' # the results
#' #
#' result
#' #
#' # As a rule of thumb, differentially expressed genes are expected to present high values of OR
#' # and low values of meanFP and density. We could also analyze each gene individually inside each
#' # cluster. The motivation of the clustering is to distinguish those false positives that score 
#' # high in OR and low in meanFP and density, but are similar to other known false positives 
#' # obtained by boostrapping. The procedure is detailed in (Irigoien, I., and Arenas, C. 2018).
#' #
#' # If the researcher is interested in a more thorough analysis, other functions are at their service.
#' #
#' # The data before being clustered can be obtained with the following function
#' #
#' preclusteredData(myORdensity)
#' #
#' # A plot with a representation of the potential genes based on OR (vertical axis), FP (horizontal
#' # axis) and dFP (size of the circle is inversely proportional to its value) can also be obtained.
#' # Genes that fulfil the relaxed criterion are drawn with triangles.
#' #
#' plot(myORdensity)
#' #
#' # By default, the number of clusters computed by the ORdensity method is used. Other values for
#' # the number of clusters can be specified.
#' #
#' plot(myORdensity, numclusters = 5)

#' @rdname ORdensity-package
#' @aliases ORdensity-package
#' @docType package

NULL

