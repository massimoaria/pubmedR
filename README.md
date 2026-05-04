
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
| `pmCollect()`         | One-step wrapper for the full workflow             |

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

1.  Register for a [My NCBI account](https://account.ncbi.nlm.nih.gov/)
2.  Go to your [Account
    Settings](https://account.ncbi.nlm.nih.gov/settings/) and generate
    an API key

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

### Quick start with `pmCollect()`

The fastest way to get PubMed data into R is `pmCollect()`, which
handles the entire workflow in a single call:

``` r
# Collect bibliometric articles published between 2020 and 2024
M <- pmCollect(
  terms = "bibliometric*",
  language = "english",
  pub_type = "Journal Article",
  date_range = c("2020", "2024"),
  limit = 10
)
```

``` r
M[, c("AU", "PY", "TI", "SO")]
#>                                                                                                                                                                           AU
#> 1  LLONTO CAICEDO Y;MORÁN SANTAMARÍA RO;ALARCÓN VILLANUEVA G;ZAVALETA GONZÁLES LN;LLATAS DÍAZ WD;PACHECO GONZALES IB;PEJERREY GONZÁLEZ RJ;CASTRO MEJÍA PJ;ATALAYA URRUTIA CW
#> 2                                                                                                                                SALEH AY;VALENTINA R;SUSANTO TD;SAPUTRA DAY
#> 3                                                                                                    VELASQUEZ GARCIA A;MINAMI M;MEJIA-RODRÍGUEZ M;ORTÍZ-MORALES JR;RADICE F
#> 4                                                                                                                  MUNAGA S;ALSHEHRI A;UL-HAQ I;KALAGI S;CHITUMALLA R;IYER K
#> 5         VALENCIA-ARIAS A;CARDONA-ACEVEDO S;MARTÍNEZ ROJAS E;RAMÍREZ DÁVILA J;RODRIGUEZ-CORREA P;PALACIOS-MOYA L;TEODORI DE LA PUENTE R;AGUDELO-CEBALLOS E;BENJUMEA-ARIAS M
#> 6                                                                                                                                   JIANG F;LI X;QIAO Q;ZHANG G;ZHANG Y;SU L
#> 7                                                                      DYESS GA;GHALIB MA;TAYLOR Z;SABETTA Z;TAYLOR E;BUTLER D;BASSETT M;HARRIS L;BOLUS H;SHAHID A;THAKUR JD
#> 8                                                                                                                NAVARRETE CB;CASTILLO LV;QUIÑONES AS;RODRÍGUEZ IR;MORENO LS
#> 9                                                                                                                                                 MARTINHO VJPD;BRÓZDOWSKI J
#> 10                                                                                                                                  PHANG KC;NG TC;SINGH SKG;VOO TC;ALVIS WA
#>      PY
#> 1  2025
#> 2  2025
#> 3  2024
#> 4  2024
#> 5  2025
#> 6  2024
#> 7  2024
#> 8  2024
#> 9  2025
#> 10 2024
#>                                                                                                                                                              TI
#> 1                                                                        URBAN PLANNING EFFECTIVENESS AND CITIZEN SATISFACTION. A SYSTEMATIC LITERATURE REVIEW.
#> 2                                         BEYOND STROKE THERAPY, NEUROAID (A CHINESE HERBAL) HAS AN EFFECT ON COGNITION AND NEUROGENESIS, A BIBLIOMETRIC STUDY.
#> 3                                             LARGE LANGUAGE MODELS IN ORTHOPEDICS: AN EXPLORATORY RESEARCH TREND ANALYSIS AND MACHINE LEARNING CLASSIFICATION.
#> 4                                                                      SAUDI ARABIA'S CONTRIBUTION TO SYSTEMATIC REVIEWS IN DENTISTRY: A BIBLIOMETRIC ANALYSIS.
#> 5                                                                                 TRENDS IN SMART RESTAURANT RESEARCH: BIBLIOMETRIC REVIEW AND RESEARCH AGENDA.
#> 6  KNOWLEDGE MAPPING OF ASPERGILLUS-RELATED RESEARCH IN RESPIRATORY MEDICINE: A BIBLIOMETRIC ANALYSIS BASED ON ENGLISH-LANGUAGE ARTICLES SPANNING 1975 TO 2022.
#> 7                                                       CAREERS IN SKULL BASE AND OPEN CEREBROVASCULAR SURGERY: FACTORS ASSOCIATED WITH ACADEMIC JOB PLACEMENT.
#> 8                                                     INTERNATIONALIZATION AND COLLABORATION IN COLOMBIAN PSYCHOLOGY DURING 2014-2023: A BIBLIOMETRIC ANALYSIS.
#> 9                                                                                              SUGGESTIONS FOR RESIN RESEARCH UNDER THE COST ACTION EU-POTARCH.
#> 10                              NAVIGATING ARTIFICIAL INTELLIGENCE IN MALAYSIAN HEALTHCARE: RESEARCH DEVELOPMENTS, ETHICAL DILEMMAS, AND GOVERNANCE STRATEGIES.
#>                                                     SO
#> 1                                        F1000RESEARCH
#> 2                                        F1000RESEARCH
#> 3                              JOURNAL OF ORTHOPAEDICS
#> 4                             THE SAUDI DENTAL JOURNAL
#> 5                                        F1000RESEARCH
#> 6                         CANADIAN RESPIRATORY JOURNAL
#> 7  JOURNAL OF NEUROLOGICAL SURGERY. PART B, SKULL BASE
#> 8              PSYCHOLOGY IN RUSSIA : STATE OF THE ART
#> 9                                 OPEN RESEARCH EUROPE
#> 10                              ASIAN BIOETHICS REVIEW
```

You can also pass a raw query string and enable citation enrichment:

``` r
M_enriched <- pmCollect(
  query = "bibliometric*[Title/Abstract] AND english[LA] AND 2023:2024[DP]",
  limit = 5,
  enrich = TRUE
)
```

``` r
M_enriched[, c("AU", "PY", "TC")]
#>                                                                                                                                                                          AU
#> 1 LLONTO CAICEDO Y;MORÁN SANTAMARÍA RO;ALARCÓN VILLANUEVA G;ZAVALETA GONZÁLES LN;LLATAS DÍAZ WD;PACHECO GONZALES IB;PEJERREY GONZÁLEZ RJ;CASTRO MEJÍA PJ;ATALAYA URRUTIA CW
#> 2                                                                                                                               SALEH AY;VALENTINA R;SUSANTO TD;SAPUTRA DAY
#> 3                                                                                                   VELASQUEZ GARCIA A;MINAMI M;MEJIA-RODRÍGUEZ M;ORTÍZ-MORALES JR;RADICE F
#> 4                                                                                                                 MUNAGA S;ALSHEHRI A;UL-HAQ I;KALAGI S;CHITUMALLA R;IYER K
#> 5        VALENCIA-ARIAS A;CARDONA-ACEVEDO S;MARTÍNEZ ROJAS E;RAMÍREZ DÁVILA J;RODRIGUEZ-CORREA P;PALACIOS-MOYA L;TEODORI DE LA PUENTE R;AGUDELO-CEBALLOS E;BENJUMEA-ARIAS M
#>     PY TC
#> 1 2025  0
#> 2 2025  0
#> 3 2024  1
#> 4 2024  0
#> 5 2025  0
```

For more control over each step, you can use the individual functions
described below.

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
#> [1] 12451
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
#> Columns: 31
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
#> $ IS        <chr> NA, NA, NA, "12", NA, NA, "5", "4", NA, "3", "1", "4", NA, N…
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
#>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  CR
#> 1                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        TSOKOS GC, 2011, N ENGL J MED, V365, P2110, DOI 10.1056/NEJMRA1100359; COZZANI E, 2013, AUTOIMMUNE DIS, V2014, P321359, DOI 10.1155/2014/321359; BHINDER S, 2010, AM J MED SCI, V339, P230, DOI 10.1097/MAJ.0B013E3181C9529C; WEENING JJ, 2004, KIDNEY INT, V65, P521, DOI 10.1111/J.1523-1755.2004.00443.X; MANNIK M, 2003, J RHEUMATOL, V30, P1495; SERET G, 2011, CLIN DEV IMMUNOL, V2012, P579670, DOI 10.1155/2012/579670; HANROTEL-SALIOU C, 2010, CLIN REV ALLERGY IMMUNOL, V40, P151, DOI 10.1007/S12016-010-8204-4; OLSON SW, 2013, CLIN J AM SOC NEPHROL, V8, P1702, DOI 10.2215/CJN.01910213; KALAAJI M, 2006, AM J PATHOL, V168, P1779, DOI 10.2353/AJPATH.2006.051329; BIRMINGHAM DJ, 2012, LUPUS, V21, P855, DOI 10.1177/0961203312439640; RASMUSSEN A, 2010, RHEUMATOLOGY (OXFORD), V50, P47, DOI 10.1093/RHEUMATOLOGY/KEQ302; YAMAMOTO T. RENAL AND URINARY PROTEOMICS. WILEY-VCH VERLAG GMBH & CO. KGAA; 2009. PP. 1–7.; SALEEM MA, 2002, J AM SOC NEPHROL, V13, P630, DOI 10.1681/ASN.V133630; BECK LH, 2009, N ENGL J MED, V361, P11, DOI 10.1056/NEJMOA0810457; POWELL DW, 2003, MOL CELL BIOL, V23, P5376, DOI 10.1128/MCB.23.15.5376-5387.2003; CUMMINS TD, 2009, BIOCHIM BIOPHYS ACTA, V1804, P653, DOI 10.1016/J.BBAPAP.2009.09.029; BABA SP, 2013, J BIOL CHEM, V288, P28163, DOI 10.1074/JBC.M113.504753; KELLER A, 2002, ANAL CHEM, V74, P5383, DOI 10.1021/AC025747H; NESVIZHSKII AI, 2003, ANAL CHEM, V75, P4646, DOI 10.1021/AC0341261; ASHBURNER M, 2000, NAT GENET, V25, P25, DOI 10.1038/75556; SEILER CY, 2013, NUCLEIC ACIDS RES, V42, PD1253, DOI 10.1093/NAR/GKT1060; DELVILLE M, 2014, SCI TRANSL MED, V6, P256RA136, DOI 10.1126/SCITRANSLMED.3008538; LEFRANC D, 2007, ARTHRITIS RHEUM, V56, P3420, DOI 10.1002/ART.22863; REISER J, 2000, J AM SOC NEPHROL, V11, P1, DOI 10.1681/ASN.V1111; PERYSINAKI GS, 2011, LUPUS, V20, P781, DOI 10.1177/0961203310397412; WELSH GI, 2011, NAT REV NEPHROL, V8, P14, DOI 10.1038/NRNEPH.2011.151; GREKA A, 2012, SEMIN NEPHROL, V32, P319, DOI 10.1016/J.SEMNEPHROL.2012.06.003; GEE HY, 2013, J CLIN INVEST, V123, P3243, DOI 10.1172/JCI69134; MEYER-SCHWESINGER C, 2012, AM J PHYSIOL RENAL PHYSIOL, V303, PF1015, DOI 10.1152/AJPRENAL.00380.2011; BHARADWAJ A, 2013, INT J MOL SCI, V14, P6259, DOI 10.3390/IJMS14036259; YUNG S, 2010, J AM SOC NEPHROL, V21, P1912, DOI 10.1681/ASN.2009080805; PIERCHALA BA, 2010, KIDNEY INT, V78, P868, DOI 10.1038/KI.2010.212; MARKOFF A, 2005, AM J PHYSIOL RENAL PHYSIOL, V289, PF949, DOI 10.1152/AJPRENAL.00089.2005; RESCHER U, 2008, J CELL SCI, V121, P2177, DOI 10.1242/JCS.028415; CAÑAS F, 2014, THROMB RES, V135, P226, DOI 10.1016/J.THROMRES.2014.11.034; MARTIN M, 2012, J BIOL CHEM, V287, P33733, DOI 10.1074/JBC.M112.341339; LEFFLER J, 2014, ANN RHEUM DIS, V73, P1601, DOI 10.1136/ANNRHEUMDIS-2014-205287; DÍAZ-RAMOS A, 2012, J BIOMED BIOTECHNOL, V2012, P156795, DOI 10.1155/2012/156795; BRUSCHI M, 2014, J AM SOC NEPHROL, V25, P2483, DOI 10.1681/ASN.2013090987; BRUSCHI M, 2011, J PROTEOMICS, V74, P2008, DOI 10.1016/J.JPROT.2011.05.021; HSU HH, 2007, J MOL MED (BERL), V86, P1379, DOI 10.1007/S00109-008-0399-Y; HUGO C, 1996, J CLIN INVEST, V97, P2499, DOI 10.1172/JCI118697; SUZUKI K, 2013, NEPHROL DIAL TRANSPLANT, V29, P1168, DOI 10.1093/NDT/GFT469; DOYLE A, 2011, J STRUCT BIOL, V176, P370, DOI 10.1016/J.JSB.2011.09.004; WIEGE K, 2012, J IMMUNOL, V189, P980, DOI 10.4049/JIMMUNOL.1200891; ZHOU CJ, 2003, EXP EYE RES, V77, P423, DOI 10.1016/S0014-4835(03)00171-4; ZANIN-ZHOROV A, 2003, FASEB J, V17, P1567, DOI 10.1096/FJ.02-1139FJE; LANG A, 2004, J AM SOC NEPHROL, V16, P383, DOI 10.1681/ASN.2004040276; HURST IR, 2003, J BONE MINER RES, V19, P499, DOI 10.1359/JBMR.0301238; AKIYAMA K, 2007, MAMM GENOME, V19, P41, DOI 10.1007/S00335-007-9078-5; LU Y, 2011, MOL CELL PROTEOMICS, V11, PM111.008755, DOI 10.1074/MCP.M111.008755; LIN CP, 2011, GENES IMMUN, V13, P232, DOI 10.1038/GENE.2011.82; CHEN HH, 2012, MOL CELL BIOL, V32, P2224, DOI 10.1128/MCB.06550-11; KREMER BE, 2006, CELL, V130, P837, DOI 10.1016/J.CELL.2007.06.053; ROSENTRETER A, 2006, EXP CELL RES, V313, P878, DOI 10.1016/J.YEXCR.2006.12.015; LIANG P, 1997, J CELL SCI, V110 ( PT 13), P1431, DOI 10.1242/JCS.110.13.1431; KHUNKEAWLA P, 2001, IMMUNOBIOLOGY, V203, P659, DOI 10.1016/S0171-2985(01)80015-2; KOSUGI T, 2014, NEPHROL DIAL TRANSPLANT, V30, P1097, DOI 10.1093/NDT/GFU302; WASIK AA, 2013, AM J PATHOL, V184, P1727, DOI 10.1016/J.AJPATH.2014.03.002; OSTALSKA-NOWICKA D, 2006, J CLIN PATHOL, V59, P916, DOI 10.1136/JCP.2005.031732; AHN YH, 2012, J CLIN INVEST, V122, P3170, DOI 10.1172/JCI63608; SCHMIEDER S, 2004, J AM SOC NEPHROL, V15, P2289, DOI 10.1097/01.ASN.0000135968.49899.E8; ZHA D, 2013, BMB REP, V46, P230, DOI 10.5483/BMBREP.2013.46.4.270
#> 2 HALSE AK, SCHLABACH M, ECKHARDT S, SWEETMAN AJ, JONES KC, BREIVIK K. SPATIAL VARIABILITY OF POPS IN EUROPEAN BACKGROUND AIR. ATMOS CHEM PHYS. 2011;11(4):1549–1564. 10.5194/ACP-11-1549-2011; BOGDAL C, 2010, ENVIRON SCI TECHNOL, V44, P4063, DOI 10.1021/ES903007H; LI YF, 2010, ENVIRON SCI TECHNOL, V44, P2784, DOI 10.1021/ES901871E; JEPSON PD, 2015, SCI REP, V6, P18573, DOI 10.1038/SREP18573; WÖHRNSCHIMMEL H, 2015, ENVIRON POLLUT, V217, P149, DOI 10.1016/J.ENVPOL.2016.01.090; JEPSON PD, 2016, SCIENCE, V352, P1388, DOI 10.1126/SCIENCE.AAF9075; LRTAP. CONVENTION ON LONG-RANGE TRANSBOUNDARY AIR POLLUTION; 1979. AVAILABLE FROM: HTTPS://WWW.UNECE.ORG/FILEADMIN/DAM/ENV/LRTAP/FULLTEXT/1979.CLRTAP.E.PDF; UNECE. PROTOCOL TO THE 1979 CONVENTION ON LONG-RANGE TRANSBOUNDARY AIR POLLUTION ON PERSISTENT ORGANIC POLLUTANTS. UNITED NATIONS ECONOMIC COMMISSION FOR EUROPE (UNECE); 1998. AVAILABLE FROM: HTTP://WWW.UNECE.ORG/FILEADMIN/DAM/ENV/LRTAP/FULLTEXT/1998.POPS.E.PDF; UNECE. GUIDELINES FOR REPORTING EMISSIONS AND PROJECTIONS DATA UNDER THE CONVENTION ON LONG-RANGE TRANSBOUNDARY AIR POLLUTION (ECE/EB-AIR/97). UNITED NATIONS ECONOMIC COMMISSION FOR EUROPE (UNECE); 2009. AVAILABLE FROM: HTTPS://WWW.UNECE.ORG/FILEADMIN/DAM/ENV/DOCUMENTS/2012/AIR/GUIDELINES_FOR_REPORTING_EMISSION_DATA_UNDER_THE_CLRTAP.PDF; EEA. EMEP/EEA AIR POLLUTANT EMISSION INVENTORY GUIDEBOOK 2016. TECHNICAL GUIDANCE TO PREPARE NATIONAL EMISSION INVENTORIES. COPENHAGEN, DENMARK: EUROPEAN ENVIRONMENTAL AGENCY (EEA); 2016. AVAILABLE FROM: HTTP://WWW.EEA.EUROPA.EU/PUBLICATIONS/EMEP-EEA-GUIDEBOOK-2016/PART-B-SECTORAL-GUIDANCE-CHAPTERS/5-WASTE; UNECE. THE 1998 PROTOCOL ON PERSISTENT ORGANIC POLLUTANTS, INCLUDING THE AMENDMENTS ADOPTED BY THE PARTIES ON 18 DECEMBER 2009. UNITED NATIONS ECONOMIC COMMISSION FOR EUROPE (UNECE); 2010. AVAILABLE FROM: HTTP://WWW.UNECE.ORG/FILEADMIN/DAM/ENV/LRTAP/FULLTEXT/ECE.EB.AIR.104.E.PDF; FOEN. SWITZERLAND’S INFORMATIVE INVENTORY REPORT 2015 (IIR) SUBMISSION UNDER THE UNECE CONVENTION ON LONG-RANGE TRANSBOUNDARY AIR POLLUTION. FEDERAL OFFICE FOR THE ENVIRONMENT (FOEN); 2015.; CUI S, 2014, SCI TOTAL ENVIRON, V533, P247, DOI 10.1016/J.SCITOTENV.2015.06.144; HU D, 2009, ENVIRON SCI TECHNOL, V44, P2822, DOI 10.1021/ES902413K; BREIVIK K, 2002, SCI TOTAL ENVIRON, V290, P199, DOI 10.1016/S0048-9697(01)01076-2; BREIVIK K, 2006, SCI TOTAL ENVIRON, V377, P296, DOI 10.1016/J.SCITOTENV.2007.02.026; VAN DEN BERG M, 1998, ENVIRON HEALTH PERSPECT, V106, P775, DOI 10.1289/EHP.98106775; VAN DEN BERG M, 2006, TOXICOL SCI, V93, P223, DOI 10.1093/TOXSCI/KFL055; FRAME GM, COCHRAN JW, BØWADT SS. COMPLETE PCB CONGENER DISTRIBUTIONS FOR 17 AROCLOR MIXTURES DETERMINED BY 3 HRGC SYSTEMS OPTIMIZED FOR COMPREHENSIVE, QUANTITATIVE, CONGENER-SPECIFIC ANALYSIS. J HIGH RESOLUT CHROMATOGR. 1996;19:657–668. 10.1002/JHRC.1240191202; TANIYASU S, 2005, J ENVIRON SCI HEALTH A TOX HAZARD SUBST ENVIRON ENG, V40, P43, DOI 10.1081/ESE-200033521; BREIVIK K, 2002, SCI TOTAL ENVIRON, V290, P181, DOI 10.1016/S0048-9697(01)01075-0; TAKASUGA T, INOUE T, ISHIDA T, IRELAND P. DETERMINATION OF THE COMPOSITION OF THE COMMERCIAL PCBS: KANECHLOR, CLOPHEN, AROCLOR, CHLOROFEN, AND SOVOL, BY HRGC-HRMS. ORGANOHALOGEN COMPD. 1996;27:391–396.; ERICKSON MD, 2010, ENVIRON SCI POLLUT RES INT, V18, P135, DOI 10.1007/S11356-010-0392-1; HARRAD SJ, 1992, ENVIRON POLLUT, V85, P131, DOI 10.1016/0269-7491(94)90079-5; BUWAL. PRAXISHILFE: PCB-EMISSIONEN BEIM KORROSIONSSCHUTZ. BERN, SWITZERLAND: BUNDESAMT FÜR UMWELT, WALD UND LANDSCHAFT; 2000.; UNECE. GUIDELINES FOR REPORTING EMISSIONS AND PROJECTIONS DATA UNDER THE CONVENTION ON LONG-RANGE TRANSBOUNDARY AIR POLLUTION (ECE/EB.AIR/128). UNITED NATIONS ECONOMIC COMMISSION FOR EUROPE (UNECE); 2015. AVAILABLE FROM: HTTP://WWW.UNECE.ORG/FILEADMIN/DAM/ENV/DOCUMENTS/2015/AIR/EB/ENGLISH.PDF; BUWAL. ZUR KONTROLLE UND ENTSORGUNG POLYCHLORIERTER BIPHENYLE IN DER SCHWEIZ. SCHRIFTENREIHE UMWELTSCHUTZ NR. 25. BERN, SWITZERLAND: BUNDESAMT FÜR UMWELTSCHUTZ; 1984.; BUWAL. SCHUTZ VOR UMWELTSCHÄDEN DURCH PCB-HALTIGE KONDENSATOREN UND TRANSFORMATOREN. SCHRIFTENREIHE UMWELTSCHUTZ NR. 90. BERN, SWITZERLAND: BUNDESAMT FÜR UMWELTSCHUTZ; 1988.; DE VOOGT P, BRINKMAN UAT. PRODUCTION, PROPERTIES AND USAGE OF POLYCHLORINATED BIPHENYLS. IN: HALOGENATED BIPHENYLS, TERPHENYLS, NAPHTALENES, DIBENZODIOXINS RELAT. PROD.; 1989.; GLÜGE J, 2015, SCI TOTAL ENVIRON, V550, P1152, DOI 10.1016/J.SCITOTENV.2016.01.097; STEINLIN C, 2014, ENVIRON SCI TECHNOL, V48, P7849, DOI 10.1021/ES501793H; STEINLIN C, 2015, ENVIRON SCI TECHNOL, V49, P14092, DOI 10.1021/ACS.EST.5B03304; UBL S, SCHERINGER M, STOHL A, BURKHART JF, HUNGERBÜHLER K. PRIMARY SOURCE REGIONS OF POLYCHLORINATED BIPHENYLS (PCBS) MEASURED IN THE ARCTIC. ATMOS ENVIRON. 2012;62(0):391–399. 10.1016/J.ATMOSENV.2012.07.061; MACLEOD M, 2005, ENVIRON SCI TECHNOL, V39, P6749, DOI 10.1021/ES048426R; ARNET R, KUHN E, NÄF U. KONDENSATOREN VERZEICHNIS—ERKENNUNG UND ENTSORGUNG PCB-HALTIGER KONDENSATOREN; 2011. AVAILABLE FROM: HTTP://WWW.CHEMSUISSE.CH/DE/FACHLICHES/PCB; TREMP J, WEGMANN L. STAND DES’PHASE-OUT’ VON PCB IN DER SCHWEIZ: ERGEBNISSE EINER UNTERSUCHUNG ÜBER PCB-RESERVOIRE UND MASSNAHMEN FÜR DIE BESCHLEUNIGTE UND SICHERE ENTSORGUNG. ARBEITSEXEMPLAR FÜR DIE SCHRIFTENREIHE UMWELT. BERN, SWITZERLAND; 2001.; BARGHOORN M, BAUER RK, GÖSSELE P. ABSCHLUSSBERICHT ZUM FORSCHUNGSVORHABEN PCB-KLEINKONDENSATOREN. ARBEITSGRUPPE UMWELTSTATISTIK-ARGUS AN DER TECHNISCHEN UNIVERSITÄT BERLIN. BERLIN, GERMANY; 1988.; KUHN E, ARNET R. PCB IN VORSCHALTGERÄTEN VON FLUORESZENZLAMPEN – EINE BILANZIERUNG. KANTONALES LABOR KANTON AARGAU. AARAU, SWITZERLAND; 1998.; BUWAL. RICHTLINIE PCB-HALTIGE FUGENDICHTUNGSMASSEN – BEURTEILUNG DES HANDLUNGSBEDARFS UND EMPFEHLUNGEN FÜR DAS VORGEHEN BEI BAUTEN. BERN, SWITZERLAND: BUNDESAMT FÜR UMWELT, WALD UND LANDSCHAFT; 2003.; KOHLER M, 2005, ENVIRON SCI TECHNOL, V39, P1967, DOI 10.1021/ES048632Z; BUWAL. DIFFUSE QUELLEN VON PCB IN DER SCHWEIZ. SCHRIFTENREIHE UMWELT NR. 229. BERN, SWITZERLAND: BUNDESAMT FÜR UMWELT, WALD UND LANDSCHAFT; 1994.; ABBASI G, 2014, ENVIRON SCI TECHNOL, V49, P1521, DOI 10.1021/ES504007V; DAVIS J, GEYER R, LEY J, HE J, CLIFT R, KWAN A, ET AL. TIME-DEPENDENT MATERIAL FLOW ANALYSIS OF IRON AND STEEL IN THE UK – PART 2. SCRAP GENERATION AND RECYCLING. RESOUR CONSERV RECYCL. 2007;51:118–140. 10.1016/J.RESCONREC.2006.08.007; DIEFENBACHER PS, 2015, ENVIRON SCI TECHNOL, V50, P232, DOI 10.1021/ACS.EST.5B04626; HAUSER A. THESENPAPIER: ENTSORGUNG BESCHICHTETER STAHLSCHROTT. BUNDESAMT FÜR UMWELT (BAFU). HOLINGER AG. BERN/LUZERN, SWITZERLAND; 2014.; MACKAY D. POLYCHLORINATED BIPHENYLS (PCBS). IN: HANDB. PHYS. PROP. ENVIRON. FATE ORG. CHEM.. 2ND ED.; 2006. AVAILABLE FROM: HTTP://WWW.CRCNETBASE.COM/DOI/PDFPLUS/10.1201/9781420044393.CH7; WERMEILLE C. PERSONAL COMMUNICATION, JULY 2016; 2016.; IFEU. ERMITTLUNG VON EMISSIONEN UND MINDERUNGSMAßNAHMEN FÜR PERSISTENTE ORGANISCHE SCHADSTOFFE IN DER BUNDESREPUBLICK DEUTSCHLAND (UBA-FB 98-115). INSTITUT FÜR ENERGIE- UND UMWELTFORSCHUNG HEIDELBERG; 1998. AVAILABLE FROM: HTTP://WWW.DIOXINDB.DE/DOKUMENTE/UBA_1998_TEXTE_74-98_POPS_INVENTARE_PCB_SCCP_HCBD_GEDRUCKT.PDF; MACLEOD M, 2002, ENVIRON TOXICOL CHEM, V21, P700; HELTON JC, DAVIS FJ. LATIN HYPERCUBE SAMPLING AND THE PROPAGATION OF UNCERTAINTY IN ANALYSES OF COMPLEX SYSTEMS. RELIAB ENG SYST SAF. 2003;81(1):23–69. 10.1016/S0951-8320(03)00058-9; BOGDAL C, 2014, ENVIRON SCI TECHNOL, V48, P482, DOI 10.1021/ES4044352; DIEFENBACHER PS, 2015, ENVIRON SCI TECHNOL, V49, P2199, DOI 10.1021/ES505242D; GRONTMIJ. SURVEY OF PCB IN MATERIALS AND INDOOR AIR—CONSOLIDATED REPORT. GRONTMIJ/COWI CONSORTIUM; 2013.; SRF. LETZTE CORONADO; 2013. AVAILABLE FROM: HTTP://WWW.SRF.CH/NEWS/FLUGHAFEN-ZUERICH/VIDEOS/LETZTE-CORONADO; FOEN. PAINTS AND VARNISHES; 2016. AVAILABLE FROM: HTTPS://WWW.BAFU.ADMIN.CH/BAFU/EN/HOME/TOPICS/CHEMICALS/INFO-SPECIALISTS/CHEMICALS--REGULATIONS-AND-PROCEDURES/PCB/PAINTS-AND-VARNISHES.HTML; BOGDAL C, 2016, ENVIRON POLLUT, V220, P891, DOI 10.1016/J.ENVPOL.2016.10.073
#> 3                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              <NA>
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

The typical pubmedR workflow follows these steps. Use `pmCollect()` to
run the full pipeline in one call, or use the individual functions for
fine-grained control:

      pmCollect()                       Individual functions
      (one step)                        (step by step)
                                       +-------------------+
    +----------------+                 | pmQueryBuild()    |
    |                |                 | Build query       |
    | pmCollect()    |                 +---------+---------+
    |                |                           |
    | Builds query,  |                           v
    | counts records,|                 +-------------------+
    | downloads,     |                 | pmQueryTotalCount()|
    | converts,      |                 | Check result count|
    | enriches (opt) |                 +---------+---------+
    |                |                           |
    +-------+--------+             +--------------+--------------+
            |                      |                             |
            |                      v                             v
            |            +-------------------+         +-------------------+
            |            | pmApiRequest()    |         | pmFetchById()     |
            |            | Search & download |         | Download by PMID  |
            |            +---------+---------+         +---------+---------+
            |                      |                             |
            |                      +-------------+---------------+
            |                                    |
            |                                    v
            |                          +-------------------+
            |                          | pmApi2df()        |
            |                          | Convert to df     |
            |                          +---------+---------+
            |                                    |
            |                                    v
            |                          +-------------------+
            |                          | pmEnrichCitations()|
            |                          | Add TC & CR       |
            |                          +---------+---------+
            |                                    |
            +------------------------------------+
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
