
#' Backends : engines for p-value computation.
#' 
#' A backend is an S3 class which implments the methods \code{\link{pvals}}, \code{\link{cors}} and \code{\link{pvals_singleton}}. Different backends provide p-value computation under different scenarios (e.g. squared vs sum of squared correlations, Indpendence within Gene and SNP's) and may do complicated precomputations on the data matrices (\code{X} and \code{Y}) behind the scenes. Yet all of them provide a unified interface.
#' The methods below are constructors for the differnt backend objects and return an S3 object which implements pvalue methods listed above.
#' 
#' @examples 
#' X <- matrix(rnorm(100), nrow=10)
#' Y <- matrix(rnorm(50), nrow=10)
#' bk <- backend.indepNormal(X, Y)
#' #Calculate Y pvalues againt the X (column) subset {1,2..,7}
#' py <- pvals(bk, 1:7)
#' #Calculate X pvalues againt the Y (column) subset {2, 3}. Use global numbering.
#' px <- pvals(bk, 10 + c(2,3))
#'@name backend
NULL

#' Calculate p-values against a testing set.
#' 
#' Given a testing set B, return the p-values for the opposite side.
#' This is an S3 method that is implemented by all backends.
#' 
#' @param bk An object of class backend
#' @param B A set of either X or Y indices (using global numbering). The method calculates the pvalues from this set to the opposite side. 
#' 
#' @return The result is a vector of p-values of length ncol(X) or ncol(Y) depending on whether B is from Y or X respectively.
#' @seealso \code{\link{pvals_singleton}}
#'@export
pvals <- function(bk, B) {
  if (length(B) == 0) return(integer(0))
  UseMethod("pvals", bk)
}

#' Calculate p-values against a single variable.
#' 
#' Given a node return the p-values for the opposite side for the correlations to this node. This is supposed to be a special case of \code{\link{pvals}} (with a singleton set) but it is more faster and accurate.
#' 
#' @param bk An object of class backend
#' @param indx Either an X or Y indices (using global numbering).  
#' @return The result is a vector of p-values of length ncol(X) or ncol(Y) depending on whether indx is from Y or X respectively.
#' @seealso \code{\link{pvals}}
#' @export
pvals_singleton <- function(bk, indx) {
  #Given indx return the set of all p-values to opposite side. 
  #This is certainly a special case of pvals(b, A) with A = indx, but can be computed much faster since it does not involve sums of correlations.
  UseMethod("pvals_singleton", bk)
}

#' Calculate correlation vector from the set A
#' 
#' The backends typically have a faster way to implement this (using precomputations)
#' but this is roughly equivalent to \code{cor(X, Y[,A-dx])} if \code{min(A) > dx} else it is equal to \code{cor(Y, X[,A])}.
#' 
#' @param bk An object of class \link{backend}
#' @param A Either a subset of X or Y columns (in global numbering)
 #'@export
cors <- function(bk, A) {
  #calculate the correlations from set A.``
  UseMethod("cors", bk)
}

#' Masks the set B in future computations.
#' 
#' The p-vlaues corresponding to Bx, By will no longer need to calculated and 
#' will be returned as NA during future pvals call.  
#' 
#' 
#' @param bk An object of class backend
#' @param Bx A set of X indices 
#' @param By A set of Y indices (globally numbered)
#' 
#'@export
mask <- function(bk, Bx=c(), By=c()) {
  if(length(Bx) + length(By) > 0) {
    UseMethod("mask", bk)
  }
}

#' Initialization function
#' 
#' @param p backend
#' @param indx The node (in global numbering to initialize from)
#' @param alpha The cutoff to use for pvalues.
#' @param init_method One of c("conservative-BH", "non-conservative-BH", "BH-0.5", "no-multiple-testing") 
#'         gives the type of initializtion scheme.
#'@export
init <- function(p, indx, alpha, init_method) {
  pvals <- pvals_singleton(p, indx) 
  switch(init_method,
        "conservative-BH" = bh_reject(pvals, alpha, conserv = TRUE),
        "non-conservative-BH" = bh_reject(pvals, alpha, conserv = FALSE),
        "BH-0.5" =  bh_reject(pvals, 0.5, conserv = TRUE),
        "no-multiple-testing" = which(pvals <= alpha),
        stop(paste("Unknown init_method:", init_method))
  )
}

## Defaults
pvals_singleton.default <- function(bk, indx) {
  pvals(bk, indx)
}
