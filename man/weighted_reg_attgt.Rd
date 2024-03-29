% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/weighted_reg_attgt.R
\name{weighted_reg_attgt}
\alias{weighted_reg_attgt}
\title{weighted_reg_attgt}
\usage{
weighted_reg_attgt(
  gt_data,
  xformla,
  weighting_method = "ps",
  ret_imputations = TRUE,
  ...
)
}
\arguments{
\item{gt_data}{data that is "local" to a particular group-time average
treatment effect}

\item{xformla}{one-sided formula for covariates used in the propensity score
and outcome regression models}

\item{weighting_method}{optional argument for type of weights to compute using
WeightIt::weightit}

\item{ret_imputations}{whether or not to return actual and imputed outcomes
for the treated group}

\item{...}{extra function arguments; not used here}
}
\value{
attgt_if
}
\description{
Takes a "local" data.frame and computes
an estimate of a group time average treatment effect
and a corresponding influence function.

The code relies on \code{this.data} having certain variables defined.
In particular, there should be an \code{id} column (individual identifier),
\code{G} (group identifier), \code{period} (time period), \code{name}
(equal to "pre" for pre-treatment periods and equal to "post" for post
treatment periods), \code{Y} (outcome).

In our case, we call \code{pte::two_by_two_subset} which sets up the
data to have this format before the call to \code{weighted_reg_attgt}.
}
