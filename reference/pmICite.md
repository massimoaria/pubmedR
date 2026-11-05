# Citation metrics of PubMed articles from NIH iCite

It retrieves citation counts and field-normalised metrics from the NIH
iCite service, built on the NIH Open Citation Collection. No API key is
required.

## Usage

``` r
pmICite(pmids, batch_size = 500)
```

## Arguments

- pmids:

  is a character or numeric vector of PubMed identifiers (PMIDs).

- batch_size:

  is numeric. PMIDs per request, at most 1000. Default is 500.

## Value

a data frame with one row per PMID requested, in the same order, and the
columns:

|  |  |  |
|----|----|----|
| pmid |  | The PMID. |
| doi |  | The DOI. |
| year |  | The publication year. |
| citation_count |  | The number of citing articles. |
| citations_per_year |  | Citations per year since publication. |
| relative_citation_ratio |  | Citations compared with those expected in the article's field (1 is the NIH-funded median). |
| nih_percentile |  | The percentile of the ratio among NIH-funded articles. |
| is_research_article |  | Whether iCite classes it as primary research. |

A PMID unknown to iCite has `NA` in every other column.

## Details

PubMed itself counts only the citing articles in PubMed Central, so its
figures are usually much lower than those of iCite.

## See also

[`pmEnrichCitations`](https://massimoaria.github.io/pubmedR/reference/pmEnrichCitations.md),
[`pmCitedBy`](https://massimoaria.github.io/pubmedR/reference/pmCitedBy.md)

## Examples

``` r
if (FALSE) { # interactive()
pmICite(c("10171110", "25824007"))
}
```
