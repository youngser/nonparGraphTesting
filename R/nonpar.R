#' Nonparametric Random Graph Testing
#' @param A An adjacency matrix
#' @param B another adjacency matrix
#' @param d the (known) dimension
#' @export
nonpar <- function(A,B,d = 5) {
  Xhat <- ase(A,d)
  Yhat <- ase(B,d)
  result <- nonpar.test(Xhat,Yhat)
  return(result)
}

#' actually run the test
nonpar.test <- function(Xhat,Yhat) {
  #alignment step:
  Q <- match.support(Xhat, Yhat)
  Ynew <- Yhat %*% Q
  U <- kernel.stat(Xhat, Ynew)
  testresult <- run_perm_test(U,nsims,Xhat,Ynew)
  return(testresult)
}

#' Compute the Adjacency Spectral embedding
#' @param A a symmetric matrix
#' @param d the known dimension
#' @require irlba
#' @export
ase <- function(A,d ) {
  A_svd <- irlba(A,d)
  Xhat <- A_svd$u %*% diag(A_svd$d)^(1/2)
  return(Xhat)
}


#' Function to get pairwise distances.  
get_dist_matrix <- function(Z1,Z2,sigma = .5) {
  new_dat <- rbind(Z1,Z2)
  D1 <-exp(-(as.matrix(stats::dist(new_dat))^2)/(2*sigma^2))
  return(D1)
}

#' Function to get the distance.  Original code by Youngser Park.
rect.dist <- function(X,Y){
  X <- as.matrix(X)
  Y <- as.matrix(Y)
  n <- nrow(X)
  m <- nrow(Y)
  tmp1 <- X%*%t(Y)
  tmp2 <- outer(rep(1, n), rowSums(Y^2))
  tmp3 <- outer(rowSums(X^2), rep(1,m))
  D <- tmp2 - 2*tmp1 + tmp3
  D <- exp(-D/(2*(.5^2)))
  return(D)
}

#' Function to generate the U-statistic given the latent positions X and Y
#' and an optional choice of sigma.
#' Original code by Youngser Park.
kernel.stat <- function(X,Y,sigma=0.5,dist = NULL,i1=c(1:nrow(X)),
                        i2=c((nrow(X) + 1):(nrow(X)*2))){
  
  n <- nrow(X)
  m <- nrow(Y)
  
  if (is.null(dist)) {
    tmpXX <- sum(exp(-(as.matrix(stats::dist(X))^2)/(2*sigma^2))) 
    tmpYY <- sum(exp(-(as.matrix(stats::dist(Y))^2)/(2*sigma^2)))
    tmpXY <- sum(exp(-(rect.dist(X,Y))/(2*sigma^2)))
    
    tmp <- tmpXX/(n*(n-1)) + tmpYY/(m*(m-1)) - 2*tmpXY/(m*n)
    
    return((m+n)*tmp)
  } else {
    tmpXX <- sum(dist[i1,i1])
    tmpYY <-  sum(dist[i2,i2])
    tmpXY <- sum(dist[i1,i2])
    tmp<- tmpXX /(n*(n-1)) +tmpYY/(m*(m-1)) - 2*tmpXY/(m*n)
    return((m+n)*tmp)
  }
  
  
}


#' Helper function for a normalizing constant.
get_s <- function(X) {
  return((1/nrow(X)^(.5))*norm(X,"F"))
}

#' Runs the permutation test given the value of the U-statistic
#' the number of repetitions, and the estimated latent positions
#' Code written in Fall of 2018, so may be buggy
#' @param U
#' @param nxims
#' @param X
#' @param Y
#' @param dist.mat Optional, a distance matrix precalculated already so as not to recalculate.
#' If null, the function is recursively run to calculate it
#' @return an estimated p-value under the null.
run_perm_test <- function(U,nsims,X,Y,dist.mat = NULL) {
  toReturn <- rep(-1.0,nsims)
  for (i in 1:nsims) {
    #cat(i," out of ",nsims,"\r")
    indices_1 <- sample(c(1:(nrow(X)*2)),size=nrow(X),replace = FALSE)
    indices_2 <- setdiff( c(1:(nrow(X)*2)), indices_1 )
    
    if(is.null(dist.mat)) {
      Xnew <- X[indices_1,]
      Ynew <- Y[indices_2,]
      sx <- get_s(Xnew)
      sy <- get_s(Ynew)
      Uhat <- kernel.stat(Xnew/sx,Ynew/sy)
    } else {
      Uhat <- kernel.stat(X=X,Y=Y,i1=indices_1,i2=indices_2,dist=dist.mat)
    }
    if (Uhat > U) {
      toReturn[i] <- 1.0
    } else {
      toReturn[i] <- 0.0
    }
  }
  
  return(sum(toReturn)/length(toReturn))
  
}










