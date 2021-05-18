
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

    #> Warning: glm.fit: algorithm did not converge
    #> Warning: glm.fit: fitted probabilities numerically 0 or 1 occurred
    #> [1] "hard to match treated observations: "
    #> # A tibble: 4 x 1
    #>   state_id
    #>      <int>
    #> 1        5
    #> 2       15
    #> 3       32
    #> 4       35
    #> [1] "hard to match treated observations: "
    #> # A tibble: 5 x 1
    #>   state_id
    #>      <int>
    #> 1        7
    #> 2       19
    #> 3       23
    #> 4       47
    #> 5       48
    #> [1] "hard to match treated observations: "
    #> # A tibble: 3 x 1
    #>   state_id
    #>      <int>
    #> 1       31
    #> 2       39
    #> 3       40
    #> Warning: glm.fit: algorithm did not converge
    
    #> Warning: glm.fit: fitted probabilities numerically 0 or 1 occurred
    #> [1] "hard to match treated observations: "
    #> # A tibble: 7 x 1
    #>   state_id
    #>      <int>
    #> 1        2
    #> 2       10
    #> 3       11
    #> 4       22
    #> 5       25
    #> 6       26
    #> 7       44
    #> Warning: glm.fit: fitted probabilities numerically 0 or 1 occurred
    #> [1] "hard to match treated observations: "
    #> # A tibble: 1 x 1
    #>   state_id
    #>      <int>
    #> 1       41

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

summary(res)
#> 
#> Overall ATT:  
#>      ATT    Std. Error     [ 95%  Conf. Int.] 
#>  74.0998       75.4064    -73.694    221.8936 
#> 
#> 
#> Dynamic Effects:
#>  Event Time Estimate Std. Error     [95%  Conf. Band] 
#>         -10  -4.4309     1.8225   -8.9246      0.0628 
#>          -9   0.6468     2.1794   -4.7271      6.0207 
#>          -8  -1.0199     1.7793   -5.4073      3.3675 
#>          -7   4.9369     2.6123   -1.5043     11.3781 
#>          -6   2.7974     1.8233   -1.6983      7.2931 
#>          -5   3.3207     4.2361   -7.1243     13.7658 
#>          -4   2.2912     2.9641   -5.0176      9.5999 
#>          -3  -0.3394     3.8471   -9.8255      9.1466 
#>          -2  -1.8006     2.3565   -7.6113      4.0101 
#>          -1   1.2608     3.0173   -6.1792      8.7008 
#>           0  -4.0483     3.4227  -12.4879      4.3913 
#>           1  -2.8472     7.0903  -20.3301     14.6357 
#>           2   4.6124     6.6708  -11.8360     21.0608 
#>           3   8.6060     9.6170  -15.1070     32.3190 
#>           4  10.9207    11.2922  -16.9230     38.7644 
#>           5  20.6761    18.8405  -25.7799     67.1321 
#>           6  18.3053    17.1425  -23.9638     60.5745 
#>           7  23.3457    25.1555  -38.6814     85.3728 
#>           8  29.1808    28.2087  -40.3749     98.7364 
#>           9  34.8426    30.4280  -40.1851    109.8703 
#>          10  46.7525    35.6165  -41.0690    134.5739 
#>          11  54.3023    44.7139  -55.9510    164.5555 
#>          12  63.0487    36.7047  -27.4558    153.5533 
#>          13  66.3826    47.9745  -51.9105    184.6756 
#>          14  72.4041    48.9732  -48.3514    193.1597 
#>          15  92.5038    60.9565  -57.7997    242.8072 
#>          16  75.2222    60.8823  -74.8981    225.3426 
#>          17  92.4658    89.8060 -128.9733    313.9050 
#>          18  90.5871   107.3272 -174.0547    355.2290 
#>          19 100.4617    79.3892  -95.2921    296.2154 
#>          20 100.4475   110.8954 -172.9928    373.8878 
#>          21  98.0003   107.8547 -167.9422    363.9428 
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
