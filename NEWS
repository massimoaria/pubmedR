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
