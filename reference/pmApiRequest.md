# Gather bibliographic content from PubMed database using NCBI entrez APIs

It gathers metadata about publications from the NCBI PubMed database.
The use of NCBI PubMed APIs is entirely free, and doesn't necessarily
require an API key. The function `pmApiRequest` queries NCBI PubMed
using an entrez query formulated through the Entrez query language or
the helper function
[`pmQueryBuild`](https://massimoaria.github.io/pubmedR/reference/pmQueryBuild.md).

## Usage

``` r
pmApiRequest(query, limit, api_key = NULL, batch_size = 200)
```

## Arguments

- query:

  is a character. It contains a search query formulated using the Entrez
  query language.

- limit:

  is numeric. It indicates the max number of records to download.

- api_key:

  is a character. It contains a valid API key for the NCBI E-utilities.
  Default is `api_key=NULL`. The API key can also be set via the
  environment variable `PUBMED_API_KEY` or `ENTREZ_KEY`.

- batch_size:

  is numeric. The number of records to download per API request. Default
  is 200.

## Value

a list D composed by 5 objects:

|  |  |  |
|----|----|----|
| data |  | It is the xml-structured list containing the bibliographic metadata collection downloaded from the PubMed database. |
| query |  | It a character object containing the original query formulated by the user. |
| query_translation |  | It a character object containing the query, translated by the NCBI Automatic Terms Translation system and submitted to the PubMed database. |
| records_downloaded |  | It is an integer object indicating the total number of records downloaded and stored in "data". |
| total_count |  | It is an integer object indicating the total number of records matching the query (stored in the "query_translation" object"). |

To obtain a free access to NCBI API, please visit:
<https://pmc.ncbi.nlm.nih.gov/tools/developers/>

To obtain more information about how to write a NCBI search query,
please visit: <https://pubmed.ncbi.nlm.nih.gov/help/#search-tags>

## Details

Official API documentation is
<https://www.ncbi.nlm.nih.gov/books/NBK25500/>.

PubMed serves only the first 9,999 records of a search. When more than
that are requested, the query is split by the date each record was added
to PubMed, and each part is downloaded in turn, so `limit` can exceed
this figure. Records then come ordered by that date period, newest
first, not as in the whole search.

## See also

[`pmQueryTotalCount`](https://massimoaria.github.io/pubmedR/reference/pmQueryTotalCount.md)

[`pmApi2df`](https://massimoaria.github.io/pubmedR/reference/pmApi2df.md)

[`pmQueryBuild`](https://massimoaria.github.io/pubmedR/reference/pmQueryBuild.md)

## Examples

``` r
if (FALSE) { # interactive()
query <- "bibliometric*[Title/Abstract] AND english[LA]
          AND Journal Article[PT] AND 2000:2020[DP]"
 D <- pmApiRequest(query = query, limit = 100, api_key = NULL)
}
```
