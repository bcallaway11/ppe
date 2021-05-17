
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
#> Warning in compute.aggte(MP = MP, type = type, balance_e = balance_e, min_e
#> = min_e, : Simultaneous conf. band is somehow smaller than pointwise one
#> using normal approximation. Since this is unusual, we are reporting pointwise
#> confidence intervals

summary(res)
#> 
#> Overall ATT:  
#>      ATT    Std. Error     [ 95%  Conf. Int.] 
#>  74.0998       68.7315   -60.6114    208.8111 
#> 
#> 
#> Dynamic Effects:
#>  Event Time Estimate Std. Error     [95%  Conf. Band] 
#>         -10  -4.4309     2.5511  -10.9696      2.1078 
#>          -9   0.6468     2.0709   -4.6610      5.9546 
#>          -8  -1.0199     1.5191   -4.9136      2.8738 
#>          -7   4.9369     2.3627   -1.1189     10.9926 
#>          -6   2.7974     1.6696   -1.4820      7.0768 
#>          -5   3.3207     3.8017   -6.4233     13.0648 
#>          -4   2.2912     3.6709   -7.1175     11.6999 
#>          -3  -0.3394     4.0920  -10.8274     10.1485 
#>          -2  -1.8006     2.9126   -9.2657      5.6645 
#>          -1   1.2608     2.7563   -5.8038      8.3254 
#>           0  -4.0483     5.1934  -17.3594      9.2628 
#>           1  -2.8472     6.9084  -20.5539     14.8595 
#>           2   4.6124     7.6636  -15.0299     24.2547 
#>           3   8.6060     9.7757  -16.4496     33.6615 
#>           4  10.9207    15.8913  -29.8096     51.6510 
#>           5  20.6761    14.1401  -15.5658     56.9181 
#>           6  18.3053    20.8831  -35.2192     71.8299 
#>           7  23.3457    19.4518  -26.5102     73.2016 
#>           8  29.1808    26.8714  -39.6920     98.0535 
#>           9  34.8426    29.9997  -42.0482    111.7334 
#>          10  46.7525    34.3337  -41.2467    134.7516 
#>          11  54.3023    35.1342  -35.7485    144.3530 
#>          12  63.0487    38.4425  -35.4814    161.5789 
#>          13  66.3826    47.9567  -56.5332    189.2983 
#>          14  72.4041    45.6867  -44.6933    189.5015 
#>          15  92.5038    73.4616  -95.7822    280.7898 
#>          16  75.2222    55.6801  -67.4887    217.9332 
#>          17  92.4658    66.3138  -77.5001    262.4317 
#>          18  90.5871    93.9866 -150.3056    331.4798 
#>          19 100.4617   127.5215 -226.3828    427.3062 
#>          20 100.4475   106.3142 -172.0416    372.9366 
#>          21  98.0003    93.8457 -142.5314    338.5319 
#> ---
#> Signif. codes: `*' confidence band does not cover 0
```
