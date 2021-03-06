# base is a backend which implements pvlas_singleton and cors. The other backends can use that if required.

#' An incomplete backend.
#' 
#' Other backends build on this. See and use \link{backend} instead.
#' 
#' @param X Matrix. The data vector for the X side
#' @param Y Matrix. The data vector for the Y side
#' @param calc_full_cor Logical. Should it calculate the \code{c(ncol(X),ncol(Y))} dimensional correlation matrix or not? Calculating this matrix upfront makes the pvalue computation faster but it also takes up lot of memory.
backend.base <- function(X, Y, calc_full_cor=TRUE){
  #Thes precomputations are stored to compute pvals_singleton for objects of type base, and store useful settings.
  p <- list(full_xy_cor = if (calc_full_cor) stats::cor(X,Y) else NULL,
            calc_full_cor = calc_full_cor,
            dx = ncol(X), n = nrow(X),
            X = scale(X), Y = scale(Y),
            two_sided = FALSE) 
  class(p) <- "base"
  p
}


cors.base <- function(p, A){
  #When p is of class base, calculate the correlations from set A.
  if (p$calc_full_cor) {
    if (min(A) > p$dx) {
      #A is in the Y set
      return(p$full_xy_cor[, A - p$dx, drop = FALSE])
    } else {
      #A is in the X set
      return(t(p$full_xy_cor[A, , drop = FALSE]))
    }    
  } else {
    if (min(A) > p$dx) {
      return(crossprod(p$X, p$Y[, A - p$dx, drop = FALSE])/(p$n - 1))
    } else {
      return(crossprod(p$Y, p$X[, A, drop = FALSE])/(p$n - 1))
    }
  }
}

pvals_singleton.base <- function(p, indx) {
  # An easy way to calculate p-values from an indx
  fischer_tranformed_cor <- atanh(as.vector(cors(p, indx))) * sqrt(p$n - 3)
  if (p$two_sided) {
    pvals <- 2 * stats::pnorm(abs(fischer_tranformed_cor), lower.tail = FALSE)
  } else {
    pvals <- stats::pnorm(fischer_tranformed_cor, lower.tail = FALSE)
  }
  return(pvals)
}

