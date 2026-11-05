# Extract references from PubMed XML records

Walks a result returned by
[`pmApiRequest`](https://massimoaria.github.io/pubmedR/reference/pmApiRequest.md)
or
[`pmFetchById`](https://massimoaria.github.io/pubmedR/reference/pmFetchById.md)
and pulls the `<ReferenceList>` block out of every record. Returns one
row per cited `<Reference>`, carrying the source PMID, the free-text
citation, and (when present) the cited PMID and DOI parsed from
`<ArticleIdList>`.

## Usage

``` r
pmExtractReferences(P)
```

## Arguments

- P:

  A list following the PubMed XML structure produced by
  [`pmApiRequest()`](https://massimoaria.github.io/pubmedR/reference/pmApiRequest.md)
  or
  [`pmFetchById()`](https://massimoaria.github.io/pubmedR/reference/pmFetchById.md).
  Must contain a `$data` element with one entry per record.

## Value

A data.frame with columns

|             |     |                                                   |
|-------------|-----|---------------------------------------------------|
| source_pmid |     | The PMID of the article that cites the reference. |
| citation    |     | The free-text `<Citation>` string from PubMed.    |
| pmid        |     | The PMID of the cited reference (if available).   |
| doi         |     | The DOI of the cited reference (if available).    |

Returns an empty data.frame (with the same schema) if no references are
found.

## Details

Reference data in PubMed XML is populated when the publisher submits a
`<ReferenceList>` block to NLM (which is now common, but not universal).
This function does not call any web API; it merely parses what is
already present in the XML. Use
[`pmEnrichCitations`](https://massimoaria.github.io/pubmedR/reference/pmEnrichCitations.md)
to also resolve cited PMIDs into structured WoS-style citation strings.

## See also

[`pmEnrichCitations`](https://massimoaria.github.io/pubmedR/reference/pmEnrichCitations.md),
[`pmFetchById`](https://massimoaria.github.io/pubmedR/reference/pmFetchById.md)

## Examples

``` r
if (FALSE) { # interactive()
D <- pmFetchById("37289732")
refs <- pmExtractReferences(D)
head(refs)
}
```
