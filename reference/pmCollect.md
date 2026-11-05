# Collect and process PubMed bibliographic data in one step

A convenience wrapper that executes the full pubmedR workflow: query
building, record count check, metadata download, conversion to data
frame, and (optionally) citation enrichment via NCBI E-Link.

## Usage

``` r
pmCollect(
  query = NULL,
  terms = NULL,
  fields = "Title/Abstract",
  language = NULL,
  pub_type = NULL,
  date_range = NULL,
  mesh_terms = NULL,
  limit = 2000,
  enrich = FALSE,
  format = "bibliometrix",
  api_key = NULL,
  batch_size = 200,
  verbose = TRUE,
  author = NULL,
  journal = NULL,
  operator = "AND"
)
```

## Arguments

- query:

  is a character. A PubMed search query in Entrez syntax. Alternatively,
  if `terms` is provided, or if `query` is missing and any of
  `mesh_terms`, `author` or `journal` is provided, the query is built
  automatically using
  [`pmQueryBuild`](https://massimoaria.github.io/pubmedR/reference/pmQueryBuild.md).

- terms:

  is a character or character vector or NULL. Search terms passed to
  [`pmQueryBuild`](https://massimoaria.github.io/pubmedR/reference/pmQueryBuild.md).
  When provided, a query is built automatically and the `query` argument
  is ignored. Default is `NULL`.

- fields:

  is a character or character vector. PubMed search tags used when
  building the query from `terms`. Default is `"Title/Abstract"`.

- language:

  is a character or NULL. Language filter for query building. Default is
  `NULL`.

- pub_type:

  is a character or NULL. Publication type filter for query building.
  Default is `NULL`.

- date_range:

  is a character vector of length 2 or NULL. Date range in format
  `c("YYYY", "YYYY")`. Default is `NULL`.

- mesh_terms:

  is a character or character vector or NULL. MeSH terms for query
  building. Default is `NULL`.

- limit:

  is numeric. Maximum number of records to download. Default is `2000`.

- enrich:

  is logical. If `TRUE`, citation counts (TC) and cited references (CR)
  are added via
  [`pmEnrichCitations`](https://massimoaria.github.io/pubmedR/reference/pmEnrichCitations.md).
  Default is `FALSE` because enrichment makes 2 API calls per article
  and can be slow for large collections.

- format:

  is a character. Output format passed to
  [`pmApi2df`](https://massimoaria.github.io/pubmedR/reference/pmApi2df.md).
  Either `"bibliometrix"` (default) or `"raw"`.

- api_key:

  is a character or NULL. NCBI API key. Can also be set via the
  environment variable `PUBMED_API_KEY` or `ENTREZ_KEY`. Default is
  `NULL`.

- batch_size:

  is numeric. Records per API request. Default is 200.

- verbose:

  is logical. If `TRUE` (default), prints progress messages.

- author:

  is a character or character vector or NULL. Author names for query
  building. Default is `NULL`.

- journal:

  is a character or character vector or NULL. Journal names for query
  building. Default is `NULL`.

- operator:

  is a character. Boolean operator combining `terms`, "AND" or "OR".
  Default is `"AND"`.

## Value

a data frame containing bibliographic records, compatible with the
`bibliometrix` package when `format = "bibliometrix"`.

## Details

This function chains together the core pubmedR functions in the
recommended order:

1.  **Query**: If `terms` is provided, builds the query with
    [`pmQueryBuild`](https://massimoaria.github.io/pubmedR/reference/pmQueryBuild.md);
    otherwise uses the `query` string directly.

2.  **Count**: Checks the total number of matching records with
    [`pmQueryTotalCount`](https://massimoaria.github.io/pubmedR/reference/pmQueryTotalCount.md).

3.  **Download**: Fetches metadata with
    [`pmApiRequest`](https://massimoaria.github.io/pubmedR/reference/pmApiRequest.md).

4.  **Convert**: Transforms XML to a data frame with
    [`pmApi2df`](https://massimoaria.github.io/pubmedR/reference/pmApi2df.md).

5.  **Enrich** (optional): Adds citation data with
    [`pmEnrichCitations`](https://massimoaria.github.io/pubmedR/reference/pmEnrichCitations.md).

## See also

[`pmQueryBuild`](https://massimoaria.github.io/pubmedR/reference/pmQueryBuild.md),
[`pmQueryTotalCount`](https://massimoaria.github.io/pubmedR/reference/pmQueryTotalCount.md),
[`pmApiRequest`](https://massimoaria.github.io/pubmedR/reference/pmApiRequest.md),
[`pmApi2df`](https://massimoaria.github.io/pubmedR/reference/pmApi2df.md),
[`pmEnrichCitations`](https://massimoaria.github.io/pubmedR/reference/pmEnrichCitations.md)

## Examples

``` r
if (FALSE) { # interactive()
# Using a raw query string
M <- pmCollect(
  query = "bibliometric*[Title/Abstract] AND english[LA] AND 2020:2024[DP]",
  limit = 50
)

# Using the query builder parameters
M <- pmCollect(
  terms = "bibliometric*",
  language = "english",
  pub_type = "Journal Article",
  date_range = c("2020", "2024"),
  limit = 50
)

# With citation enrichment (slower, requires extra API calls)
M <- pmCollect(
  terms = "bibliometric*",
  date_range = c("2023", "2024"),
  limit = 10,
  enrich = TRUE
)
}
```
