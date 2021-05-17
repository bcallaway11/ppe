
<!-- README.md is generated from README.Rmd. Please edit that file -->

# Pandemic Policy Evaluation (ppe) package

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
time_id_list <- unlist(trim_id_list)

# states that we will drop
unique(subset(covid_data, state_id %in% time_id_list)$state)
#>  [1] "AL" "CA" "CT" "FL" "GA" "IL" "LA" "ME" "MI" "MO" "MS" "NH" "NJ" "NY" "PA"
#> [16] "RI" "SC" "TX" "VT" "WA"
covid_data2 <- subset(covid_data, !(state_id %in% time_id_list))
```

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
#>  74.0998       62.9975   -49.3729    197.5726 
#> 
#> 
#> Dynamic Effects:
#>  Event time Estimate Std. Error     [95%  Conf. Band] 
#>         -10  -4.4309     2.6731  -12.3814      3.5196 
#>          -9   0.6468     1.7748   -4.6321      5.9256 
#>          -8  -1.0199     1.7790   -6.3112      4.2714 
#>          -7   4.9369     1.9598   -0.8921     10.7659 
#>          -6   2.7974     1.6107   -1.9933      7.5882 
#>          -5   3.3207     3.5957   -7.3739     14.0154 
#>          -4   2.2912     3.5053   -8.1346     12.7169 
#>          -3  -0.3394     4.3921  -13.4028     12.7240 
#>          -2  -1.8006     2.6195   -9.5919      5.9907 
#>          -1   1.2608     2.8621   -7.2520      9.7736 
#>           0  -4.0483     4.7477  -18.1694     10.0728 
#>           1  -2.8472     6.5185  -22.2353     16.5409 
#>           2   4.6124     9.0430  -22.2842     31.5090 
#>           3   8.6060     9.7154  -20.2906     37.5026 
#>           4  10.9207     9.4547  -17.2003     39.0418 
#>           5  20.6761    17.4367  -31.1859     72.5381 
#>           6  18.3053    17.1376  -32.6669     69.2776 
#>           7  23.3457    21.3458  -40.1431     86.8344 
#>           8  29.1808    25.5423  -46.7896    105.1511 
#>           9  34.8426    25.8083  -41.9191    111.6042 
#>          10  46.7525    31.5358  -47.0444    140.5494 
#>          11  54.3023    41.4413  -68.9567    177.5612 
#>          12  63.0487    40.7850  -58.2580    184.3555 
#>          13  66.3826    55.9659 -100.0767    232.8419 
#>          14  72.4041    52.9266  -85.0155    229.8238 
#>          15  92.5038    69.9331 -115.4981    300.5056 
#>          16  75.2222    69.6517 -131.9428    282.3873 
#>          17  92.4658    84.2628 -158.1569    343.0886 
#>          18  90.5871    95.5208 -193.5203    374.6946 
#>          19 100.4617   104.9052 -211.5577    412.4811 
#>          20 100.4475   128.9806 -283.1795    484.0745 
#>          21  98.0003   124.9941 -273.7696    469.7702 
#> ---
#> Signif. codes: `*' confidence band does not cover 0
#> $overall_att
#>       ATT    Std. Error     [ 95%  Conf. Int.] 
#> 1 74.0998       62.9975   -49.3729    197.5726 
#> 
#> $event_study
#>    Event time Estimate Std. Error     [95%  Conf. Band] 
#> 1         -10  -4.4309     2.6731  -12.3814      3.5196 
#> 2          -9   0.6468     1.7748   -4.6321      5.9256 
#> 3          -8  -1.0199     1.7790   -6.3112      4.2714 
#> 4          -7   4.9369     1.9598   -0.8921     10.7659 
#> 5          -6   2.7974     1.6107   -1.9933      7.5882 
#> 6          -5   3.3207     3.5957   -7.3739     14.0154 
#> 7          -4   2.2912     3.5053   -8.1346     12.7169 
#> 8          -3  -0.3394     4.3921  -13.4028     12.7240 
#> 9          -2  -1.8006     2.6195   -9.5919      5.9907 
#> 10         -1   1.2608     2.8621   -7.2520      9.7736 
#> 11          0  -4.0483     4.7477  -18.1694     10.0728 
#> 12          1  -2.8472     6.5185  -22.2353     16.5409 
#> 13          2   4.6124     9.0430  -22.2842     31.5090 
#> 14          3   8.6060     9.7154  -20.2906     37.5026 
#> 15          4  10.9207     9.4547  -17.2003     39.0418 
#> 16          5  20.6761    17.4367  -31.1859     72.5381 
#> 17          6  18.3053    17.1376  -32.6669     69.2776 
#> 18          7  23.3457    21.3458  -40.1431     86.8344 
#> 19          8  29.1808    25.5423  -46.7896    105.1511 
#> 20          9  34.8426    25.8083  -41.9191    111.6042 
#> 21         10  46.7525    31.5358  -47.0444    140.5494 
#> 22         11  54.3023    41.4413  -68.9567    177.5612 
#> 23         12  63.0487    40.7850  -58.2580    184.3555 
#> 24         13  66.3826    55.9659 -100.0767    232.8419 
#> 25         14  72.4041    52.9266  -85.0155    229.8238 
#> 26         15  92.5038    69.9331 -115.4981    300.5056 
#> 27         16  75.2222    69.6517 -131.9428    282.3873 
#> 28         17  92.4658    84.2628 -158.1569    343.0886 
#> 29         18  90.5871    95.5208 -193.5203    374.6946 
#> 30         19 100.4617   104.9052 -211.5577    412.4811 
#> 31         20 100.4475   128.9806 -283.1795    484.0745 
#> 32         21  98.0003   124.9941 -273.7696    469.7702
```
