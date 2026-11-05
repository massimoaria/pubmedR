# Enrich a PubMed dataframe with citation data

Adds cited references (CR field), reference counts (NR field), and
optionally citation counts (TC field) to a dataframe created by
[`pmApi2df`](https://massimoaria.github.io/pubmedR/reference/pmApi2df.md).

## Usage

``` r
pmEnrichCitations(
  df,
  P = NULL,
  api_key = NULL,
  resolve_pmids = TRUE,
  only_multiple = FALSE,
  include_TC = TRUE,
  batch_size = 200,
  tc_source = c("pubmed", "icite")
)
```

## Arguments

- df:

  is a dataframe. A bibliometric dataframe produced by
  [`pmApi2df`](https://massimoaria.github.io/pubmedR/reference/pmApi2df.md).

- P:

  is the optional list returned by
  [`pmApiRequest`](https://massimoaria.github.io/pubmedR/reference/pmApiRequest.md)
  or
  [`pmFetchById`](https://massimoaria.github.io/pubmedR/reference/pmFetchById.md)
  that produced `df`. Reuse it to avoid an extra round-trip when
  references are already available. If `NULL`, the function calls
  `pmFetchById` on `df$PMID` to retrieve the underlying XML.

- api_key:

  is a character. It contains a valid API key for the NCBI E-utilities.
  Default is `api_key=NULL`. The API key can also be set via the
  environment variable `PUBMED_API_KEY` or `ENTREZ_KEY`.

- resolve_pmids:

  logical. When `TRUE` (default) the function fetches metadata for every
  cited PMID present in the references and assembles structured
  WoS-style citation strings ("AUTHOR YYYY, JOURNAL, V##, P##, DOI
  ..."). When `FALSE` the free-text `<Citation>` block from the XML is
  used as-is.

- only_multiple:

  logical. When `TRUE` only references cited by more than one source
  article are resolved to metadata (faster and cheaper). References not
  resolved keep their free-text citation. Defaults to `FALSE`.

- include_TC:

  logical. When `TRUE` (default) also retrieve the citation count of
  each source article and write it to `df$TC`. An article whose count
  could not be retrieved keeps its value, with a warning. Disable to
  skip this step.

- batch_size:

  integer. Number of records per API call when fetching metadata.
  Defaults to 200 (NCBI's hard cap for efetch).

- tc_source:

  character. Where citation counts come from: `"pubmed"` (default), the
  articles in PubMed Central that cite the document, or `"icite"`, the
  larger NIH Open Citation Collection (see
  [`pmICite`](https://massimoaria.github.io/pubmedR/reference/pmICite.md)).

## Value

The input dataframe with updated `CR` (cited references), `NR` (number
of references), and `TC` (times cited, if `include_TC = TRUE`) fields.

## Details

Cited references are extracted from the article's PubMed XML
(`<ReferenceList>`). This is more reliable than the previous E-Link
`pubmed_pubmed_refs` approach, which only worked for articles deposited
in PMC. References whose XML carries an `ArticleId` `IdType="pubmed"`
are resolved to bibliographic metadata in batched `efetch` requests so
that `CR` matches the WoS convention used by bibliometrix; references
with only free-text citations are kept verbatim (uppercased).

## See also

[`pmExtractReferences`](https://massimoaria.github.io/pubmedR/reference/pmExtractReferences.md),
[`pmCitedBy`](https://massimoaria.github.io/pubmedR/reference/pmCitedBy.md),
[`pmFetchById`](https://massimoaria.github.io/pubmedR/reference/pmFetchById.md),
[`pmApi2df`](https://massimoaria.github.io/pubmedR/reference/pmApi2df.md)

## Examples

``` r
if (FALSE) { # interactive()
query <- "bibliometric*[Title/Abstract] AND english[LA]
         AND Journal Article[PT] AND 2000:2020[DP]"
D <- pmApiRequest(query = query, limit = 10, api_key = NULL)
M <- pmApi2df(D)
M <- pmEnrichCitations(M, P = D)        # avoid the extra fetch
}
```
