# Count the documents of a query by publication year

It returns the publication trend of a query without downloading its
records, with one request per year.

## Usage

``` r
pmCountByYear(query, years = NULL, api_key = NULL)
```

## Arguments

- query:

  is a character. A search query in the Entrez query language.

- years:

  is a numeric vector of years. Default is the last 20 years.

- api_key:

  is a character. A valid API key for the NCBI E-utilities. Default is
  `api_key=NULL`. It can also be set via the environment variable
  `PUBMED_API_KEY` or `ENTREZ_KEY`.

## Value

a data frame with the columns `year` and `count`, in the order of
`years`.

## See also

[`pmQueryTotalCount`](https://massimoaria.github.io/pubmedR/reference/pmQueryTotalCount.md),
[`pmQueryBuild`](https://massimoaria.github.io/pubmedR/reference/pmQueryBuild.md)

## Examples

``` r
if (FALSE) { # interactive()
pmCountByYear("bibliometric*[Title/Abstract]", years = 2015:2024)
}
```
