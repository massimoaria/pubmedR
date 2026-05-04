#' Extract references from PubMed XML records
#'
#' Walks a result returned by \code{\link{pmApiRequest}} or
#' \code{\link{pmFetchById}} and pulls the \code{<ReferenceList>} block out of
#' every record. Returns one row per cited \code{<Reference>}, carrying the
#' source PMID, the free-text citation, and (when present) the cited PMID and
#' DOI parsed from \code{<ArticleIdList>}.
#'
#' @param P A list following the PubMed XML structure produced by
#'   \code{pmApiRequest()} or \code{pmFetchById()}. Must contain a \code{$data}
#'   element with one entry per record.
#'
#' @return A data.frame with columns
#' \tabular{lll}{
#' source_pmid \tab \tab The PMID of the article that cites the reference.\cr
#' citation    \tab \tab The free-text \code{<Citation>} string from PubMed.\cr
#' pmid        \tab \tab The PMID of the cited reference (if available).\cr
#' doi         \tab \tab The DOI of the cited reference (if available).}
#'
#' Returns an empty data.frame (with the same schema) if no references are
#' found.
#'
#' @details
#' Reference data in PubMed XML is populated when the publisher submits a
#' \code{<ReferenceList>} block to NLM (which is now common, but not universal).
#' This function does not call any web API; it merely parses what is already
#' present in the XML. Use \code{\link{pmEnrichCitations}} to also resolve cited
#' PMIDs into structured WoS-style citation strings.
#'
#' @examples
#' \donttest{
#' D <- pmFetchById("37289732")
#' refs <- pmExtractReferences(D)
#' head(refs)
#' }
#'
#' @seealso \code{\link{pmEnrichCitations}}, \code{\link{pmFetchById}}
#'
#' @export
pmExtractReferences <- function(P) {
  records <- P$data
  if (is.null(records) || length(records) == 0) {
    return(data.frame(
      source_pmid = character(0),
      citation = character(0),
      pmid = character(0),
      doi = character(0),
      stringsAsFactors = FALSE
    ))
  }

  out <- list()
  for (i in seq_along(records)) {
    rec <- records[[i]]
    src_pmid <- extract_record_pmid(rec)
    refs <- extract_refs_from_record(rec)
    if (nrow(refs) == 0) next
    refs$source_pmid <- src_pmid
    out[[length(out) + 1]] <- refs[, c("source_pmid", "citation", "pmid", "doi")]
  }

  if (length(out) == 0) {
    return(data.frame(
      source_pmid = character(0),
      citation = character(0),
      pmid = character(0),
      doi = character(0),
      stringsAsFactors = FALSE
    ))
  }

  do.call(rbind, out)
}
