
<!-- README.md is generated from README.Rmd. Please edit that file -->

# Pandemic Policy Evaluation (ppe) package

The `ppe` package contains code for estimating policy effects during the
pandemic. It is the companion code for [Callaway and Li (2021), Policy
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
#>  14.8882       82.0311  -145.8899    175.6662 
#> 
#> 
#> Dynamic Effects:
#>  Event Time Estimate Std. Error     [95%  Conf. Band] 
#>         -10  -3.7266     3.1866  -12.5207      5.0674 
#>          -9   2.6607     1.9686   -2.7721      8.0934 
#>          -8   0.8290     2.4872   -6.0351      7.6930 
#>          -7   5.2843     1.9902   -0.2082     10.7768 
#>          -6   2.8555     2.1240   -3.0060      8.7170 
#>          -5   1.3589     3.7612   -9.0208     11.7386 
#>          -4   0.3294     4.3537  -11.6856     12.3443 
#>          -3  -4.2227     4.6343  -17.0119      8.5665 
#>          -2  -3.8447     3.3393  -13.0603      5.3708 
#>          -1  -0.2234     3.6395  -10.2672      9.8204 
#>           0 -10.8156     9.1844  -36.1618     14.5305 
#>           1 -13.7998    15.5314  -56.6618     29.0622 
#>           2  -7.8432    10.7932  -37.6291     21.9428 
#>           3  -4.5541    11.4520  -36.1583     27.0500 
#>           4  -3.5368    10.5804  -32.7356     25.6620 
#>           5   8.5221    11.9627  -24.4913     41.5355 
#>           6   1.1140    14.9703  -40.1996     42.4276 
#>           7   6.6384    18.8443  -45.3662     58.6431 
#>           8   7.1288    25.0843  -62.0966     76.3542 
#>           9  10.8758    26.6884  -62.7763     84.5280 
#>          10  17.5057    33.8652  -75.9523    110.9637 
#>          11  40.8318    33.9059  -52.7384    134.4019 
#>          12  48.6134    41.7463  -66.5942    163.8209 
#>          13  52.4228    52.4409  -92.2987    197.1443 
#>          14  50.2000    56.1049 -104.6328    205.0329 
#>          15  68.2960    55.2406  -84.1516    220.7436 
#>          16  44.7305    88.7289 -200.1352    289.5962 
#>          17  61.4670   123.2700 -278.7219    401.6559 
#>          18  50.4635   104.9096 -239.0559    339.9829 
#>          19  47.3392   148.4732 -362.4030    457.0814 
#>          20  28.6326   133.6901 -340.3125    397.5778 
#>          21   4.3445   142.3427 -388.4793    397.1683 
#> ---
#> Signif. codes: `*' confidence band does not cover 0
```

and we can also plot the results in event study.

``` r
ggpte(res) + ylim(c(-1000,1000))
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
#>  -3.9162        1.2671    -6.3997     -1.4328 *
#> 
#> 
#> Dynamic Effects:
#>  Event Time Estimate Std. Error    [95%  Conf. Band]  
#>         -10  -3.0210     2.0256  -8.5155      2.4735  
#>          -9   2.7846     2.0401  -2.7493      8.3186  
#>          -8   0.2543     1.7692  -4.5446      5.0533  
#>          -7  -1.2765     0.9825  -3.9415      1.3884  
#>          -6  -0.9085     1.0728  -3.8185      2.0015  
#>          -5  -0.6359     1.1975  -3.8843      2.6124  
#>          -4   1.6184     1.2775  -1.8470      5.0838  
#>          -3  -0.4660     1.1682  -3.6347      2.7028  
#>          -2   0.7693     0.8388  -1.5060      3.0447  
#>          -1   0.2643     1.2777  -3.2015      3.7300  
#>           0  -0.8510     2.7207  -8.2309      6.5289  
#>           1  -5.5461     2.0760 -11.1773      0.0851  
#>           2  -6.5928     1.5579 -10.8187     -2.3669 *
#>           3  -6.7447     1.8791 -11.8417     -1.6477 *
#>           4  -7.2925     1.8004 -12.1760     -2.4090 *
#>           5  -3.6784     2.3887 -10.1577      2.8009  
#>           6  -4.9731     1.8145  -9.8949     -0.0513 *
#>           7  -4.0683     2.1939 -10.0192      1.8826  
#>           8  -6.1649     1.3315  -9.7765     -2.5532 *
#>           9  -5.9830     2.0276 -11.4829     -0.4831 *
#>          10  -1.4185     2.3772  -7.8669      5.0298  
#>          11  -2.4974     1.7935  -7.3623      2.3675  
#>          12  -1.9884     1.6695  -6.5171      2.5403  
#>          13  -3.3056     1.7232  -7.9797      1.3686  
#>          14  -2.4633     2.3675  -8.8853      3.9587  
#>          15  -3.8627     1.9419  -9.1301      1.4048  
#>          16  -3.3849     1.9327  -8.6275      1.8576  
#>          17  -2.1404     2.2861  -8.3415      4.0607  
#>          18  -6.1309     2.1794 -12.0425     -0.2193 *
#>          19  -0.7883     2.6213  -7.8986      6.3220  
#>          20   0.6190     2.7413  -6.8168      8.0549  
#>          21  -5.0789     3.3228 -14.0921      3.9342  
#> ---
#> Signif. codes: `*' confidence band does not cover 0

# make an event study plot
ggpte(oo_res) + ylim(c(-30,30))
```

![](man/figures/README-unnamed-chunk-8-1.png)<!-- -->
