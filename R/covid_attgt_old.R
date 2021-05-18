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
#' @param this.data data that is "local" to a particular group-time average
#'  treatment effect
#' @param xformla one-sided formula for covariates used in the propensity score
#'  and outcome regression models
#' @param ... extra function arguments; not used here
#'
#' @return attgt_if
#'
#' @export
covid_attgt <- function(this.data, xformla, ...) {

  #-----------------------------------------------------------------------------
  # handle covariates
  #-----------------------------------------------------------------------------
  # for outcome regression, get pre-treatment values
  Xor <- model.frame(xformla, data=subset(this.data,name=="pre"))
  # for pscore, get pre-treatment values
  Xpscore <- model.frame(xformla, data=subset(this.data,name=="pre"))

  # convert two period panel into one period
  this.data_outcomes <- tidyr::pivot_wider(this.data[,c("G","id","period","name","Y")], id_cols=c(id, G),
                                           names_from=c(name),
                                           values_from=c(Y))

  # merge outcome and covariate data
  this.dataOR <- cbind.data.frame(this.data_outcomes, Xor)
  this.dataPscore <- cbind.data.frame(this.data_outcomes, Xpscore)

  # create local treated variable
  this.dataPscore$D <- 1*(this.dataPscore$G==g)

  # run the outcome regression,
  # note: this is regression of change on covariates (which makes sense given structure of model in paper)
  or_formla <- BMisc::toformula("I(post-pre)", BMisc::rhs.vars(xformla))
  outcome_regression <- lm(or_formla, data=this.dataOR)
  # and get predicted values
  # note: add back in pre-treatment outcomes so that this
  # is prediction for the level of outcomes in post-treatment
  # period
  or_preds <- predict(outcome_regression, newdata=this.dataOR) + this.dataOR$pre

  # run the pscore regression
  pscore_formla <- BMisc::toformula("D", c(BMisc::rhs.vars(xformla)))

  # treatment dummy variable
  D <- this.dataPscore$D

  # post treatment outcome
  Y_post <- this.dataOR$post

  # estimate attgt
  # DRDID::drdid_panel is for panel data, but we can hack it
  # to work in levels by just setting outcomes in "first period"
  # to be equal to 0 for all units
  this.dataPscore <- droplevels(this.dataPscore)
  attgt <- DRDID::drdid_panel(y1=Y_post,
                              y0=rep(0,length(Y_post)),
                              D=D,
                              covariates=model.matrix(pscore_formla,
                                                      data=this.dataPscore),
                              inffunc=TRUE)

  # return attgt
  attgt_if(attgt=attgt$ATT, inf_func=attgt$att.inf.func)
}
