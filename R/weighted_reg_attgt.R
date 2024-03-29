#' @title weighted_reg_attgt
#'
#' @description Takes a "local" data.frame and computes
#'  an estimate of a group time average treatment effect
#'  and a corresponding influence function.
#'
#'  The code relies on \code{this.data} having certain variables defined.
#'  In particular, there should be an \code{id} column (individual identifier),
#'  \code{G} (group identifier), \code{period} (time period), \code{name}
#'  (equal to "pre" for pre-treatment periods and equal to "post" for post
#'  treatment periods), \code{Y} (outcome).
#'
#'  In our case, we call \code{pte::two_by_two_subset} which sets up the
#'  data to have this format before the call to \code{weighted_reg_attgt}.
#'
#' @param gt_data data that is "local" to a particular group-time average
#'  treatment effect
#' @param xformla one-sided formula for covariates used in the propensity score
#'  and outcome regression models
#' @param weighting_method optional argument for type of weights to compute using
#'  WeightIt::weightit
#' @param ret_imputations whether or not to return actual and imputed outcomes
#'  for the treated group
#' @param ... extra function arguments; not used here
#'
#' @return attgt_if
#'
#' @export
weighted_reg_attgt <- function(gt_data, xformla, weighting_method="ps", ret_imputations=TRUE, ...) {

  #-----------------------------------------------------------------------------
  # handle covariates
  #-----------------------------------------------------------------------------
  # code to match on pre-treatment characteristics
  wres <- WeightIt::weightit(BMisc::toformula("D",
                                              BMisc::rhs.vars(xformla)),
                             data=subset(gt_data, name=="pre"),
                             estimand="ATT",
                             method=weighting_method,
                             stabilize=TRUE)

  gt_data_outcomes <- tidyr::pivot_wider(gt_data[,c("D", "id","period","name","Y")], id_cols=c(id, D),
                                         names_from=c(name),
                                         values_from=c(Y)) %>% as.data.frame()

  Xpre <- model.frame(xformla, data=subset(gt_data,name=="pre"))

  # merge outcome and covariate data
  gt_dataX <- cbind.data.frame(gt_data_outcomes, Xpre)
  gt_dataX$.w <- wres$weights

  # treatment dummy variable
  D <- gt_dataX$D

  # post treatment outcome
  Y_post <- gt_dataX$post

  # estimate attgt
  # DRDID::reg_did_panel is for panel data, but we can hack it
  # to work in levels by just setting outcomes in "first period"
  # to be equal to 0 for all units
  gt_dataX <- droplevels(gt_dataX)
  # drop covariates that are constant across all observations
  # this is a bit of a hack for covid project but shouldn't
  # cause issues generally...I think
  covmat <- model.matrix(xformla, data=gt_dataX)
  covmat2 <- covmat[D==0,]
  www <- gt_dataX[D==0,]$.w
  n_unt <- sum(1-D)
  precheck_reg <- qr(t(www*covmat2)%*%covmat2/n_unt)
  keep_covs <- precheck_reg$pivot[1:precheck_reg$rank]
  covmat <- covmat[,keep_covs]
  attgt <- DRDID::reg_did_panel(y1=Y_post,
                                y0=rep(0,length(Y_post)),
                                D=D,
                                covariates=covmat,
                                i.weights=gt_dataX$.w,
                                inffunc=TRUE)


  # optionally return imputations
  extra_gt_returns <- list()
  if (ret_imputations) {
    untreated_reg <- lm(BMisc::toformula("post", BMisc::rhs.vars(xformla)), data=subset(gt_dataX, D==0), weights=.w)
    actual <- Y_post[D==1]
    imputation <- predict(untreated_reg, newdata=subset(gt_dataX, D==1))
    extra_gt_returns <- list(actual=actual, imputation=imputation)
  }
    
  
  # return attgt
  pte::attgt_if(attgt=attgt$ATT, inf_func=attgt$att.inf.func, extra_gt_returns=extra_gt_returns)
}
