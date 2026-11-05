# Changelog

## pubmedR (development version)

### Bug fixes

- [`pmApi2df()`](https://massimoaria.github.io/pubmedR/reference/pmApi2df.md):
  `PY` is now the year of the journal issue (or of the book), not the
  earliest date in the record’s history, which is often one or two years
  before the publication (for example, the date the record was entered).

- [`pmApi2df()`](https://massimoaria.github.io/pubmedR/reference/pmApi2df.md):
  titles holding an inline tag (“PM_(2.5)”, an italic species name) were
  `NA`, 385 of a sample of 1,500 records chosen to include them, and the
  tagged words were lost from abstracts and keywords. All are now read
  in full.

- [`pmApi2df()`](https://massimoaria.github.io/pubmedR/reference/pmApi2df.md):
  an author with no fore name or initials, such as a single-name author,
  shifted the names of the following authors. Each author is now read as
  a whole, and no name ends in “NA”.

- [`pmApi2df()`](https://massimoaria.github.io/pubmedR/reference/pmApi2df.md):
  collective authors are now kept in their place in `AU` and `AF`.

- [`pmApi2df()`](https://massimoaria.github.io/pubmedR/reference/pmApi2df.md):
  removing an e-mail address also removed the text around it, often the
  country (“Pavia, Italy. <m.rossi@unipv.it>”). Only the address is
  removed now.

- [`pmApiRequest()`](https://massimoaria.github.io/pubmedR/reference/pmApiRequest.md)
  failed, losing what it had downloaded, beyond the 9,999 records PubMed
  serves per search. The query is now split by date, so `limit` can
  exceed it. `records_downloaded` is now the number of records actually
  received.

- API calls: a retry no longer raises a warning, a client error (HTTP
  4xx) is no longer retried, and error messages no longer include a
  whole HTML page.

- [`pmEnrichCitations()`](https://massimoaria.github.io/pubmedR/reference/pmEnrichCitations.md):
  an article whose citation count could not be retrieved had `TC` set
  to 0. It now keeps its value, with a warning. Counts are requested in
  batches, not one article at a time.

- [`pmQueryBuild()`](https://massimoaria.github.io/pubmedR/reference/pmQueryBuild.md):
  several values in `language` or `pub_type` failed, and they are now
  combined with OR. A `date_range` without two dates is now an error,
  not ignored.

- [`pmCollect()`](https://massimoaria.github.io/pubmedR/reference/pmCollect.md):
  `mesh_terms` alone no longer fails, `enrich = TRUE` no longer
  downloads the records again, and it gains the arguments `author`,
  `journal` and `operator`.

- [`pmFetchById()`](https://massimoaria.github.io/pubmedR/reference/pmFetchById.md)
  ignores missing PMIDs, and reports those returning no record.

- Examples and tests no longer fail when NCBI is unavailable.

### New functions

- [`pmICite()`](https://massimoaria.github.io/pubmedR/reference/pmICite.md):
  citation counts and the relative citation ratio from NIH iCite,
  usually much higher than the counts from PubMed.
  `pmEnrichCitations(tc_source = "icite")` uses them for `TC`.

- [`pmCountByYear()`](https://massimoaria.github.io/pubmedR/reference/pmCountByYear.md):
  the publication trend of a query, without downloading records.

- [`pmFetchByDoi()`](https://massimoaria.github.io/pubmedR/reference/pmFetchByDoi.md):
  download records by DOI, and see which DOIs are not in PubMed.

### New columns

- [`pmApi2df()`](https://massimoaria.github.io/pubmedR/reference/pmApi2df.md)
  adds `PT`, all the publication types of a record (`DT` holds only the
  first, usually “Journal Article” even for a review), and `PMCID`.

## pubmedR 1.0.2

CRAN release: 2026-05-04

## pubmedR 1.0.1

### Bug fixes

- [`pmEnrichCitations()`](https://massimoaria.github.io/pubmedR/reference/pmEnrichCitations.md)
  no longer relies on the NCBI E-Link `pubmed_pubmed_refs` link, which
  only resolves references for articles whose full text is deposited in
  PMC. The function now extracts cited references directly from the
  PubMed XML `<ReferenceList>` block, which is populated for the
  majority of recent articles. CR coverage on typical bibliographic
  queries improved from a few percent to almost full coverage on tested
  samples.

### New functions

- [`pmExtractReferences()`](https://massimoaria.github.io/pubmedR/reference/pmExtractReferences.md):
  parse a PubMed XML payload (the result of
  [`pmApiRequest()`](https://massimoaria.github.io/pubmedR/reference/pmApiRequest.md)
  or
  [`pmFetchById()`](https://massimoaria.github.io/pubmedR/reference/pmFetchById.md))
  and return a tidy data frame of references, one row per cited
  reference, with the source PMID, the raw `<Citation>` text, and any
  embedded PubMed/DOI identifiers.

### Improvements

- [`pmEnrichCitations()`](https://massimoaria.github.io/pubmedR/reference/pmEnrichCitations.md)
  gains the arguments `P` (reuse a previously downloaded XML payload to
  avoid an extra `efetch` round-trip), `resolve_pmids` (resolve cited
  PMIDs to WoS-style “AUTHOR YEAR, JOURNAL, V, P, DOI” citation strings
  via batched `efetch`), `only_multiple` (only resolve references cited
  by more than one source article), `include_TC` (toggle the slower
  per-article cited-by lookup), and `batch_size` (forwarded to
  [`pmFetchById()`](https://massimoaria.github.io/pubmedR/reference/pmFetchById.md)).

- CR strings produced by
  [`pmEnrichCitations()`](https://massimoaria.github.io/pubmedR/reference/pmEnrichCitations.md)
  are now compatible with the WoS conventions parsed by `bibliometrix`
  ([`citations()`](https://rdrr.io/pkg/bibliometrix/man/citations.html),
  [`histNetwork()`](https://rdrr.io/pkg/bibliometrix/man/histNetwork.html),
  …). References for which only a free-text `<Citation>` is available
  are kept verbatim (uppercased).

- [`pmEnrichCitations()`](https://massimoaria.github.io/pubmedR/reference/pmEnrichCitations.md)
  now also writes the number of references for each article into the
  `NR` column.

## pubmedR 1.0.0

CRAN release: 2026-04-15

## pubmedR 0.1.0.900

### New functions

- [`pmQueryBuild()`](https://massimoaria.github.io/pubmedR/reference/pmQueryBuild.md):
  build PubMed search queries programmatically, with support for terms,
  MeSH headings, authors, journals, language, publication type, and date
  range filters.

- [`pmFetchById()`](https://massimoaria.github.io/pubmedR/reference/pmFetchById.md):
  download PubMed records directly by a vector of PMIDs, with batch
  support and full compatibility with
  [`pmApi2df()`](https://massimoaria.github.io/pubmedR/reference/pmApi2df.md).

- [`pmCitedBy()`](https://massimoaria.github.io/pubmedR/reference/pmCitedBy.md):
  retrieve PMIDs of articles that cite a given article, using the NCBI
  E-Link service.

- [`pmReferences()`](https://massimoaria.github.io/pubmedR/reference/pmReferences.md):
  retrieve PMIDs of references cited by a given article, using the NCBI
  E-Link service.

- [`pmEnrichCitations()`](https://massimoaria.github.io/pubmedR/reference/pmEnrichCitations.md):
  batch enrich a bibliometric data frame with real citation counts (TC)
  and cited references (CR) from NCBI E-Link data.

- [`pmCollect()`](https://massimoaria.github.io/pubmedR/reference/pmCollect.md):
  one-step wrapper that covers the full workflow — query building,
  record count, download, conversion to data frame, and optional
  citation enrichment.

### Improvements

- All API calls now include error handling with automatic retry and
  exponential backoff (up to 3 retries).

- Automatic rate limiting enforces NCBI limits: 3 requests/second
  without API key, 10 requests/second with API key.

- API key is now auto-detected from environment variables
  `PUBMED_API_KEY` or `ENTREZ_KEY`, removing the need to pass it
  explicitly to every function.

- [`pmApiRequest()`](https://massimoaria.github.io/pubmedR/reference/pmApiRequest.md)
  gains a `batch_size` argument (default 200) to control the number of
  records per API request.

- [`pmApiRequest()`](https://massimoaria.github.io/pubmedR/reference/pmApiRequest.md)
  now returns an empty result gracefully when the query matches zero
  records, instead of erroring.

- Improved affiliation extraction in
  [`pmApi2df()`](https://massimoaria.github.io/pubmedR/reference/pmApi2df.md):
  all author affiliations are now collected (previously only the
  corresponding author’s affiliation was captured).

- Progress bars upgraded to style 3 (percentage display) across all
  functions.

- [`pmApiRequest()`](https://massimoaria.github.io/pubmedR/reference/pmApiRequest.md)
  documentation now correctly references
  [`pmQueryBuild()`](https://massimoaria.github.io/pubmedR/reference/pmQueryBuild.md)
  (previously referenced a non-existent function).

### Bug fixes

- Fixed HTTP 400 error when query returns exactly one record. The
  `retstart` parameter now correctly starts at 0 instead of 1 (GitHub
  issues [\#7](https://github.com/massimoaria/pubmedR/issues/7) and
  [\#9](https://github.com/massimoaria/pubmedR/issues/9), PR
  [\#13](https://github.com/massimoaria/pubmedR/issues/13)).

- Fixed “invalid multibyte string” error in
  [`pmApi2df()`](https://massimoaria.github.io/pubmedR/reference/pmApi2df.md)
  caused by non-UTF-8 characters in PubMed XML records. Encoding is now
  sanitized during list-to-character conversion (GitHub issues
  [\#3](https://github.com/massimoaria/pubmedR/issues/3) and
  [\#6](https://github.com/massimoaria/pubmedR/issues/6)).

- Fixed `txtProgressBar` error in
  [`pmApi2df()`](https://massimoaria.github.io/pubmedR/reference/pmApi2df.md)
  when converting a single record (`min == max` when `n == 1`), by
  starting the progress bar at 0 (GitHub PR
  [\#13](https://github.com/massimoaria/pubmedR/issues/13)).

### Infrastructure

- Added test suite using testthat (66 tests covering utilities, query
  building, query counting, and data conversion).

- New `README.Rmd` with live examples, function reference table,
  workflow diagram, and integration guide for bibliometrix/biblioshiny.

- Internal utility functions (`list2char`, `get_api_key`,
  `api_throttle`, `api_call_with_retry`) extracted into `R/utils.R`.

## pubmedR 0.0.4

- Fixed issue about entrez_fetch restart argument.

## pubmedR 0.0.2

CRAN release: 2020-04-03

- Fixed issue in publication year field.

## pubmedR 0.0.1

CRAN release: 2020-03-20

- Initial version.
