#' Citation metrics of PubMed articles from NIH iCite
#'
#' It retrieves citation counts and field-normalised metrics from the NIH iCite
#' service, built on the NIH Open Citation Collection. No API key is required.
#'
#' PubMed itself counts only the citing articles in PubMed Central, so its figures
#' are usually much lower than those of iCite.
#'
#' @param pmids is a character or numeric vector of PubMed identifiers (PMIDs).
#' @param batch_size is numeric. PMIDs per request, at most 1000. Default is 500.
#'
#' @return a data frame with one row per PMID requested, in the same order, and
#' the columns:
#' \tabular{lll}{
#' pmid \tab \tab The PMID.\cr
#' doi \tab \tab The DOI.\cr
#' year \tab \tab The publication year.\cr
#' citation_count \tab \tab The number of citing articles.\cr
#' citations_per_year \tab \tab Citations per year since publication.\cr
#' relative_citation_ratio \tab \tab Citations compared with those expected in the
#' article's field (1 is the NIH-funded median).\cr
#' nih_percentile \tab \tab The percentile of the ratio among NIH-funded articles.\cr
#' is_research_article \tab \tab Whether iCite classes it as primary research.}
#'
#' A PMID unknown to iCite has \code{NA} in every other column.
#'
#' @examplesIf interactive()
#' pmICite(c("10171110", "25824007"))
#'
#' @seealso \code{\link{pmEnrichCitations}}, \code{\link{pmCitedBy}}
#'
#' @export
pmICite <- function(pmids, batch_size = 500) {
  pmids <- unique(trimws(as.character(pmids)))
  pmids <- pmids[!is.na(pmids) & nzchar(pmids)]
  if (length(pmids) == 0) {
    stop("No valid PMIDs provided.", call. = FALSE)
  }
  batch_size <- min(batch_size, 1000)

  numeric_cols <- c(
    "year", "citation_count", "citations_per_year",
    "relative_citation_ratio", "nih_percentile"
  )
  out <- data.frame(pmid = pmids, doi = NA_character_, stringsAsFactors = FALSE)
  out[numeric_cols] <- NA_real_
  out$is_research_article <- NA

  fields <- paste(c("pmid", "doi", numeric_cols, "is_research_article"), collapse = ",")
  batches <- split(pmids, ceiling(seq_along(pmids) / batch_size))
  for (ids in batches) {
    url <- sprintf(
      "https://icite.od.nih.gov/api/pubs?pmids=%s&fl=%s&limit=%d",
      paste(ids, collapse = ","), fields, length(ids)
    )
    res <- api_call_with_retry(jsonlite::fromJSON(url))$data
    if (length(res) == 0 || NROW(res) == 0) next

    rows <- match(as.character(res$pmid), out$pmid)
    if ("doi" %in% names(res)) out$doi[rows] <- as.character(res$doi)
    for (col in intersect(numeric_cols, names(res))) {
      out[[col]][rows] <- as.numeric(res[[col]])
    }
    if ("is_research_article" %in% names(res)) {
      out$is_research_article[rows] <- as.logical(res$is_research_article)
    }
  }
  out
}
