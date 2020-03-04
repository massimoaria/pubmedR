
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
```

First of all, we define a query to submit at the NCBI PubMed system.
For example, imagine we want downlaod a collection of journal articles using bibliometric analyses, published in the last 20 years in English language.
Translating in the query language, we find:
- documents cointaining the word bibliometric and its variations in their title or abstract: "bibliometric*[Title/Abstract]"
- documents written in English language: "english[LA]"
- documents that are categorized as Journal Article: "Journal Article[PT]"
- docuemnts published from the 2000 to the 2020: "2000:2020[DP]"

Combining all these elements using the Boolean operator "AND", we obtain the final query:

``` r
query <- "bibliometric*[Title/Abstract] AND english[LA] AND Journal Article[PT] AND 2000:2020[DP]"
```
Now, we want to know how many documents should retrieved by our query. 
To do that, we use the function pmQueryTotalCount.
``` r
res <- pmQueryTotalCount(query = query, api_key = api_key)
res$total_count
```
We could decide to change the query or continue to downloadthe whole collection or a part of it (setting the limit argument lower than res$total_count.

Image, we decided to download the whole collection:

``` r
D <- pmApiRequest(query = query, limit = res$total_count, api_key = NULL)
```
Finally, we transform the xml object D into a data frame, with cases corresponding to documents and variables to Field Tags as used in bibliometrix R package.

``` r
M <- pmApi2df(D)
```


"# pubmedR" 
