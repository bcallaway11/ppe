
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
#>  14.8882       61.0457  -104.7593    134.5356 
#> 
#> 
#> Dynamic Effects:
#>  Event Time Estimate Std. Error     [95%  Conf. Band] 
#>         -10  -3.7266     4.0155  -14.4487      6.9954 
#>          -9   2.6607     1.4649   -1.2509      6.5723 
#>          -8   0.8290     2.1982   -5.0406      6.6986 
#>          -7   5.2843     2.2122   -0.6228     11.1915 
#>          -6   2.8555     1.8828   -2.1720      7.8831 
#>          -5   1.3589     3.9165   -9.0988     11.8166 
#>          -4   0.3294     3.1233   -8.0103      8.6691 
#>          -3  -4.2227     5.6412  -19.2857     10.8404 
#>          -2  -3.8447     3.1547  -12.2685      4.5790 
#>          -1  -0.2234     3.4089   -9.3259      8.8791 
#>           0 -10.8156     9.6689  -36.6334     15.0021 
#>           1 -13.7998    11.4868  -44.4716     16.8720 
#>           2  -7.8432    11.7029  -39.0923     23.4059 
#>           3  -4.5541     9.3487  -29.5170     20.4087 
#>           4  -3.5368    14.2902  -41.6945     34.6208 
#>           5   8.5221    12.6907  -25.3645     42.4087 
#>           6   1.1140    17.1492  -44.6776     46.9056 
#>           7   6.6384    19.4903  -45.4043     58.6811 
#>           8   7.1288    25.7643  -61.6667     75.9243 
#>           9  10.8758    39.6937  -95.1138    116.8655 
#>          10  17.5057    32.6865  -69.7735    104.7849 
#>          11  40.8318    51.5882  -96.9185    178.5820 
#>          12  48.6134    52.4925  -91.5516    188.7783 
#>          13  52.4228    54.8393  -94.0086    198.8542 
#>          14  50.2000    61.1427 -113.0627    213.4628 
#>          15  68.2960    68.2755 -114.0125    250.6045 
#>          16  44.7305    77.3749 -161.8752    251.3363 
#>          17  61.4670    83.2663 -160.8699    283.8038 
#>          18  50.4635   111.7703 -247.9844    348.9114 
#>          19  47.3392   124.4414 -284.9429    379.6213 
#>          20  28.6326    99.9412 -238.2293    295.4945 
#>          21   4.3445   158.3917 -418.5914    427.2805 
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
#> Warning in compute.aggte(MP = MP, type = type, balance_e = balance_e, min_e
#> = min_e, : Simultaneous conf. band is somehow smaller than pointwise one
#> using normal approximation. Since this is unusual, we are reporting pointwise
#> confidence intervals

summary(oo_res)
#> 
#> Overall ATT:  
#>      ATT    Std. Error     [ 95%  Conf. Int.]  
#>  -3.9162        1.4855    -6.8277     -1.0048 *
#> 
#> 
#> Dynamic Effects:
#>  Event Time Estimate Std. Error    [95%  Conf. Band]  
#>         -10  -3.0210     2.1812  -9.1923      3.1503  
#>          -9   2.7846     1.5705  -1.6589      7.2282  
#>          -8   0.2543     1.6055  -4.2882      4.7969  
#>          -7  -1.2765     0.9340  -3.9191      1.3661  
#>          -6  -0.9085     1.2336  -4.3987      2.5817  
#>          -5  -0.6359     1.3566  -4.4742      3.2024  
#>          -4   1.6184     1.4159  -2.3876      5.6245  
#>          -3  -0.4660     1.1197  -3.6338      2.7019  
#>          -2   0.7693     0.9474  -1.9111      3.4498  
#>          -1   0.2643     1.0434  -2.6878      3.2164  
#>           0  -0.8510     2.2825  -7.3088      5.6068  
#>           1  -5.5461     1.9213 -10.9822     -0.1100 *
#>           2  -6.5928     1.6626 -11.2969     -1.8888 *
#>           3  -6.7447     1.5036 -10.9988     -2.4907 *
#>           4  -7.2925     2.0161 -12.9968     -1.5883 *
#>           5  -3.6784     2.1965  -9.8929      2.5360  
#>           6  -4.9731     2.1842 -11.1530      1.2068  
#>           7  -4.0683     2.1637 -10.1900      2.0533  
#>           8  -6.1649     1.7340 -11.0708     -1.2590 *
#>           9  -5.9830     1.6404 -10.6243     -1.3417 *
#>          10  -1.4185     2.2347  -7.7413      4.9042  
#>          11  -2.4974     1.7498  -7.4480      2.4532  
#>          12  -1.9884     1.4394  -6.0609      2.0841  
#>          13  -3.3056     1.8977  -8.6748      2.0637  
#>          14  -2.4633     1.7068  -7.2924      2.3659  
#>          15  -3.8627     2.2782 -10.3083      2.5830  
#>          16  -3.3849     1.8421  -8.5968      1.8269  
#>          17  -2.1404     2.1339  -8.1778      3.8971  
#>          18  -6.1309     2.0653 -11.9742     -0.2876 *
#>          19  -0.7883     1.9978  -6.4406      4.8640  
#>          20   0.6190     2.2247  -5.6754      6.9135  
#>          21  -5.0789     2.2421 -11.4226      1.2647  
#> ---
#> Signif. codes: `*' confidence band does not cover 0

# make an event study plot
plot_df <- summary(oo_res)$event_study
colnames(plot_df) <- c("e", "att", "se", "cil", "ciu")
plot_df$post <- as.factor(1*(plot_df$e >= 0))
ggplot(plot_df, aes(x=e, y=att)) +
  geom_line(aes(color=post)) +
  geom_point(aes(color=post)) + 
  geom_line(aes(y=ciu), linetype="dashed", alpha=0.5) +
  geom_line(aes(y=cil), linetype="dashed", alpha=0.5) +
  theme_bw() +
  ylim(c(-30,30)) + 
  theme(legend.position="bottom")
```

![](man/figures/README-unnamed-chunk-8-1.png)<!-- -->
