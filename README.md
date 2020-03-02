
# pubmedR

<!-- badges: start -->
<!-- badges: end -->

The goal of pubmedR is to gather metadata about publications, patents, grants, clinical trials and policy documents from PubMed database.

## Installation

You can install the developer version of pubmedR from [github](https://github.com) with:

``` r
install.packages("devtools")
devtools::install_github("massimoaria/pubmedR")
```

You can install the released version of dimensionsR from [CRAN](https://CRAN.R-project.org) with:

``` r
# not yet on CRAN
# install.packages("pubmedR")
```

## Example


``` r
library(pubmedR)


query <- "bibliometric*[TITL] AND english[LA] AND article[PT]"

D <- pmApiRequest(query = query, limit = 1000, api_key = NULL)

M <- pmApi2df(D)

```

"# pubmedR" 
