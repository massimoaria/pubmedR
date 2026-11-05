# Count the number of documents returned by a query

It counts the number of documents that a query returns from the NCBI
PubMed database.

## Usage

``` r
pmQueryTotalCount(query, api_key = NULL)
```

## Arguments

- query:

  is a character. It contains a search query formulated using the Entrez
  query language.

- api_key:

  is a character. It contains a valid API key for the NCBI E-utilities.
  Default is `api_key=NULL`. The use of NCBI PubMed APIs is entirely
  free, and doesn't necessarily require an API key. The API key can also
  be set via the environment variable `PUBMED_API_KEY` or `ENTREZ_KEY`.

## Value

a list. It contains three objects:

|  |  |  |
|----|----|----|
| total_count |  | The total number of records returned by the query |
| query_translation |  | The query translation by the NCBI Automatic Terms Translation system |
| web_history |  | The web history object. The NCBI provides search history features, which is useful for dealing with large lists of IDs or repeated searches. |

To obtain a free access to NCBI API, please visit:
<https://pmc.ncbi.nlm.nih.gov/tools/developers/>

## See also

[`pmApiRequest`](https://massimoaria.github.io/pubmedR/reference/pmApiRequest.md)

[`pmApi2df`](https://massimoaria.github.io/pubmedR/reference/pmApi2df.md)

## Examples

``` r
if (FALSE) { # interactive()
query <- "bibliometric*[Title/Abstract] AND english[LA]
           AND Journal Article[PT] AND 2000:2020[DP]"
D <- pmQueryTotalCount(query = query, api_key = NULL)
}
```
