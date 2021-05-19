other_outcome_attgt <- function(gt_data, xformla, adjustI=TRUE, Iname, ...) {

  # organize data
  Xpre <- model.frame(xformla, data=subset(gt_data, name=="pre"))
  Ypost <- subset(gt_data, name=="post")$Y
  Ypre <- subset(gt_data, name=="pre")$Y
  Ipost <- subset(gt_data, name=="post")[,Iname]
  Ipre <- subset(gt_data, name=="pre")[,Iname]
  D <- subset(gt_data, name=="post")$D
  dY <- Ypost - Ypre
  dI <- Ipost - Ipre
  this.n <- length(Ypost)
  reg2by2.data <- cbind.data.frame(dY=dY, dI=dI, D=D)

  # first step estimation of parameters using untreated observations  
  first_step_reg <- lm(dY ~ dI, data=subset(reg2by2.data, D==0))
  thet <- coef(first_step_reg)[1]
  alp <- coef(first_step_reg)[2]
  first_step_if <- sandwich::estfun(first_step_reg) %*%
    sandwich::bread(first_step_reg)
  this.n0 <- nrow(first_step_if)
  this.n1 <- this.n - this.n0

  # second step estimation of effect of policy on current cases
  Xpre <- droplevels(Xpre)
  attgt_I <- DRDID::drdid_panel(y1=Ipost,
                                y0=Ipre,
                                D=D,
                                covariates=model.matrix(xformla,
                                                        data=Xpre),
                                inffunc=TRUE)

  # build up estimate of ATT
  this.p <- mean(D)

  mdI <- mean( D*(Ipost - Ipre) / this.p )
  delta_I0 <- mdI - attgt_I$ATT


  attgt <- mean( D*(Ypost - Ypre) / this.p ) - (thet + alp*delta_I0)

  #-----------------------------------------------------------------------------
  # influence function
  #-----------------------------------------------------------------------------

  # part coming from estimating parameters
  if1 <- matrix(data=0, nrow=this.n, ncol=ncol(first_step_if))
  if1[D==0,] <- first_step_if / (1-this.p) # no extra estimation effect of p here
  # from estimating cases
  if2a <-  as.matrix( D*(Ipost-Ipre)/this.p - mdI )
  if2b <- as.matrix(-(mdI/this.p) * (D - this.p))
  if2c <- attgt_I$att.inf.func
  if2 <- if2a + if2b - if2c

  # from estimating E[\Delta Y_t(0) | D=1]
  if3a <- alp*if2
  if3b <- as.matrix(if1[,1]) # inf.func for theta
  if3c <- as.matrix(delta_I0 * if1[,2]) # inf.func for alp
  if3 <- if3a + if3b + if3c

  # from estimating E[\Delta Y_t(1) | D=1]
  EdY <- mean(D*(Ypost-Ypre)/this.p)
  if4a <- D*(Ypost-Ypre)/this.p - EdY
  if4b <- as.matrix(-(EdY/this.p) * (D - this.p)) # from estimating p
  if4 <- if4a + if4b

  # overall influence function; from E[\Delta Y_t(1) | D=1] - \E[\Delta Y_t(0) | D=1]
  inf_func <- if4 - if3
  #V <- t(inf_func)%*%inf_func/n


  #-----------------------------------------------------------------------------
  # Alternatively: ignore that policy can effect cases
  #-----------------------------------------------------------------------------
  if (!adjustI) {
    # just take change in infections for treated group
    attgt <- mean( D*(Ypost - Ypre) / this.p ) - (thet + alp*mdI)

    # influence function is same as above except don't need to estimate/include ATT^I
    # only adjusting terms that are affected
    if2 <-  as.matrix( D*(Ipost-Ipre)/this.p - mdI )
    # - from estimating E[\Delta Y_t(0) | D=1]
    if3a <- alp*if2
    if3b <- as.matrix(if1[,1]) # inf.func for theta
    if3c <- as.matrix(delta_I0 * if1[,2]) # inf.func for alp
    if3 <- if3a + if3b + if3c

    # overall influence function
    inf_func <- if4 - if3
  }

  # return attgt and influence function
  pte::attgt_if(attgt=attgt, inf_func=inf_func)
}
