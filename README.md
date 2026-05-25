
<!-- README.md is generated from README.Rmd. Please edit that file -->

# Pandemic Policy Evaluation (ppe) package

> **Note:** This package is only lightly maintained. Most of the general
> functionality it provides — including bootstrap inference and
> aggregation of group-time average treatment effects — is now available
> through the `pte_default` method in the
> [`ptetools`](https://bcallaway11.github.io/ptetools/) package
> ([GitHub](https://github.com/bcallaway11/ptetools)).

The `ppe` package contains code for estimating policy effects during the
pandemic. It is the companion code for [Callaway and Li (2023), Policy
Evaluation during a Pandemic](https://arxiv.org/abs/2105.06927). The
central idea of that paper is to compare locations who implemented some
Covid-19 related policy to other locations that did not implement the
policy *and that had the same pre-treatment values of Covid-19 related
characteristics*. These characteristics definitely include (i) the
current number of cases and (ii) the number of susceptible individuals
(or equivalently the cumulative number of cases). They might also
include demographic characteristics, population densities, region of the
country, among others.

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
trim_id_list <- lapply(c(10, 15, 20, 25, 30),
  did::trimmer,
  tname = "time.period",
  idname = "state_id",
  gname = "group",
  xformla = xformla,
  data = covid_data,
  control_group = "nevertreated",
  threshold = 0.95)
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
res <- pte(yname = "positive",
  gname = "group",
  tname = "time.period",
  idname = "state_id",
  data = covid_data2,
  subset_fun = two_by_two_subset,
  setup_pte_fun = setup_pte_basic,
  attgt_fun = covid_attgt,
  xformla = xformla,
  max_e = 21,
  min_e = -10)
#> Warning in pte(yname = "positive", gname = "group", tname = "time.period", : 'pte' is deprecated.
#> Use 'pte2' instead.
#> See help("Deprecated")
#> Warning in BMisc::getListElement(selective.se.inner, "se"): 'BMisc::getListElement' is deprecated.
#> Use 'get_list_element' instead.
#> See help("Deprecated")
#> Warning in BMisc::getListElement(selective.se.inner, "inf.func"): 'BMisc::getListElement' is deprecated.
#> Use 'get_list_element' instead.
#> See help("Deprecated")
#> Warning in BMisc::getListElement(dynamic.se.inner, "se"): 'BMisc::getListElement' is deprecated.
#> Use 'get_list_element' instead.
#> See help("Deprecated")
#> Warning in BMisc::getListElement(dynamic.se.inner, "inf.func"): 'BMisc::getListElement' is deprecated.
#> Use 'get_list_element' instead.
#> See help("Deprecated")

summary(res)
#> 
#> Overall ATT:  
#>      ATT    Std. Error     [ 95%  Conf. Int.] 
#>  14.8882       80.1842  -142.2701    172.0464 
#> 
#> 
#> Dynamic Effects:
#>  Event Time Estimate Std. Error     [95%  Conf. Band] 
#>         -10  -3.7266     3.5260  -13.1880      5.7347 
#>          -9   2.6607     1.5159   -1.4071      6.7284 
#>          -8   0.8290     2.3408   -5.4522      7.1102 
#>          -7   5.2843     2.0268   -0.1542     10.7229 
#>          -6   2.8555     1.9758   -2.4462      8.1572 
#>          -5   1.3589     3.9120   -9.1383     11.8561 
#>          -4   0.3294     3.8860  -10.0980     10.7568 
#>          -3  -4.2227     5.6703  -19.4379     10.9926 
#>          -2  -3.8447     2.7654  -11.2652      3.5757 
#>          -1  -0.2234     3.5667   -9.7940      9.3472 
#>           0 -10.8156     9.0546  -35.1123     13.4811 
#>           1 -13.7998    14.0387  -51.4704     23.8708 
#>           2  -7.8432    10.5938  -36.2700     20.5836 
#>           3  -4.5541    10.2174  -31.9708     22.8625 
#>           4  -3.5368    12.5919  -37.3253     30.2516 
#>           5   8.5221    14.5763  -30.5911     47.6353 
#>           6   1.1140    15.4788  -40.4209     42.6489 
#>           7   6.6384    19.8961  -46.7497     60.0266 
#>           8   7.1288    34.1376  -84.4740     98.7316 
#>           9  10.8758    28.7639  -66.3075     88.0592 
#>          10  17.5057    31.4284  -66.8275    101.8389 
#>          11  40.8318    36.1131  -56.0721    137.7357 
#>          12  48.6134    57.6837 -106.1718    203.3985 
#>          13  52.4228    54.2404  -93.1227    197.9683 
#>          14  50.2000    65.6197 -125.8801    226.2801 
#>          15  68.2960    68.5511 -115.6500    252.2420 
#>          16  44.7305    82.0383 -175.4064    264.8674 
#>          17  61.4670    96.6043 -197.7555    320.6894 
#>          18  50.4635   113.8958 -255.1580    356.0850 
#>          19  47.3392   111.7736 -252.5877    347.2661 
#>          20  28.6326   148.8780 -370.8582    428.1234 
#>          21   4.3445   149.9413 -397.9995    406.6886 
#> ---
#> Signif. codes: `*' confidence band does not cover 0
```

and we can also plot the results in event study.

``` r
ggpte(res) + ylim(c(-1000, 1000))
```

![](man/figures/README-unnamed-chunk-7-1.png)<!-- -->

To conclude, we provide estimated effects of the effects of
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
oo_res <- pte(yname = "retail_and_recreation_percent_change_from_baseline",
  gname = "group",
  tname = "time.period",
  idname = "state_id",
  data = covid_data2,
  subset_fun = two_by_two_subset,
  setup_pte_fun = setup_pte_basic,
  attgt_fun = other_outcome_attgt,
  xformla = xformla,
  max_e = 21,
  min_e = -10,
  Iname = "current",
  adjustI = TRUE)
#> Warning in pte(yname = "retail_and_recreation_percent_change_from_baseline", : 'pte' is deprecated.
#> Use 'pte2' instead.
#> See help("Deprecated")
#> Warning in BMisc::getListElement(selective.se.inner, "se"): 'BMisc::getListElement' is deprecated.
#> Use 'get_list_element' instead.
#> See help("Deprecated")
#> Warning in BMisc::getListElement(selective.se.inner, "inf.func"): 'BMisc::getListElement' is deprecated.
#> Use 'get_list_element' instead.
#> See help("Deprecated")
#> Warning in BMisc::getListElement(dynamic.se.inner, "se"): 'BMisc::getListElement' is deprecated.
#> Use 'get_list_element' instead.
#> See help("Deprecated")
#> Warning in BMisc::getListElement(dynamic.se.inner, "inf.func"): 'BMisc::getListElement' is deprecated.
#> Use 'get_list_element' instead.
#> See help("Deprecated")

summary(oo_res)
#> 
#> Overall ATT:  
#>      ATT    Std. Error     [ 95%  Conf. Int.] 
#>  -3.9162        2.0164    -7.8683      0.0358 
#> 
#> 
#> Dynamic Effects:
#>  Event Time Estimate Std. Error    [95%  Conf. Band]  
#>         -10  -3.0210     1.6270  -8.0522      2.0102  
#>          -9   2.7846     1.6460  -2.3053      7.8745  
#>          -8   0.2543     1.2054  -3.4731      3.9818  
#>          -7  -1.2765     1.0667  -4.5749      2.0219  
#>          -6  -0.9085     1.4291  -5.3276      3.5106  
#>          -5  -0.6359     1.3543  -4.8237      3.5519  
#>          -4   1.6184     1.2284  -2.1801      5.4170  
#>          -3  -0.4660     1.0130  -3.5983      2.6664  
#>          -2   0.7693     0.9277  -2.0993      3.6380  
#>          -1   0.2643     1.1694  -3.3519      3.8805  
#>           0  -0.8510     2.7673  -9.4083      7.7063  
#>           1  -5.5461     1.8829 -11.3686      0.2764  
#>           2  -6.5928     1.6687 -11.7529     -1.4328 *
#>           3  -6.7447     1.7644 -12.2006     -1.2889 *
#>           4  -7.2925     2.0251 -13.5546     -1.0305 *
#>           5  -3.6784     1.9895  -9.8303      2.4735  
#>           6  -4.9731     2.1774 -11.7061      1.7600  
#>           7  -4.0683     2.2418 -11.0005      2.8639  
#>           8  -6.1649     1.5662 -11.0079     -1.3218 *
#>           9  -5.9830     1.9783 -12.1004      0.1344  
#>          10  -1.4185     1.9735  -7.5211      4.6840  
#>          11  -2.4974     1.9754  -8.6059      3.6111  
#>          12  -1.9884     1.4407  -6.4435      2.4667  
#>          13  -3.3056     1.6858  -8.5186      1.9075  
#>          14  -2.4633     2.4494 -10.0375      5.1109  
#>          15  -3.8627     2.2821 -10.9194      3.1941  
#>          16  -3.3849     1.5453  -8.1633      1.3934  
#>          17  -2.1404     2.2130  -8.9836      4.7028  
#>          18  -6.1309     2.1120 -12.6617      0.3999  
#>          19  -0.7883     2.7617  -9.3282      7.7516  
#>          20   0.6190     2.3223  -6.5620      7.8001  
#>          21  -5.0789     2.1830 -11.8292      1.6714  
#> ---
#> Signif. codes: `*' confidence band does not cover 0

# make an event study plot
ggpte(oo_res) + ylim(c(-30, 30))
```

![](man/figures/README-unnamed-chunk-8-1.png)<!-- -->
