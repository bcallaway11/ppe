
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
xformla <- ~ current + I(current^2) + I(current^2) + region + totalTestResults
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
#>  [1] "AL" "CA" "CO" "CT" "FL" "GA" "IL" "LA" "ME" "MI" "MO" "MS" "NH" "NJ" "NY"
#> [16] "PA" "RI" "SC" "TX" "VT" "WA"
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

summary(res)
#> 
#> Overall ATT:  
#>      ATT    Std. Error     [ 95%  Conf. Int.] 
#>  14.8882       75.3544  -132.8038    162.5801 
#> 
#> 
#> Dynamic Effects:
#>  Event Time Estimate Std. Error     [95%  Conf. Band] 
#>         -10  -3.7266     3.8360  -14.1967      6.7435 
#>          -9   2.6607     1.2747   -0.8185      6.1398 
#>          -8   0.8290     2.5423   -6.1100      7.7680 
#>          -7   5.2843     2.4902   -1.5123     12.0810 
#>          -6   2.8555     1.5031   -1.2469      6.9580 
#>          -5   1.3589     3.7348   -8.8348     11.5526 
#>          -4   0.3294     3.8676  -10.2267     10.8855 
#>          -3  -4.2227     4.3381  -16.0630      7.6177 
#>          -2  -3.8447     2.6441  -11.0615      3.3720 
#>          -1  -0.2234     3.4893   -9.7471      9.3004 
#>           0 -10.8156     7.5497  -31.4218      9.7906 
#>           1 -13.7998    13.0550  -49.4323     21.8326 
#>           2  -7.8432    11.5299  -39.3130     23.6267 
#>           3  -4.5541     9.7071  -31.0488     21.9406 
#>           4  -3.5368    12.6855  -38.1608     31.0872 
#>           5   8.5221    12.8598  -26.5774     43.6216 
#>           6   1.1140    16.2473  -43.2314     45.4594 
#>           7   6.6384    24.9990  -61.5939     74.8708 
#>           8   7.1288    26.3536  -64.8008     79.0584 
#>           9  10.8758    25.7444  -59.3911     81.1428 
#>          10  17.5057    37.0992  -83.7530    118.7644 
#>          11  40.8318    43.0915  -76.7823    158.4459 
#>          12  48.6134    49.0773  -85.3385    182.5652 
#>          13  52.4228    52.5399  -90.9800    195.8256 
#>          14  50.2000    61.8498 -118.6131    219.0131 
#>          15  68.2960    61.2098  -98.7703    235.3623 
#>          16  44.7305    84.4484 -185.7633    275.2243 
#>          17  61.4670    78.7304 -153.4203    276.3542 
#>          18  50.4635    99.8651 -222.1089    323.0359 
#>          19  47.3392   128.3893 -303.0872    397.7656 
#>          20  28.6326    99.9078 -244.0563    301.3216 
#>          21   4.3445   128.7065 -346.9476    355.6366 
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
