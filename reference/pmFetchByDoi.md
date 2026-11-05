# Fetch PubMed records by DOI

It downloads the PubMed records of a set of articles identified by their
DOI, for instance to complete a collection coming from another database.

## Usage

``` r
pmFetchByDoi(dois, api_key = NULL, batch_size = 50)
```

## Arguments

- dois:

  is a character vector of DOIs, with or without the `https://doi.org/`
  prefix.

- api_key:

  is a character. A valid API key for the NCBI E-utilities. Default is
  `api_key=NULL`. It can also be set via the environment variable
  `PUBMED_API_KEY` or `ENTREZ_KEY`.

- batch_size:

  is numeric. DOIs per search. Default is 50.

## Value

a list with the same structure as the output of
[`pmFetchById`](https://massimoaria.github.io/pubmedR/reference/pmFetchById.md),
ready for
[`pmApi2df`](https://massimoaria.github.io/pubmedR/reference/pmApi2df.md),
with one more element: `not_found`, the DOIs with no PubMed record.

## See also

[`pmFetchById`](https://massimoaria.github.io/pubmedR/reference/pmFetchById.md),
[`pmApi2df`](https://massimoaria.github.io/pubmedR/reference/pmApi2df.md)

## Examples

``` r
if (FALSE) { # interactive()
D <- pmFetchByDoi(c("10.1016/j.joi.2017.08.007", "10.1038/nature14539"))
D$not_found
M <- pmApi2df(D)
}
```
