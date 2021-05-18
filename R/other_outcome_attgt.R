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
  #V <- t(first_step_if) %*% first_step_if / n
  #se <- sqrt(diag(V))/sqrt(n)
  
  # convert two period panel into one period
  ## this.data_outcomes <- tidyr::pivot_wider(gt_data[,c("G","id","period","name","current")], id_cols=c(id, G),
  ##                                          names_from=c(name),
  ##                                          values_from=c(current))

  # merge outcome and covariate data
  # this.dataOR <- cbind.data.frame(this.data_outcomes, Xor)
  # this.dataPscore <- cbind.data.frame(this.data_outcomes, Xpscore)

  # this.dataPscore <- droplevels(this.dataPscore)
  Xpre <- droplevels(Xpre)
  attgt_I <- DRDID::drdid_panel(y1=Ipost,
                                y0=Ipre,
                                D=D,
                                covariates=model.matrix(xformla,
                                                        data=Xpre),
                                inffunc=TRUE)

  this.p <- mean(D)

  mdI <- mean( D*(Ipost - Ipre) / this.p )
  delta_I0 <- mdI - attgt_I$ATT


  attgt <- mean( D*(Ypost - Ypre) / this.p ) - (thet + alp*delta_I0)

  # build influence function
  # - from estimating parameters
  if1 <- matrix(data=0, nrow=this.n, ncol=ncol(first_step_if))
  if1[D==0,] <- first_step_if / (1-this.p) # no extra estimation effect of p here
  # - from estimating cases
  if2a <-  as.matrix( D*(Ipost-Ipre)/this.p - mdI )
  if2b <- as.matrix(-(mdI/this.p) * (D - this.p))
  if2c <- attgt_I$att.inf.func
  if2 <- if2a + if2b - if2c
  # - from estimating E[\Delta Y_t(0) | D=1]
  if3a <- alp*if2
  if3b <- as.matrix(if1[,1]) # inf.func for theta
  if3c <- as.matrix(delta_I0 * if1[,2]) # inf.func for alp
  if3 <- if3a + if3b + if3c
  # - from estimating E[\Delta Y_t(1) | D=1]
  EdY <- mean(D*(Ypost-Ypre)/this.p)
  if4a <- D*(Ypost-Ypre)/this.p - EdY
  if4b <- as.matrix(-(EdY/this.p) * (D - this.p)) # from estimating p
  if4 <- if4a + if4b

  # overall influence function; from E[\Delta Y_t(1) | D=1] - \E[\Delta Y_t(0) | D=1]
  inf_func <- if4 - if3
  #V <- t(inf_func)%*%inf_func/n

  ## # create local treated variable
  ## this.dataPscore$D <- 1*(this.dataPscore$G==g)

  ## # run the outcome regression,
  ## # note: this is regression of change on covariates (which makes sense given structure of model in paper)
  ## or_formla <- BMisc::toformula("I(post-pre)", BMisc::rhs.vars(or_xformla))
  ## outcome_regression <- lm(or_formla,data=subset(this.dataOR, (G > g | G == 0)))
  ## # and get predicted values
  ## or_preds <- predict(outcome_regression, newdata=this.dataOR)

  ## # run the pscore regression
  ## pscore_formla <- BMisc::toformula("D", c(BMisc::rhs.vars(pscore_xformla)))
  ## pscore_reg <- glm(pscore_formla, data=this.dataPscore, family=binomial(link=logit) )
  ## pscore_preds <- predict(pscore_reg, type="response")

  ## # treatment dummy variable
  ## D <- this.dataPscore$D

  ## # compute weights
  ## #w1 <- D/mean(D)
  ## w2a <- (1-D)*pscore_preds/(1-pscore_preds)
  ## w2 <- w2a / mean(w2a)
  ## #w <- w1 - w2
  ## dI <- this.dataOR$post - this.dataOR$pre

  # doubly robust  version / don't think this works...
  # EdI <- mean(w2 * (dI - or_preds) )

  # pscore weighting version
  #EdI <- mean(w2 * dI)

  # if we ignore that policy can effect
  # infections
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

  attgt_if(attgt=attgt, inf_func=inf_func)
}
