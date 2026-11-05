# Convert xml PubMed bibliographic data into a dataframe

It converts PubMed data, downloaded using Entrez API, into a dataframe

## Usage

``` r
pmApi2df(P, format = "bibliometrix")
```

## Arguments

- P:

  is a list following the xml PubMed structure, downloaded using the
  function `pmApiRequest`.

- format:

  is a character. If `format = "bibliometrix"` data will be converted in
  the bibliometrix compatible data format. If `format = "raw"` data will
  save in a data frame without any other data editing procedure.

## Value

a dataframe containing bibliographic records.

To obtain a free access to NCBI API, please visit:
<https://pmc.ncbi.nlm.nih.gov/tools/developers/>

To obtain more information about how to write a NCBI search query,
please visit: <https://pubmed.ncbi.nlm.nih.gov/help/#search-tags>

## See also

[`pmApiRequest`](https://massimoaria.github.io/pubmedR/reference/pmApiRequest.md)

[`pmQueryTotalCount`](https://massimoaria.github.io/pubmedR/reference/pmQueryTotalCount.md)

## Examples

``` r
if (FALSE) { # interactive()
# Example: Querying a collection of publications

query <- "bibliometric*[Title/Abstract] AND english[LA]
         AND Journal Article[PT] AND 2000:2020[DP]"
D <- pmApiRequest(query = query, limit = 100, api_key = NULL)
M <- pmApi2df(D)
}
```
