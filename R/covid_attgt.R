#' @title covid_attgt
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
#'  data to have this format before the call to \code{covid_attgt}.
#'
#' @param gt_data data that is "local" to a particular group-time average
#'  treatment effect
#' @param xformla one-sided formula for covariates used in the propensity score
#'  and outcome regression models
#' @param ... extra function arguments; not used here
#'
#' @return attgt_if
#'
#' @export
covid_attgt <- function(gt_data, xformla, d_outcome=FALSE, d_covs_formula=~-1, ...) {

  #-----------------------------------------------------------------------------
  # handle covariates
  #-----------------------------------------------------------------------------
  
  # pre-treatment covariates
  Xpre <- model.frame(xformla, data=subset(gt_data,name=="pre"))

  # change in covariates
  dX <- model.frame(d_covs_formula, data=subset(gt_data,name=="post")) - model.frame(d_covs_formula, data=subset(gt_data,name=="pre"))
  if (ncol(dX) > 0) colnames(dX) <- paste0("d", colnames(dX))

  # convert two period panel into one period
  gt_data_outcomes <- tidyr::pivot_wider(gt_data[,c("D","id","period","name","Y")], id_cols=c(id, D),
                                           names_from=c(name),
                                           values_from=c(Y))

  # merge outcome and covariate data
  gt_dataX <- cbind.data.frame(gt_data_outcomes, Xpre, dX)

  # treatment dummy variable
  D <- gt_dataX$D

  # post treatment outcome
  Y <- gt_dataX$post

  if (d_outcome) Y <- gt_dataX$post - gt_dataX$pre

  # estimate attgt
  # DRDID::drdid_panel is for panel data, but we can hack it
  # to work in levels by just setting outcomes in "first period"
  # to be equal to 0 for all units
  gt_dataX <- droplevels(gt_dataX)
  use_formula <- BMisc::toformula("", c(BMisc::rhs.vars(xformla), colnames(dX)))
  covmat <- model.matrix(use_formula, data=gt_dataX)
  covmat2 <- covmat[D==0,]
  #www <- gt_dataX[D==0,]$.w
  n_unt <- sum(1-D)
  precheck_reg <- qr(t(covmat2)%*%covmat2/n_unt)
  keep_covs <- precheck_reg$pivot[1:precheck_reg$rank]
  covmat <- covmat[,keep_covs]
  attgt <- DRDID::drdid_panel(y1=Y,
                                y0=rep(0,length(Y)),
                                D=D,
                                covariates=covmat,      
                                inffunc=TRUE)

  # return attgt
  pte::attgt_if(attgt=attgt$ATT, inf_func=attgt$att.inf.func)
}
