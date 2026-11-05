
<!-- README.md is generated from README.Rmd. Please edit that file -->

# pubmedR

<!-- badges: start -->

[![CRAN
status](https://www.r-pkg.org/badges/version/pubmedR)](https://CRAN.R-project.org/package=pubmedR)
[![CRAN
downloads](https://cranlogs.r-pkg.org/badges/pubmedR)](https://CRAN.R-project.org/package=pubmedR)
[![Project Status:
Active](https://www.repostatus.org/badges/latest/active.svg)](https://www.repostatus.org/#active)
[![R-CMD-check](https://github.com/massimoaria/pubmedR/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/massimoaria/pubmedR/actions/workflows/R-CMD-check.yaml)
<!-- badges: end -->

**pubmedR** downloads bibliographic records from
[PubMed](https://pubmed.ncbi.nlm.nih.gov/) through the NCBI API and
turns them into a data frame ready for analysis in R. The data frame
uses the field tags of [bibliometrix](https://www.bibliometrix.org), so
you can pass it straight to that package and to its Biblioshiny app.

## Installation

``` r
# The released version, from CRAN
install.packages("pubmedR")

# The development version, from GitHub
# install.packages("remotes")
remotes::install_github("massimoaria/pubmedR")
```

The API is free and needs no key. Without one, NCBI allows 3 requests
per second; with a [free API
key](https://account.ncbi.nlm.nih.gov/settings/) it allows 10. To use a
key in every session, add `PUBMED_API_KEY=your_key` to your `.Renviron`
file (`usethis::edit_r_environ()` opens it).

## Quick start

`pmCollect()` builds the query, downloads the records and converts them
in one call:

``` r
library(pubmedR)

M <- pmCollect(
  terms = "bibliometric*",
  language = "english",
  pub_type = "Review",
  date_range = c("2020", "2024"),
  limit = 5
)
```

``` r
knitr::kable(M[, c("PY", "TI", "SO")], row.names = FALSE)
```

| PY | TI | SO |
|---:|:---|:---|
| 2024 | DEVELOPING MEDICAL DEVICES WITH EMERGING TECHNOLOGIES: TRENDS, CHALLENGES, AND FUTURE DIRECTIONS. | F1000RESEARCH |
| 2024 | GEOPHYSICS FOR THE ENVIRONMENT IN INDONESIA. | F1000RESEARCH |
| 2024 | URBAN PLANNING EFFECTIVENESS AND CITIZEN SATISFACTION. A SYSTEMATIC LITERATURE REVIEW. | F1000RESEARCH |
| 2024 | BEYOND STROKE THERAPY, NEUROAID (A CHINESE HERBAL) HAS AN EFFECT ON COGNITION AND NEUROGENESIS, A BIBLIOMETRIC STUDY. | F1000RESEARCH |
| 2024 | TRENDS IN SMART RESTAURANT RESEARCH: BIBLIOMETRIC REVIEW AND RESEARCH AGENDA. | F1000RESEARCH |

## Step by step

For more control, run each step yourself. `pmQueryBuild()` writes the
query, or you can write your own in the [PubMed search
syntax](https://pubmed.ncbi.nlm.nih.gov/help/#search-tags):

``` r
query <- pmQueryBuild(
  terms = c("machine learning", "deep learning"),
  operator = "OR",
  mesh_terms = "Neoplasms",
  language = c("english", "italian"),
  date_range = c("2022", "2024")
)
query
#> [1] "(machine learning[Title/Abstract] OR deep learning[Title/Abstract]) AND Neoplasms[MeSH Terms] AND (english[LA] OR italian[LA]) AND 2022:2024[DP]"
```

Check how many records it finds before downloading them, and see how
they spread over the years:

``` r
pmQueryTotalCount(query)$total_count
#> [1] 12119

pmCountByYear(query, years = 2022:2024)
#>   year count
#> 1 2022  3378
#> 2 2023  4081
#> 3 2024  5699
```

Then download the records and convert them:

``` r
D <- pmApiRequest(query, limit = 20)
M <- pmApi2df(D)
```

``` r
dim(M)
#> [1] 20 33
```

PubMed serves at most 9,999 records per search. If you ask for more,
`pmApiRequest()` splits the query by the date records were added to
PubMed and downloads the parts in turn. The records then come in that
order, newest first, not in the order of the original search.

## Records you already know

Download records by PMID or by DOI. `pmFetchByDoi()` also tells you
which DOIs are not in PubMed:

``` r
by_pmid <- pmFetchById(c("10171110", "25824007"))

known <- pmApi2df(by_pmid)

by_doi <- pmFetchByDoi(c("10.1038/nature14539", "10.9999/not.a.real.doi"))
```

``` r
knitr::kable(known[, c("PMID", "PY", "TI")], row.names = FALSE)
```

| PMID | PY | TI |
|:---|---:|:---|
| 10171110 | 1991 | ANTERIOR CRUCIATE LIGAMENT REPLACEMENT: A REVIEW. |
| 25824007 | 2015 | AUTOANTIBODIES TARGETING GLOMERULAR ANNEXIN A2 IDENTIFY PATIENTS WITH PROLIFERATIVE LUPUS NEPHRITIS. |

``` r

by_doi$not_found
#> [1] "10.9999/not.a.real.doi"
```

## Citations

PubMed records carry no citation count, so `TC` is 0 after the download.
There are two sources for it. PubMed counts only the citing articles in
PubMed Central, and NIH iCite draws on a larger collection, so its
counts are usually higher:

``` r
pmCitedBy("10171110")$count
#> [1] 4

pmICite("10171110")[, c("pmid", "citation_count", "relative_citation_ratio")]
#>       pmid citation_count relative_citation_ratio
#> 1 10171110             19               0.9153152
```

`pmEnrichCitations()` fills in `TC`, along with the cited references
(`CR`) and their number (`NR`), for a whole data frame. Pass the
downloaded records as `P` to avoid fetching them again:

``` r
M <- pmEnrichCitations(M, P = D, tc_source = "icite", resolve_pmids = FALSE)
```

``` r
head(M[, c("PY", "TC", "NR")])
#>     PY TC NR
#> 1 2024  0 27
#> 2 2024  1 25
#> 3 2024  0 30
#> 4 2024  0 43
#> 5 2024  0 30
#> 6 2024  0 27
```

To list the references of one article, use `pmReferences()` or, for all
the records you downloaded, `pmExtractReferences()`.

## Analysis with bibliometrix

``` r
library(bibliometrix)

M <- convert2df(D, dbsource = "pubmed", format = "api")
results <- biblioAnalysis(M)
summary(results, k = 10)

# Or work in the app, which can also download from PubMed
biblioshiny()
```

## Main fields

| Field | Content |
|----|----|
| `AU`, `AF` | Authors, as surname and initials or in full |
| `TI`, `AB` | Title and abstract |
| `SO`, `JI`, `J9` | Journal, and its abbreviation |
| `PY` | Publication year |
| `DT`, `PT` | The first publication type, and all of them |
| `DE`, `ID`, `MESH` | Author keywords and MeSH terms |
| `C1`, `AU_UN` | Affiliations |
| `DI`, `PMID`, `PMCID` | Identifiers |
| `TC`, `CR`, `NR` | Citations, cited references and their number, after enrichment |

## Citation and help

To cite the package, run `citation("pubmedR")`. Report bugs or ask for
features in the [issues](https://github.com/massimoaria/pubmedR/issues).
