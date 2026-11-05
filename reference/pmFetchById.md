# Fetch PubMed records by PMID

It downloads metadata for a set of PubMed articles identified by their
PMID (PubMed Identifier). This is useful for retrieving specific known
articles, updating existing datasets, or downloading records identified
through other sources.

## Usage

``` r
pmFetchById(pmids, api_key = NULL, batch_size = 200)
```

## Arguments

- pmids:

  is a character or numeric vector. A vector of PubMed identifiers
  (PMIDs).

- api_key:

  is a character. It contains a valid API key for the NCBI E-utilities.
  Default is `api_key=NULL`. The API key can also be set via the
  environment variable `PUBMED_API_KEY` or `ENTREZ_KEY`.

- batch_size:

  is numeric. The number of records to download per API request. Default
  is 200.

## Value

a list following the same structure as
[`pmApiRequest`](https://massimoaria.github.io/pubmedR/reference/pmApiRequest.md)
output, containing:

|  |  |  |
|----|----|----|
| data |  | The xml-structured list containing the bibliographic metadata. |
| query |  | A character string describing the PMID-based query. |
| query_translation |  | Same as query for PMID-based searches. |
| records_downloaded |  | The total number of records downloaded. |
| total_count |  | The total number of PMIDs requested. |

## Details

The function uses the NCBI E-utilities `efetch` endpoint to retrieve
records directly by their PMIDs, without requiring a search query.
Records are downloaded in batches to respect API rate limits.

The output is compatible with
[`pmApi2df`](https://massimoaria.github.io/pubmedR/reference/pmApi2df.md)
for conversion to a dataframe.

## See also

[`pmApiRequest`](https://massimoaria.github.io/pubmedR/reference/pmApiRequest.md)

[`pmApi2df`](https://massimoaria.github.io/pubmedR/reference/pmApi2df.md)

## Examples

``` r
if (FALSE) { # interactive()
# Download specific articles by PMID
pmids <- c("34813985", "34813456", "34812345")
D <- pmFetchById(pmids = pmids)
M <- pmApi2df(D)
}
```
