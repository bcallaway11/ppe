#' @title State-level Covid-19 Data
#'
#' @description A panel dataset containing Covid-19 related data for 46 states.  This data comes from Callaway and Li (2021).  See the paper for additional descriptions.
#'
#' @format A data frame with 1656 rows and 9 variables:
#' \describe{
#'   \item{positive}{The cumulative number of cases per million individuals in a particular state by a particular time period.}
#'   \item{time.period}{Time period}
#'   \item{group}{The group that a state belongs to.  It is based on the time
#'    period when they enacted the shelter-in-place order}
#'   \item{state}{State abbreviation}
#'   \item{totalTestResults}{The total Covid-19 number of tests run per million individuals in a particular state by a particular time period.}
#'   \item{state_id}{Numeric state identfier}
#'   \item{region}{Census region for particular state}
#'   \item{retail_and_recreation_percent_change_from_baseline}{The percentage
#'    change in retail and recreational travel from pre-Covid baseline.  This
#'    is from Google's Mobility report (see paper for details).}
#'   \item{current}{The current number of cases per million individuals in a
#'    particular state by a particular time period.  This variable is constructed
#'    from \code{positive} (see paper for details on how it is constructed).}
#' }
#' @source Callaway and Sant'Anna (2020)
"covid_data"
