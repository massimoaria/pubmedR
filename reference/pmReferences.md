# Find references cited by a given PubMed article

It retrieves the PMIDs of articles that are cited by (referenced in) a
given PubMed article, using the NCBI E-Link service.

## Usage

``` r
pmReferences(pmid, api_key = NULL)
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

|  |  |  |
|----|----|----|
| pmid |  | The queried PMID. |
| references |  | A character vector of PMIDs referenced by the queried article. |
| count |  | The number of references found. |

## Details

This function uses the NCBI E-Link endpoint with linkname
"pubmed_pubmed_refs" to find articles in PubMed that are referenced by
the given article.

Note: Reference data is extracted from PubMed Central (PMC) full-text
articles and is only available when the full text is deposited in PMC.
Not all PubMed articles have reference data available.

## See also

[`pmCitedBy`](https://massimoaria.github.io/pubmedR/reference/pmCitedBy.md)

[`pmFetchById`](https://massimoaria.github.io/pubmedR/reference/pmFetchById.md)

## Examples

``` r
if (FALSE) { # interactive()
# Find references of PMID 25824007
refs <- pmReferences(pmid = "25824007")
refs$count
refs$references
}
```
