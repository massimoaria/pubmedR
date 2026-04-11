#' Find articles that cite a given PubMed article
#'
#' It retrieves the PMIDs of articles that cite a given PubMed article,
#' using the NCBI E-Link service (PubMed Cited by).
#'
#' @param pmid is a character or numeric. A single PubMed identifier (PMID).
#' @param api_key is a character. It contains a valid API key for the NCBI E-utilities.
#' Default is \code{api_key=NULL}. The API key can also be set via the environment variable
#' \code{PUBMED_API_KEY} or \code{ENTREZ_KEY}.
#'
#' @return a list containing:
#' \tabular{lll}{
#' pmid \tab \tab The queried PMID.\cr
#' cited_by \tab \tab A character vector of PMIDs that cite the queried article.\cr
#' count \tab \tab The number of citing articles found.}
#'
#' @details
#' This function uses the NCBI E-Link endpoint with linkname "pubmed_pubmed_citedin"
#' to find articles in PubMed that cite the given article.
#'
#' Note: Citation data in PubMed is based on PubMed Central (PMC) and may not be as
#' comprehensive as commercial citation databases (e.g. Web of Science, Scopus).
#'
#' @examples
#'
#' \donttest{
#' # Find articles that cite PMID 25824007
#' cites <- pmCitedBy(pmid = "25824007")
#' cites$count
#' cites$cited_by
#' }
#'
#' @seealso \code{\link{pmReferences}}
#' @seealso \code{\link{pmFetchById}}
#'
#' @export
#' @import rentrez

pmCitedBy <- function(pmid, api_key = NULL) {

  api_key <- get_api_key(api_key)
  pmid <- as.character(pmid)[1]

  links <- api_call_with_retry(
    entrez_link(
      dbfrom = "pubmed",
      id = pmid,
      db = "pubmed",
      linkname = "pubmed_pubmed_citedin",
      api_key = api_key
    )
  )

  cited_by <- character(0)
  if (length(links$links$pubmed_pubmed_citedin) > 0) {
    cited_by <- links$links$pubmed_pubmed_citedin
  }

  result <- list(
    pmid = pmid,
    cited_by = cited_by,
    count = length(cited_by)
  )
  return(result)
}


#' Find references cited by a given PubMed article
#'
#' It retrieves the PMIDs of articles that are cited by (referenced in) a given
#' PubMed article, using the NCBI E-Link service.
#'
#' @param pmid is a character or numeric. A single PubMed identifier (PMID).
#' @param api_key is a character. It contains a valid API key for the NCBI E-utilities.
#' Default is \code{api_key=NULL}. The API key can also be set via the environment variable
#' \code{PUBMED_API_KEY} or \code{ENTREZ_KEY}.
#'
#' @return a list containing:
#' \tabular{lll}{
#' pmid \tab \tab The queried PMID.\cr
#' references \tab \tab A character vector of PMIDs referenced by the queried article.\cr
#' count \tab \tab The number of references found.}
#'
#' @details
#' This function uses the NCBI E-Link endpoint with linkname "pubmed_pubmed_refs"
#' to find articles in PubMed that are referenced by the given article.
#'
#' Note: Reference data is extracted from PubMed Central (PMC) full-text articles and
#' is only available when the full text is deposited in PMC. Not all PubMed articles
#' have reference data available.
#'
#' @examples
#'
#' \donttest{
#' # Find references of PMID 25824007
#' refs <- pmReferences(pmid = "25824007")
#' refs$count
#' refs$references
#' }
#'
#' @seealso \code{\link{pmCitedBy}}
#' @seealso \code{\link{pmFetchById}}
#'
#' @export
#' @import rentrez

pmReferences <- function(pmid, api_key = NULL) {

  api_key <- get_api_key(api_key)
  pmid <- as.character(pmid)[1]

  links <- api_call_with_retry(
    entrez_link(
      dbfrom = "pubmed",
      id = pmid,
      db = "pubmed",
      linkname = "pubmed_pubmed_refs",
      api_key = api_key
    )
  )

  references <- character(0)
  if (length(links$links$pubmed_pubmed_refs) > 0) {
    references <- links$links$pubmed_pubmed_refs
  }

  result <- list(
    pmid = pmid,
    references = references,
    count = length(references)
  )
  return(result)
}


#' Enrich a PubMed dataframe with citation data
#'
#' It adds cited references (CR field) and citation counts (TC field)
#' to a dataframe created by \code{\link{pmApi2df}}, using NCBI E-Link data.
#'
#' @param df is a dataframe. A bibliometric dataframe produced by \code{\link{pmApi2df}}.
#' @param api_key is a character. It contains a valid API key for the NCBI E-utilities.
#' Default is \code{api_key=NULL}. The API key can also be set via the environment variable
#' \code{PUBMED_API_KEY} or \code{ENTREZ_KEY}.
#'
#' @return The input dataframe with updated CR (Cited References) and TC (Times Cited) fields.
#'
#' @details
#' This function iterates over each record in the dataframe and queries NCBI E-Link
#' to retrieve: (1) The PMIDs of references cited by each article (populates CR field),
#' and (2) The count of articles citing each article (populates TC field).
#'
#' Note: This process makes two API calls per article and can be slow for large datasets.
#' An API key is strongly recommended.
#'
#' @examples
#'
#' \donttest{
#' query <- "bibliometric*[Title/Abstract] AND english[LA]
#'          AND Journal Article[PT] AND 2000:2020[DP]"
#' D <- pmApiRequest(query = query, limit = 10, api_key = NULL)
#' M <- pmApi2df(D)
#' M <- pmEnrichCitations(M)
#' }
#'
#' @seealso \code{\link{pmCitedBy}}
#' @seealso \code{\link{pmReferences}}
#' @seealso \code{\link{pmApi2df}}
#'
#' @export

pmEnrichCitations <- function(df, api_key = NULL) {

  api_key <- get_api_key(api_key)

  if (!"PMID" %in% names(df) || nrow(df) == 0) {
    message("No valid PMID field found in the dataframe.")
    return(df)
  }

  n <- nrow(df)
  cat("\nEnriching citation data for", n, "articles...\n")
  pb <- utils::txtProgressBar(min = 0, max = n, initial = 0, char = "=", style = 3)

  last_time <- NULL

  for (i in seq_len(n)) {
    pmid <- df$PMID[i]
    if (is.na(pmid) || !nzchar(pmid)) next

    ## Get references (CR field)
    last_time <- api_throttle(api_key, last_time)
    refs <- tryCatch(
      pmReferences(pmid, api_key = api_key),
      error = function(e) list(references = character(0), count = 0)
    )
    if (refs$count > 0) {
      df$CR[i] <- paste(refs$references, collapse = ";")
    }

    ## Get citation count (TC field)
    last_time <- api_throttle(api_key, last_time)
    cites <- tryCatch(
      pmCitedBy(pmid, api_key = api_key),
      error = function(e) list(cited_by = character(0), count = 0)
    )
    df$TC[i] <- cites$count

    utils::setTxtProgressBar(pb, i)
  }

  close(pb)
  cat("\nCitation enrichment completed.\n")

  return(df)
}
