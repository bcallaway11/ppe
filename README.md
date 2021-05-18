
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
xformla <- ~ current + I(current^2) + region + totalTestResults
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
#> Warning in compute.aggte(MP = MP, type = type, balance_e = balance_e, min_e
#> = min_e, : Simultaneous conf. band is somehow smaller than pointwise one
#> using normal approximation. Since this is unusual, we are reporting pointwise
#> confidence intervals

summary(res)
#> 
#> Overall ATT:  
#>      ATT    Std. Error     [ 95%  Conf. Int.] 
#>  14.8882       82.1669  -146.1561    175.9324 
#> 
#> 
#> Dynamic Effects:
#>  Event Time Estimate Std. Error     [95%  Conf. Band] 
#>         -10  -3.7266     2.8916  -11.0407      3.5874 
#>          -9   2.6607     1.5868   -1.3532      6.6745 
#>          -8   0.8290     2.6141   -5.7834      7.4413 
#>          -7   5.2843     2.2360   -0.3715     10.9402 
#>          -6   2.8555     2.0496   -2.3289      8.0399 
#>          -5   1.3589     3.8404   -8.3551     11.0729 
#>          -4   0.3294     4.2100  -10.3198     10.9785 
#>          -3  -4.2227     3.3890  -12.7949      4.3496 
#>          -2  -3.8447     2.8630  -11.0866      3.3971 
#>          -1  -0.2234     3.7521   -9.7143      9.2675 
#>           0 -10.8156     9.8332  -35.6882     14.0570 
#>           1 -13.7998    14.8284  -51.3076     23.7080 
#>           2  -7.8432    12.2982  -38.9509     23.2646 
#>           3  -4.5541    11.8074  -34.4204     25.3121 
#>           4  -3.5368    10.4181  -29.8889     22.8153 
#>           5   8.5221    11.9772  -21.7737     38.8179 
#>           6   1.1140    16.5316  -40.7019     42.9299 
#>           7   6.6384    20.3054  -44.7234     58.0002 
#>           8   7.1288    25.3286  -56.9389     71.1965 
#>           9  10.8758    23.8359  -49.4161     71.1677 
#>          10  17.5057    30.2247  -58.9464     93.9578 
#>          11  40.8318    52.6357  -92.3080    173.9716 
#>          12  48.6134    49.6534  -76.9830    174.2097 
#>          13  52.4228    44.0121  -58.9040    163.7496 
#>          14  50.2000    60.4837 -102.7911    203.1912 
#>          15  68.2960    67.1395 -101.5307    238.1227 
#>          16  44.7305    62.0768 -112.2902    201.7512 
#>          17  61.4670    97.0579 -184.0371    306.9710 
#>          18  50.4635    98.2750 -198.1191    299.0461 
#>          19  47.3392   112.6413 -237.5823    332.2607 
#>          20  28.6326   132.1554 -305.6490    362.9142 
#>          21   4.3445   174.4827 -437.0022    445.6913 
#> ---
#> Signif. codes: `*' confidence band does not cover 0
```

and we can also plot the results in event study.

``` r
ggpte(res) + ylim(c(-1000,1000))
```

![](man/figures/README-unnamed-chunk-7-1.png)<!-- -->

To conclude, we provide estimate effects of the effects of
shelter-in-place orders on travel. In the paper, we mainly consider the
case where (i) the policy can have a direct effect on travel, (ii) the
policy can have a direct effect on Covid-19 cases, and (iii) Covid-19
cases can have their own effect on travel. This means that the policy
can have an indirect effect on travel through its effect on Covid-19
cases. We show in the paper that neither standard DID (ignoring cases)
nor DID that includes current cases as a covariate delivers a suitable
estimate of the effect of the policy on travel in this case. We propose
an alternative estimator that accounts for the indirect effect of the
policy on travel through its effect on cases, and show code for this
approach below.

``` r
oo_res <- pte(yname="retail_and_recreation_percent_change_from_baseline",
           gname="group",
           tname="time.period",
           idname="state_id",
           data=covid_data2,
           subset_fun=two_by_two_subset,
           attgt_fun=other_outcome_attgt,
           xformla=xformla,
           max_e=21,
           min_e=-10,
           Iname="current",
           adjustI=TRUE) 

summary(oo_res)
#> 
#> Overall ATT:  
#>      ATT    Std. Error     [ 95%  Conf. Int.]  
#>  -3.9162         1.769    -7.3834      -0.449 *
#> 
#> 
#> Dynamic Effects:
#>  Event Time Estimate Std. Error    [95%  Conf. Band]  
#>         -10  -3.0210     2.0069  -8.7902      2.7482  
#>          -9   2.7846     2.0530  -3.1170      8.6862  
#>          -8   0.2543     1.4475  -3.9067      4.4154  
#>          -7  -1.2765     1.2144  -4.7675      2.2145  
#>          -6  -0.9085     1.1143  -4.1117      2.2947  
#>          -5  -0.6359     1.5331  -5.0430      3.7712  
#>          -4   1.6184     1.3782  -2.3433      5.5802  
#>          -3  -0.4660     1.1466  -3.7618      2.8299  
#>          -2   0.7693     0.9005  -1.8193      3.3579  
#>          -1   0.2643     1.1262  -2.9730      3.5016  
#>           0  -0.8510     2.4046  -7.7633      6.0613  
#>           1  -5.5461     2.1728 -11.7919      0.6997  
#>           2  -6.5928     1.4146 -10.6592     -2.5265 *
#>           3  -6.7447     1.4981 -11.0511     -2.4384 *
#>           4  -7.2925     2.0615 -13.2186     -1.3664 *
#>           5  -3.6784     2.5642 -11.0495      3.6927  
#>           6  -4.9731     1.7018  -9.8651     -0.0811 *
#>           7  -4.0683     1.8138  -9.2822      1.1456  
#>           8  -6.1649     1.8057 -11.3554     -0.9743 *
#>           9  -5.9830     1.8156 -11.2020     -0.7640 *
#>          10  -1.4185     1.7742  -6.5186      3.6816  
#>          11  -2.4974     1.5583  -6.9769      1.9821  
#>          12  -1.9884     1.4886  -6.2675      2.2907  
#>          13  -3.3056     1.6400  -8.0200      1.4089  
#>          14  -2.4633     1.9545  -8.0817      3.1551  
#>          15  -3.8627     2.3505 -10.6195      2.8941  
#>          16  -3.3849     1.7904  -8.5316      1.7617  
#>          17  -2.1404     1.9167  -7.6502      3.3695  
#>          18  -6.1309     1.3901 -10.1269     -2.1349 *
#>          19  -0.7883     2.3503  -7.5445      5.9679  
#>          20   0.6190     3.3738  -9.0794     10.3175  
#>          21  -5.0789     2.7749 -13.0556      2.8977  
#> ---
#> Signif. codes: `*' confidence band does not cover 0

# make an event study plot
ggpte(oo_res) + ylim(c(-30,30))
```

![](man/figures/README-unnamed-chunk-8-1.png)<!-- -->
