
<!-- README.md is generated from README.Rmd. Please edit that file -->

# pubmedR <img src="man/figures/logo.png" align="right" height="139" />

<!-- badges: start -->

[![CRAN
status](https://www.r-pkg.org/badges/version/pubmedR)](https://CRAN.R-project.org/package=pubmedR)
[![CRAN
downloads](https://cranlogs.r-pkg.org/badges/pubmedR)](https://CRAN.R-project.org/package=pubmedR)
[![Project Status:
Active](https://www.repostatus.org/badges/latest/active.svg)](https://www.repostatus.org/#active)
[![R-CMD-check](https://github.com/massimoaria/pubmedR/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/massimoaria/pubmedR/actions/workflows/R-CMD-check.yaml)
<!-- badges: end -->

**pubmedR** is an R package for gathering bibliographic metadata from
the [PubMed](https://pubmed.ncbi.nlm.nih.gov/) database using [NCBI
Entrez](https://www.ncbi.nlm.nih.gov/books/NBK25500/) REST APIs.

It provides a complete toolkit to **search**, **download**, **convert**,
and **enrich** PubMed records, with full compatibility with the
[bibliometrix](https://www.bibliometrix.org) R package for bibliometric
analysis.

## Core Functions

| Function              | Description                                        |
|-----------------------|----------------------------------------------------|
| `pmQueryBuild()`      | Build a PubMed query programmatically              |
| `pmQueryTotalCount()` | Count the number of records matching a query       |
| `pmApiRequest()`      | Download bibliographic metadata from PubMed        |
| `pmApi2df()`          | Convert downloaded XML data into a data frame      |
| `pmFetchById()`       | Download records by a list of PMIDs                |
| `pmCitedBy()`         | Find articles that cite a given article            |
| `pmReferences()`      | Find references cited by a given article           |
| `pmEnrichCitations()` | Add citation counts and references to a data frame |

## Installation

You can install the released version of pubmedR from
[CRAN](https://CRAN.R-project.org) with:

``` r
install.packages("pubmedR")
```

Or install the development version from
[GitHub](https://github.com/massimoaria/pubmedR):

``` r
# install.packages("devtools")
devtools::install_github("massimoaria/pubmedR")
```

## API Key Setup

Access to the NCBI PubMed API is free and does not necessarily require
an API key. However, without a key, NCBI limits requests to **3 per
second**. With a registered API key, the limit increases to **10 per
second**.

To obtain a free API key:

1.  Register for a [My NCBI
    account](https://www.ncbi.nlm.nih.gov/account/)
2.  Go to your [Account
    Settings](https://www.ncbi.nlm.nih.gov/account/settings/) and
    generate an API key

You can set the API key in three ways (in order of priority):

``` r
# Option 1: Pass it directly to functions
D <- pmApiRequest(query = query, limit = 100, api_key = "your_api_key")

# Option 2: Set the PUBMED_API_KEY environment variable in your .Renviron
# Run: usethis::edit_r_environ()
# Then add: PUBMED_API_KEY=your_api_key

# Option 3: Use the ENTREZ_KEY variable (rentrez convention)
# ENTREZ_KEY=your_api_key
```

When the API key is set via environment variable, all pubmedR functions
will use it automatically.

## Getting Started

``` r
library(pubmedR)
```

### Building a query

The `pmQueryBuild()` function helps you construct valid PubMed queries
programmatically:

``` r
# Build a query for bibliometric articles in English, published between 2015 and 2024
query <- pmQueryBuild(
  terms = "bibliometric*",
  fields = "Title/Abstract",
  language = "english",
  pub_type = "Journal Article",
  date_range = c("2015", "2024")
)

query
#> [1] "bibliometric*[Title/Abstract] AND english[LA] AND Journal Article[PT] AND 2015:2024[DP]"
```

You can also combine multiple terms and add MeSH filters:

``` r
# Combine multiple terms with OR
query_ml <- pmQueryBuild(
  terms = c("machine learning", "deep learning", "artificial intelligence"),
  fields = "Title/Abstract",
  operator = "OR",
  mesh_terms = "Neoplasms",
  language = "english",
  date_range = c("2020", "2024")
)

query_ml
#> [1] "(machine learning[Title/Abstract] OR deep learning[Title/Abstract] OR artificial intelligence[Title/Abstract]) AND Neoplasms[MeSH Terms] AND english[LA] AND 2020:2024[DP]"
```

Of course, you can also write the query string manually using the
[Entrez query
syntax](https://pubmed.ncbi.nlm.nih.gov/help/#search-tags):

``` r
query <- "bibliometric*[Title/Abstract] AND english[LA] AND Journal Article[PT] AND 2015:2024[DP]"
```

### Checking query results

Before downloading, check how many records match your query:

``` r
res <- pmQueryTotalCount(query = query)

res$total_count
#> [1] 12448
res$query_translation
#> [1] "\"bibliometric*\"[Title/Abstract] AND \"english\"[Language] AND \"journal article\"[Publication Type] AND 2015/01/01:2024/12/31[Date - Publication]"
```

### Downloading records

Download metadata for the matching records:

``` r
D <- pmApiRequest(query = query, limit = 200)
```

The `pmApiRequest()` function returns a list with five elements:

- **data**: XML-structured list of bibliographic metadata
- **query**: the original query
- **query_translation**: query translated by NCBI
- **records_downloaded**: number of records downloaded
- **total_count**: total number of matching records

### Converting to a data frame

Convert the downloaded XML data into a structured data frame:

``` r
M <- pmApi2df(D, format = "bibliometrix")
```

``` r
dplyr::glimpse(M)
#> Rows: 200
#> Columns: 30
#> $ AU        <chr> "LLONTO CAICEDO Y;MORÁN SANTAMARÍA RO;ALARCÓN VILLANUEVA G;Z…
#> $ AF        <chr> "LLONTO CAICEDO, YEFFERSON;MORÁN SANTAMARÍA, ROGGER ORLANDO;…
#> $ TI        <chr> "URBAN PLANNING EFFECTIVENESS AND CITIZEN SATISFACTION. A SY…
#> $ SO        <chr> "F1000RESEARCH", "F1000RESEARCH", "JOURNAL OF ORTHOPAEDICS",…
#> $ SO_CO     <chr> "ENGLAND", "ENGLAND", "INDIA", "SAUDI ARABIA", "ENGLAND", "U…
#> $ LA        <chr> "ENG", "ENG", "ENG", "ENG", "ENG", "ENG", "ENG", "ENG", "ENG…
#> $ DT        <chr> "JOURNAL ARTICLE", "JOURNAL ARTICLE", "JOURNAL ARTICLE", "JO…
#> $ DE        <chr> "PRISMA;BIBLIOMETRICS;BIBLIOMETRIX;CITIZEN SATISFACTION;STAT…
#> $ ID        <chr> "CITY PLANNING;HUMANS;PERSONAL SATISFACTION;QUALITY OF LIFE;…
#> $ MESH      <chr> "CITY PLANNING;HUMANS;PERSONAL SATISFACTION;QUALITY OF LIFE;…
#> $ AB        <chr> "THE POPULATION IS INCREASINGLY DEMANDING A BETTER QUALITY O…
#> $ C1        <chr> "LAMBAYEQUE, UNIVERSIDAD NACIONAL PEDRO RUIZ GALLO, LAMBAYEQ…
#> $ CR        <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
#> $ TC        <dbl> 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, …
#> $ SN        <chr> "2046-1402", "2046-1402", "0972-978X", "1013-9052", "2046-14…
#> $ J9        <chr> "F1000RES", "F1000RES", "J ORTHOP", "SAUDI DENT J", "F1000RE…
#> $ JI        <chr> "F1000RES", "F1000RES", "J ORTHOP", "SAUDI DENT J", "F1000RE…
#> $ PY        <dbl> 2025, 2025, 2024, 2024, 2025, 2024, 2024, 2024, 2025, 2024, …
#> $ PY_IS     <chr> "2024", "2024", "2025", "2024", "2024", "2024", "2025", "202…
#> $ VL        <chr> "13", "13", "66", "36", "13", "2024", "86", "17", "4", "17",…
#> $ DI        <chr> "10.12688/f1000research.157550.2", "10.12688/f1000research.1…
#> $ PG        <chr> "1330", "799", "110-118", "1521-1526", "1505", "6199860", "5…
#> $ GRANT_ID  <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
#> $ GRANT_ORG <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
#> $ UT        <chr> "41287786", "41024939", "40978518", "40952837", "40919447", …
#> $ PMID      <chr> "41287786", "41024939", "40978518", "40952837", "40919447", …
#> $ DB        <chr> "PUBMED", "PUBMED", "PUBMED", "PUBMED", "PUBMED", "PUBMED", …
#> $ AU_UN     <chr> "LAMBAYEQUE, UNIVERSIDAD NACIONAL PEDRO RUIZ GALLO, LAMBAYEQ…
#> $ AU_CO     <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
#> $ AU1_CO    <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
```

The `format = "bibliometrix"` option (default) creates a data frame
fully compatible with the [bibliometrix](https://www.bibliometrix.org)
package, using standard bibliometric field tags:

| Tag | Description         |
|-----|---------------------|
| AU  | Authors             |
| TI  | Title               |
| SO  | Source (Journal)    |
| AB  | Abstract            |
| DE  | Author Keywords     |
| ID  | MeSH Terms          |
| DI  | DOI                 |
| PY  | Publication Year    |
| C1  | Author Affiliations |
| TC  | Times Cited         |
| CR  | Cited References    |
| …   | and more            |

## Fetching Records by PMID

If you already have a list of PubMed IDs, use `pmFetchById()` to
download their metadata directly:

``` r
pmids <- c("25824007", "28981534", "31414462")
D_pmid <- pmFetchById(pmids = pmids)
```

``` r
M_pmid <- pmApi2df(D_pmid)
```

``` r
M_pmid[, c("AU", "PY", "TI", "SO")]
#>                                                                                                                         AU
#> 1 CASTER DJ;KORTE EA;MERCHANT ML;KLEIN JB;WILKEY DW;ROVIN BH;BIRMINGHAM DJ;HARLEY JB;COBB BL;NAMJOU B;MCLEISH KR;POWELL DW
#> 2                                        GLÜGE J;STEINLIN C;SCHALLES S;WEGMANN L;TREMP J;BREIVIK K;HUNGERBÜHLER K;BOGDAL C
#> 3                                                                                                                      EO 
#>     PY
#> 1 2014
#> 2 2017
#> 3 2019
#>                                                                                                     TI
#> 1 AUTOANTIBODIES TARGETING GLOMERULAR ANNEXIN A2 IDENTIFY PATIENTS WITH PROLIFERATIVE LUPUS NEPHRITIS.
#> 2                                 IMPORT, USE, AND EMISSIONS OF PCBS IN SWITZERLAND FROM 1930 TO 2100.
#> 3                                                                                     [NOT AVAILABLE].
#>                                  SO
#> 1 PROTEOMICS. CLINICAL APPLICATIONS
#> 2                          PLOS ONE
#> 3      MMW FORTSCHRITTE DER MEDIZIN
```

## Citation Enrichment

PubMed does not provide citation counts or reference lists by default.
pubmedR can enrich your data using the NCBI E-Link service.

### Citations for a single article

``` r
# Find who cited a specific article (PMID: 25824007)
cites <- pmCitedBy(pmid = "25824007")
cat("Number of citing articles:", cites$count, "\n")
#> Number of citing articles: 31
cat("First 5 citing PMIDs:", paste(head(cites$cited_by, 5), collapse = ", "), "\n")
#> First 5 citing PMIDs: 41021815, 40889685, 39057791, 38891801, 37955107
```

### References of a single article

``` r
# Find the references of an article
refs <- pmReferences(pmid = "25824007")
cat("Number of references:", refs$count, "\n")
#> Number of references: 62
cat("First 5 reference PMIDs:", paste(head(refs$references, 5), collapse = ", "), "\n")
#> First 5 reference PMIDs: 25533130, 25273097, 25248362, 24845390, 24790181
```

### Batch enrichment of a data frame

Use `pmEnrichCitations()` to add citation data (TC and CR fields) to an
entire data frame:

``` r
# Enrich the small PMID dataset with citation data
M_enriched <- pmEnrichCitations(M_pmid)
```

``` r
M_enriched[, c("AU", "PY", "TC", "CR")]
#>                                                                                                                         AU
#> 1 CASTER DJ;KORTE EA;MERCHANT ML;KLEIN JB;WILKEY DW;ROVIN BH;BIRMINGHAM DJ;HARLEY JB;COBB BL;NAMJOU B;MCLEISH KR;POWELL DW
#> 2                                        GLÜGE J;STEINLIN C;SCHALLES S;WEGMANN L;TREMP J;BREIVIK K;HUNGERBÜHLER K;BOGDAL C
#> 3                                                                                                                      EO 
#>     PY TC
#> 1 2014 31
#> 2 2017  2
#> 3 2019  0
#>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            CR
#> 1 25533130;25273097;25248362;24845390;24790181;24726496;24649358;24319012;24225319;23928303;23867502;23833315;23615266;23519104;23118496;22958486;22879587;22850877;22811486;22706085;22493061;22433915;22189356;22162716;22159597;22129255;22025085;21964468;21640210;21478284;20864496;20847146;20664558;20414746;20090510;19836472;19571279;18773185;18565825;18064521;17907141;17803907;17274980;16723695;16522749;16210453;15601747;15339978;15040839;14717922;14632076;12957142;12861023;12858447;12824285;12403597;11856766;11402500;10802651;10616834;9224761;8647942
#> 2                                                                                                                                                                                                                                                                                                                                    27876229;27313021;27015905;26889948;26766430;26646689;26632968;26172591;25622721;25548829;24999726;24392941;20848233;20446692;20384373;19957996;17395248;16829543;16190235;15871225;15663299;15091669;12083710;12083709;11951941;9831538
#> 3                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        <NA>
```

## Integration with bibliometrix

pubmedR is designed to work seamlessly with
[bibliometrix](https://www.bibliometrix.org) and its Shiny interface
[biblioshiny](https://www.bibliometrix.org/home/index.php/layout/biblioshiny).

``` r
library(bibliometrix)

# Convert and analyze
M <- convert2df(D, dbsource = "pubmed", format = "api")
results <- biblioAnalysis(M)
summary(results)

# Or launch the interactive dashboard
biblioshiny()
```

The data frame produced by `pmApi2df()` uses the same field tags as
bibliometrix, so it can be directly used with all bibliometrix
functions: `biblioAnalysis()`, `biblioNetwork()`, `thematicMap()`,
`conceptualStructure()`, and more.

## Workflow Summary

The typical pubmedR workflow follows these steps:

                                       +-------------------+
                                       | pmQueryBuild()    |
                                       | Build query       |
                                       +---------+---------+
                                                 |
                                                 v
                                       +-------------------+
                                       | pmQueryTotalCount()|
                                       | Check result count|
                                       +---------+---------+
                                                 |
                                  +--------------+--------------+
                                  |                             |
                                  v                             v
                        +-------------------+         +-------------------+
                        | pmApiRequest()    |         | pmFetchById()     |
                        | Search & download |         | Download by PMID  |
                        +---------+---------+         +---------+---------+
                                  |                             |
                                  +-------------+---------------+
                                                |
                                                v
                                      +-------------------+
                                      | pmApi2df()        |
                                      | Convert to df     |
                                      +---------+---------+
                                                |
                                                v
                                      +-------------------+
                                      | pmEnrichCitations()|
                                      | Add TC & CR       |
                                      +---------+---------+
                                                |
                                                v
                                      +-------------------+
                                      | bibliometrix      |
                                      | Analyze & explore |
                                      +-------------------+

## About PubMed

[PubMed](https://pubmed.ncbi.nlm.nih.gov/) is a free search engine
maintained by the National Center for Biotechnology Information (NCBI)
at the U.S. National Library of Medicine (NLM). It provides access to
over **36 million** citations and abstracts of biomedical literature
from MEDLINE, life science journals, and online books.

pubmedR uses the [NCBI E-utilities
API](https://www.ncbi.nlm.nih.gov/books/NBK25500/), which provides
programmatic access to PubMed data including:

- **ESearch**: Search and retrieve a list of matching record IDs
- **EFetch**: Download full records in XML format
- **ELink**: Find related records (citations, references)

## Citation

If you use pubmedR in your research, please cite it as:

``` r
citation("pubmedR")
```

> Aria, M. (2023). *pubmedR: Gathering Metadata About Publications,
> Grants, Clinical Trials from PubMed Database*. R package.
> <https://github.com/massimoaria/pubmedR>

## Community

- Report bugs or request features at:
  <https://github.com/massimoaria/pubmedR/issues>
- For bibliometric analysis: <https://www.bibliometrix.org>
- NCBI API documentation: <https://www.ncbi.nlm.nih.gov/books/NBK25500/>
