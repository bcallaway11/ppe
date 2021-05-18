
<!-- README.md is generated from README.Rmd. Please edit that file -->

# Pandemic Policy Evaluation (ppe) package

The `ppe` package contains code for estimating policy effects during the
pandemic. It is the companion code for [Callaway and Li (2021). Policy
Evaluation during a Pandemic](https://arxiv.org/abs/2105.06927). The
central idea of that paper is to compare locations who implemented some
policy to other locations that did not implement the policy *and that
had the same pre-treatment values of Covid-19 related characteristics*.
These characteristics definitely include (i) the current number of cases
and (ii) the number of susceptible individuals (or equivalently the
cumulative number of cases). They might also include demographic
characteristics, population densities, region of the country, among
others.

This amounts to an unconfoundedness-type strategy. In the paper, we
compare it to a difference in differences strategy and argue that the
unconfoundedness strategy is likely to be more appropriate to evaluate
policies during the pandemic. The rationale for this argument is that
epidemic models from the epidemiology literature are highly nonlinear
but do not involve individual-level unobserved heterogeneity. See our
[five minute
summary](https://bcallaway11.github.io/posts/five-minute-pandemic-policy)
for additional discussion along these lines.

In practice, we use a doubly robust estimation procedure that estimates
both the propensity score (which is related to the treatment assigment
model) and an outcome regression for untreated potential outcomes (which
is related to the epidemic model). An important advantage of this is
that, at least to some extent, it allows us to side-step the issue of
estimating a full epidemic model.

To demonstrate our approach, we provide a shortened version of the
application from our paper which is about the effect of shelter-in-place
orders early in the pandemic. We have state-level data about Covid-19
cases, tests, and the timing when a state adopted a shelter-in-place
order.

``` r
# load the data
data(covid_data)

# formula for covariates
xformla <- ~ current + current^2 + current^3 + region + totalTestResults
```

A first issue is that there are major overlap violations — for example,
there are just not good comparison states for New York. As a first step,
we drop those:

``` r
trim_id_list <- lapply(c(10,15,20,25,30),
                       did::trimmer,
                       tname="time.period",
                       idname="state_id",
                       gname="group",
                       xformla=xformla,
                       data=covid_data,
                       control_group="nevertreated",
                       threshold=0.95)
time_id_list <- unlist(trim_id_list)
```

``` r
# states that we will drop
unique(subset(covid_data, state_id %in% time_id_list)$state)
#>  [1] "AL" "CA" "CT" "FL" "GA" "IL" "LA" "ME" "MI" "MO" "MS" "NH" "NJ" "NY" "PA"
#> [16] "RI" "SC" "TX" "VT" "WA"
covid_data2 <- subset(covid_data, !(state_id %in% time_id_list))
```

Next, we use the [`pte`](https://github.com/bcallaway11/pte) package to
estimate policy effects. This basically involves us only having to write
a new function to compute group-time average treatment effects — for us,
it is the function
[`covid_attgt`](https://github.com/bcallaway11/ppe/blob/master/R/covid_attgt.R)
(which is essentially just a function to compute doubly robust treatment
effect estimates under unconfoundedness and that include lags of some
variables).

``` r
res <- pte(yname="positive",
           gname="group",
           tname="time.period",
           idname="state_id",
           data=covid_data2,
           subset_fun=two_by_two_subset,
           attgt_fun=covid_attgt,
           xformla=xformla,
           max_e=21,
           min_e=-10) 
#> Warning in compute.aggte(MP = MP, type = type, balance_e = balance_e, min_e
#> = min_e, : Simultaneous conf. band is somehow smaller than pointwise one
#> using normal approximation. Since this is unusual, we are reporting pointwise
#> confidence intervals

summary(res)
#> 
#> Overall ATT:  
#>      ATT    Std. Error     [ 95%  Conf. Int.] 
#>  74.0998        60.006   -43.5097    191.7093 
#> 
#> 
#> Dynamic Effects:
#>  Event Time Estimate Std. Error     [95%  Conf. Band] 
#>         -10  -4.4309     2.5550  -11.2550      2.3932 
#>          -9   0.6468     1.7060   -3.9098      5.2034 
#>          -8  -1.0199     1.7757   -5.7627      3.7229 
#>          -7   4.9369     2.0641   -0.5763     10.4500 
#>          -6   2.7974     1.5456   -1.3307      6.9256 
#>          -5   3.3207     3.8055   -6.8433     13.4848 
#>          -4   2.2912     4.3123   -9.2265     13.8089 
#>          -3  -0.3394     4.0420  -11.1351     10.4563 
#>          -2  -1.8006     2.2299   -7.7565      4.1553 
#>          -1   1.2608     3.5842   -8.3123     10.8339 
#>           0  -4.0483     4.6231  -16.3961      8.2995 
#>           1  -2.8472     6.5810  -20.4245     14.7301 
#>           2   4.6124     7.7951  -16.2076     25.4324 
#>           3   8.6060     8.8539  -15.0420     32.2540 
#>           4  10.9207     9.9851  -15.7484     37.5899 
#>           5  20.6761    15.0041  -19.3984     60.7506 
#>           6  18.3053    17.0761  -27.3031     63.9138 
#>           7  23.3457    23.2140  -38.6566     85.3480 
#>           8  29.1808    26.7806  -42.3474    100.7090 
#>           9  34.8426    26.5899  -36.1763    105.8614 
#>          10  46.7525    35.3865  -47.7613    141.2663 
#>          11  54.3023    34.4062  -37.5933    146.1978 
#>          12  63.0487    45.0843  -57.3668    183.4643 
#>          13  66.3826    52.9943  -75.1598    207.9249 
#>          14  72.4041    58.6302  -84.1910    228.9993 
#>          15  92.5038    65.0698  -81.2909    266.2984 
#>          16  75.2222    82.0603 -143.9523    294.3968 
#>          17  92.4658    71.2626  -97.8693    282.8010 
#>          18  90.5871   100.6468 -178.2302    359.4044 
#>          19 100.4617    93.7348 -149.8945    350.8178 
#>          20 100.4475   124.9396 -233.2534    434.1484 
#>          21  98.0003   140.0528 -276.0663    472.0669 
#> ---
#> Signif. codes: `*' confidence band does not cover 0
```

and we can also plot the results in event study.

``` r
plot_df <- summary(res)$event_study
colnames(plot_df) <- c("e", "att", "se", "cil", "ciu")
plot_df$post <- as.factor(1*(plot_df$e >= 0))
ggplot(plot_df, aes(x=e, y=att)) +
  geom_line(aes(color=post)) +
  geom_point(aes(color=post)) + 
  geom_line(aes(y=ciu), linetype="dashed", alpha=0.5) +
  geom_line(aes(y=cil), linetype="dashed", alpha=0.5) +
  ylim(c(-1000,1000)) +
  theme_bw() +
  theme(legend.position="bottom")
```

![](man/figures/README-unnamed-chunk-7-1.png)<!-- -->
