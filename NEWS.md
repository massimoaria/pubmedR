# pubmedR (development version)

## Bug fixes

* `pmApi2df()`: `PY` is now the year of the journal issue (or of the book), not
  the earliest date in the record's history, which is often one or two years
  before the publication (for example, the date the record was entered).

* `pmApi2df()`: titles holding an inline tag ("PM<sub>2.5</sub>", an italic species
  name) were `NA`, 385 of a sample of 1,500 records chosen to include them, and the
  tagged words were lost from abstracts and keywords. All are now read in full.

* `pmApi2df()`: an author with no fore name or initials, such as a single-name
  author, shifted the names of the following authors. Each author is now read as a
  whole, and no name ends in "NA".

* `pmApi2df()`: collective authors are now kept in their place in `AU` and `AF`.

* `pmApi2df()`: removing an e-mail address also removed the text around it, often the
  country ("Pavia, Italy. m.rossi@unipv.it"). Only the address is removed now.

* `pmApiRequest()` failed, losing what it had downloaded, beyond the 9,999 records
  PubMed serves per search. The query is now split by date, so `limit` can exceed it.
  `records_downloaded` is now the number of records actually received.

* API calls: a retry no longer raises a warning, a client error (HTTP 4xx) is no
  longer retried, and error messages no longer include a whole HTML page.

* `pmEnrichCitations()`: an article whose citation count could not be retrieved had
  `TC` set to 0. It now keeps its value, with a warning. Counts are requested in
  batches, not one article at a time.

* `pmQueryBuild()`: several values in `language` or `pub_type` failed, and they are
  now combined with OR. A `date_range` without two dates is now an error, not ignored.

* `pmCollect()`: `mesh_terms` alone no longer fails, `enrich = TRUE` no longer downloads
  the records again, and it gains the arguments `author`, `journal` and `operator`.

* `pmFetchById()` ignores missing PMIDs, and reports those returning no record.

* Examples and tests no longer fail when NCBI is unavailable.

## New functions

* `pmICite()`: citation counts and the relative citation ratio from NIH iCite, usually
  much higher than the counts from PubMed. `pmEnrichCitations(tc_source = "icite")`
  uses them for `TC`.

* `pmCountByYear()`: the publication trend of a query, without downloading records.

* `pmFetchByDoi()`: download records by DOI, and see which DOIs are not in PubMed.

## New columns

* `pmApi2df()` adds `PT`, all the publication types of a record (`DT` holds only the
  first, usually "Journal Article" even for a review), and `PMCID`.

# pubmedR 1.0.2

# pubmedR 1.0.1

## Bug fixes

* `pmEnrichCitations()` no longer relies on the NCBI E-Link
  `pubmed_pubmed_refs` link, which only resolves references for articles
  whose full text is deposited in PMC. The function now extracts cited
  references directly from the PubMed XML `<ReferenceList>` block, which is
  populated for the majority of recent articles. CR coverage on typical
  bibliographic queries improved from a few percent to almost full coverage
  on tested samples.

## New functions

* `pmExtractReferences()`: parse a PubMed XML payload (the result of
  `pmApiRequest()` or `pmFetchById()`) and return a tidy data frame of
  references, one row per cited reference, with the source PMID, the raw
  `<Citation>` text, and any embedded PubMed/DOI identifiers.

## Improvements

* `pmEnrichCitations()` gains the arguments `P` (reuse a previously
  downloaded XML payload to avoid an extra `efetch` round-trip),
  `resolve_pmids` (resolve cited PMIDs to WoS-style "AUTHOR YEAR, JOURNAL,
  V, P, DOI" citation strings via batched `efetch`), `only_multiple` (only
  resolve references cited by more than one source article), `include_TC`
  (toggle the slower per-article cited-by lookup), and `batch_size`
  (forwarded to `pmFetchById()`).

* CR strings produced by `pmEnrichCitations()` are now compatible with the
  WoS conventions parsed by `bibliometrix` (`citations()`,
  `histNetwork()`, ...). References for which only a free-text `<Citation>`
  is available are kept verbatim (uppercased).

* `pmEnrichCitations()` now also writes the number of references for each
  article into the `NR` column.

# pubmedR 1.0.0

# pubmedR 0.1.0.900

## New functions

* `pmQueryBuild()`: build PubMed search queries programmatically, with support
  for terms, MeSH headings, authors, journals, language, publication type,
  and date range filters.

* `pmFetchById()`: download PubMed records directly by a vector of PMIDs,
  with batch support and full compatibility with `pmApi2df()`.

* `pmCitedBy()`: retrieve PMIDs of articles that cite a given article,
  using the NCBI E-Link service.

* `pmReferences()`: retrieve PMIDs of references cited by a given article,
  using the NCBI E-Link service.

* `pmEnrichCitations()`: batch enrich a bibliometric data frame with real
  citation counts (TC) and cited references (CR) from NCBI E-Link data.

* `pmCollect()`: one-step wrapper that covers the full workflow — query
  building, record count, download, conversion to data frame, and optional
  citation enrichment.

## Improvements

* All API calls now include error handling with automatic retry and
  exponential backoff (up to 3 retries).

* Automatic rate limiting enforces NCBI limits: 3 requests/second without
  API key, 10 requests/second with API key.

* API key is now auto-detected from environment variables `PUBMED_API_KEY`
  or `ENTREZ_KEY`, removing the need to pass it explicitly to every function.

* `pmApiRequest()` gains a `batch_size` argument (default 200) to control
  the number of records per API request.

* `pmApiRequest()` now returns an empty result gracefully when the query
  matches zero records, instead of erroring.

* Improved affiliation extraction in `pmApi2df()`: all author affiliations
  are now collected (previously only the corresponding author's affiliation
  was captured).

* Progress bars upgraded to style 3 (percentage display) across all functions.

* `pmApiRequest()` documentation now correctly references `pmQueryBuild()`
  (previously referenced a non-existent function).

## Bug fixes

* Fixed HTTP 400 error when query returns exactly one record. The
  `retstart` parameter now correctly starts at 0 instead of 1 (GitHub
  issues #7 and #9, PR #13).

* Fixed "invalid multibyte string" error in `pmApi2df()` caused by
  non-UTF-8 characters in PubMed XML records. Encoding is now sanitized
  during list-to-character conversion (GitHub issues #3 and #6).

* Fixed `txtProgressBar` error in `pmApi2df()` when converting a single
  record (`min == max` when `n == 1`), by starting the progress bar at 0
  (GitHub PR #13).

## Infrastructure

* Added test suite using testthat (66 tests covering utilities, query building,
  query counting, and data conversion).

* New `README.Rmd` with live examples, function reference table, workflow
  diagram, and integration guide for bibliometrix/biblioshiny.

* Internal utility functions (`list2char`, `get_api_key`, `api_throttle`,
  `api_call_with_retry`) extracted into `R/utils.R`.

# pubmedR 0.0.4

* Fixed issue about entrez_fetch restart argument.

# pubmedR 0.0.2

* Fixed issue in publication year field.

# pubmedR 0.0.1

* Initial version.
