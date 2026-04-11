#' Fetch PubMed records by PMID
#'
#' It downloads metadata for a set of PubMed articles identified by their PMID (PubMed Identifier).
#' This is useful for retrieving specific known articles, updating existing datasets,
#' or downloading records identified through other sources.
#'
#' @param pmids is a character or numeric vector. A vector of PubMed identifiers (PMIDs).
#' @param api_key is a character. It contains a valid API key for the NCBI E-utilities.
#' Default is \code{api_key=NULL}. The API key can also be set via the environment variable
#' \code{PUBMED_API_KEY} or \code{ENTREZ_KEY}.
#' @param batch_size is numeric. The number of records to download per API request. Default is 200.
#'
#' @return a list following the same structure as \code{\link{pmApiRequest}} output, containing:
#' \tabular{lll}{
#' data \tab \tab The xml-structured list containing the bibliographic metadata.\cr
#' query \tab \tab A character string describing the PMID-based query.\cr
#' query_translation \tab \tab Same as query for PMID-based searches.\cr
#' records_downloaded \tab \tab The total number of records downloaded.\cr
#' total_count \tab \tab The total number of PMIDs requested.}
#'
#' @details
#' The function uses the NCBI E-utilities \code{efetch} endpoint to retrieve records directly
#' by their PMIDs, without requiring a search query. Records are downloaded in batches
#' to respect API rate limits.
#'
#' The output is compatible with \code{\link{pmApi2df}} for conversion to a dataframe.
#'
#' @examples
#'
#' \donttest{
#' # Download specific articles by PMID
#' pmids <- c("34813985", "34813456", "34812345")
#' D <- pmFetchById(pmids = pmids)
#' M <- pmApi2df(D)
#' }
#'
#' @seealso \code{\link{pmApiRequest}}
#' @seealso \code{\link{pmApi2df}}
#'
#' @export
#' @import XML
#' @import rentrez

pmFetchById <- function(pmids, api_key = NULL, batch_size = 200) {

  api_key <- get_api_key(api_key)
  pmids <- as.character(unique(pmids))
  pmids <- pmids[nzchar(trimws(pmids))]

  if (length(pmids) == 0) {
    stop("No valid PMIDs provided.", call. = FALSE)
  }

  n <- length(pmids)
  metadata <- list()
  last_time <- NULL

  cat("\nDownloading", n, "documents from PubMed by PMID...\n")
  pb <- utils::txtProgressBar(min = 0, max = n, initial = 0, char = "=", style = 3)

  ## Download in batches
  s <- 1
  while (s <= n) {
    end <- min(s + batch_size - 1, n)
    batch_ids <- pmids[s:end]

    ## Rate limiting
    last_time <- api_throttle(api_key, last_time)

    ## Fetch with retry
    multi_summs <- api_call_with_retry(
      entrez_fetch(
        db = "pubmed",
        id = batch_ids,
        rettype = "xml",
        parsed = TRUE,
        api_key = api_key
      )
    )

    multi_summs <- xmlToList(multi_summs, simplify = FALSE)
    metadata <- c(metadata, multi_summs)

    utils::setTxtProgressBar(pb, end)
    s <- end + 1
  }

  close(pb)
  cat("\nDownload completed.\n")

  P <- list(
    data = metadata,
    query = paste("PMID:", paste(pmids[1:min(5, n)], collapse = ", "),
                  if (n > 5) paste0("... (", n, " total)") else ""),
    query_translation = paste(n, "PMIDs"),
    records_downloaded = length(metadata),
    total_count = n
  )
  return(P)
}
