# Find articles that cite a given PubMed article

It retrieves the PMIDs of articles that cite a given PubMed article,
using the NCBI E-Link service (PubMed Cited by).

## Usage

``` r
pmCitedBy(pmid, api_key = NULL)
```

## Arguments

- pmid:

  is a character or numeric. A single PubMed identifier (PMID).

- api_key:

  is a character. It contains a valid API key for the NCBI E-utilities.
  Default is `api_key=NULL`. The API key can also be set via the
  environment variable `PUBMED_API_KEY` or `ENTREZ_KEY`.

## Value

a list containing:

|          |     |                                                            |
|----------|-----|------------------------------------------------------------|
| pmid     |     | The queried PMID.                                          |
| cited_by |     | A character vector of PMIDs that cite the queried article. |
| count    |     | The number of citing articles found.                       |

## Details

This function uses the NCBI E-Link endpoint with linkname
"pubmed_pubmed_citedin" to find articles in PubMed that cite the given
article.

Note: Citation data in PubMed is based on PubMed Central (PMC) and may
not be as comprehensive as commercial citation databases (e.g. Web of
Science, Scopus).

## See also

[`pmReferences`](https://massimoaria.github.io/pubmedR/reference/pmReferences.md)

[`pmFetchById`](https://massimoaria.github.io/pubmedR/reference/pmFetchById.md)

## Examples

``` r
if (FALSE) { # interactive()
# Find articles that cite PMID 25824007
cites <- pmCitedBy(pmid = "25824007")
cites$count
cites$cited_by
}
```
