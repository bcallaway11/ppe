#' @title matching_attgt
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
#'  data to have this format before the call to \code{matching_attgt}.
#'
#' @param gt_data data that is "local" to a particular group-time average
#'  treatment effect
#' @param xformla one-sided formula for covariates used in the propensity score
#'  and outcome regression models
#' @param matching_formula if provided, allows for the formula used to construct
#'  the matches to be different from the outcome regression
#' @param ret_imputations whether or not to return actual and imputed outcomes
#'  for the treated group
#' @param ... extra function arguments; not used here
#'
#' @return attgt_if
#'
#' @export
matching_attgt <- function(gt_data, xformla, matching_formula=xformla, ret_imputations=TRUE, ...) {

  #-----------------------------------------------------------------------------
  # handle covariates
  #-----------------------------------------------------------------------------
  # code to match on pre-treatment characteristics
  matching_res <- MatchIt::matchit(BMisc::toformula("D", BMisc::rhs.vars(matching_formula)),
                                   data=subset(gt_data, name=="pre"),
                                   replace=FALSE,
                                   distance="mahalanobis")
  Xpre <- get_matches(matching_res, data=subset(gt_data, name=="pre"), id="match_id")

  # convert two period panel into one period
  matched_gt_data <- subset(gt_data, id %in% unique(Xpre$id))
  matched_gt_data_outcomes <- tidyr::pivot_wider(matched_gt_data[,c("D", "id","period","name","Y")], id_cols=c(id, D),
                                           names_from=c(name),
                                           values_from=c(Y)) %>% as.data.frame()

  #-----------------------------------------------------------------------------
  # in order to cluster at the "match" level while allowing for the matches
  # to vary across periods (this is sorta complicated and matters in
  # pre-treatment periods), let's put the "entire" influence function (i.e.,
  # for both a treated unit and its match into the "spot" for the treated unit
  #-----------------------------------------------------------------------------
  disidx <- (unique(subset(gt_data, name=="pre")$id) %in% unique(matched_gt_data_outcomes$id)) & (subset(gt_data, name=="pre")$D==1)
  this_n <- length(unique(gt_data$id))
  matched_n <- length(unique(matched_gt_data_outcomes$id))

  # merge outcome and covariate data
  gt_dataX <- merge(matched_gt_data_outcomes, Xpre, by=c("id","D"))
  gt_dataX <- gt_dataX[order(gt_dataX$subclass, gt_dataX$D),]

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
  covmat2 <- covmat[D==0, , drop=FALSE]
  keep_covs <- apply(covmat2, 2, function(r) length(unique(r))!=1)
  keep_covs[1] <- TRUE # keep intercept
  covmat <- covmat[,keep_covs, drop=FALSE]
  attgt <- DRDID::reg_did_panel(y1=Y_post,
                                y0=rep(0,length(Y_post)),
                                D=D,
                                covariates=covmat,
                                inffunc=TRUE)

  # account for not using all observations in the influence function
  # and put "all" of influence function in for treated observations in
  # order to correctly cluster
  inf_func <- rep(0, nrow(subset(gt_data, name=="pre")))
  inf_func[disidx] <- (this_n/matched_n)*(attgt$att.inf.func[D==1] + attgt$att.inf.func[D==0])

  # optionally return imputations
  extra_gt_returns <- list()
  if (ret_imputations) {
    untreated_reg <- lm(BMisc::toformula("post", BMisc::rhs.vars(xformla)), data=subset(gt_dataX, D==0))
    actual <- Y_post[D==1]
    imputation <- predict(untreated_reg, newdata=subset(gt_dataX, D==1))
    extra_gt_returns <- list(actual=actual, imputation=imputation)
  }
  
  # return attgt
  pte::attgt_if(attgt=attgt$ATT, inf_func=inf_func, extra_gt_returns=extra_gt_returns)
}
