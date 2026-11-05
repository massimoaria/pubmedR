# Build a PubMed search query programmatically

It helps to build a valid PubMed search query using the Entrez query
language, combining multiple search terms with Boolean operators.

## Usage

``` r
pmQueryBuild(
  terms = NULL,
  fields = "Title/Abstract",
  language = NULL,
  pub_type = NULL,
  date_range = NULL,
  mesh_terms = NULL,
  author = NULL,
  journal = NULL,
  operator = "AND"
)
```

## Arguments

- terms:

  is a character or character vector. Search terms to look for in title
  and abstract fields.

- fields:

  is a character or character vector. PubMed search tags to apply.
  Default is `c("Title/Abstract")`. Common fields include:
  "Title/Abstract", "Title", "Author", "MeSH Terms", "Affiliation",
  "Journal".

- language:

  is a character or character vector or NULL. Language filter (e.g.
  "english", "french"). Several languages are combined with OR. Default
  is `NULL` (no filter).

- pub_type:

  is a character or character vector or NULL. Publication type filter
  (e.g. "Journal Article", "Review", "Clinical Trial"). Several types
  are combined with OR. Default is `NULL` (no filter).

- date_range:

  is a character vector of length 2 or NULL. Date range in format
  `c("YYYY", "YYYY")` or `c("YYYY/MM/DD", "YYYY/MM/DD")`. Default is
  `NULL` (no filter).

- mesh_terms:

  is a character or character vector or NULL. MeSH (Medical Subject
  Headings) terms. Default is `NULL` (no filter).

- author:

  is a character or character vector or NULL. Author names. Default is
  `NULL`.

- journal:

  is a character or character vector or NULL. Journal names or
  abbreviations. Default is `NULL`.

- operator:

  is a character. Boolean operator to combine multiple `terms`. One of
  "AND", "OR". Default is `"AND"`.

## Value

a character string containing the formatted PubMed query.

## Details

The function constructs a query string compatible with NCBI's Entrez
search system. Multiple terms within the same parameter are combined
with the specified `operator`, while different parameters (terms,
language, pub_type, etc.) are combined with AND.

For more information about PubMed search tags, visit:
<https://pubmed.ncbi.nlm.nih.gov/help/#search-tags>

## See also

[`pmQueryTotalCount`](https://massimoaria.github.io/pubmedR/reference/pmQueryTotalCount.md)

[`pmApiRequest`](https://massimoaria.github.io/pubmedR/reference/pmApiRequest.md)

## Examples

``` r

# Simple query
q <- pmQueryBuild(terms = "bibliometrics", language = "english",
                  pub_type = "Journal Article", date_range = c("2000", "2023"))

# Multiple terms
q <- pmQueryBuild(terms = c("machine learning", "deep learning"),
                  operator = "OR", language = "english")

# MeSH terms query
q <- pmQueryBuild(mesh_terms = "COVID-19", pub_type = "Review",
                  date_range = c("2020", "2024"))

# Author search
q <- pmQueryBuild(terms = "bibliometrics", author = "Aria M")
```
