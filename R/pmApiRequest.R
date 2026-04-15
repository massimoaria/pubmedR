#' Gather bibliographic content from PubMed database using NCBI entrez APIs
#'
#' It gathers metadata about publications from the NCBI PubMed database.
#' The use of NCBI PubMed APIs is entirely free, and doesn't necessarily require an API key.
#' The function \code{pmApiRequest} queries NCBI PubMed using an entrez query formulated through
#' the Entrez query language or the helper function \code{\link{pmQueryBuild}}.
#'
#' Official API documentation is \href{https://www.ncbi.nlm.nih.gov/books/NBK25500/}{https://www.ncbi.nlm.nih.gov/books/NBK25500/}.
#' @param query is a character. It contains a search query formulated using the Entrez query language.
#' @param limit is numeric. It indicates the max number of records to download.
#' @param api_key is a character. It contains a valid API key for the NCBI E-utilities.
#' Default is \code{api_key=NULL}. The API key can also be set via the environment variable
#' \code{PUBMED_API_KEY} or \code{ENTREZ_KEY}.
#' @param batch_size is numeric. The number of records to download per API request. Default is 200.
#'
#' @return a list D composed by 5 objects:
#'\tabular{lll}{
#' data \tab \tab It is the xml-structured list containing the bibliographic metadata collection downloaded from the PubMed database.\cr
#' query \tab \tab It a character object containing the original query formulated by the user.\cr
#' query_translation \tab \tab It a character object containing the query, translated by the NCBI Automatic Terms Translation system and submitted to the PubMed database.\cr
#' records_downloaded \tab \tab It is an integer object indicating the total number of records downloaded and stored in "data".\cr
#' total_count \tab \tab It is an integer object indicating the total number of records matching the query (stored in the "query_translation" object").}
#'
#' To obtain a free access to NCBI API, please visit: \href{https://pmc.ncbi.nlm.nih.gov/tools/developers/}{https://pmc.ncbi.nlm.nih.gov/tools/developers/}
#'
#' To obtain more information about how to write a NCBI search query, please visit: \href{https://pubmed.ncbi.nlm.nih.gov/help/#search-tags}{https://pubmed.ncbi.nlm.nih.gov/help/#search-tags}
#'
#' @examples
#'
#' \donttest{
#' query <- "bibliometric*[Title/Abstract] AND english[LA]
#'           AND Journal Article[PT] AND 2000:2020[DP]"
#'  D <- pmApiRequest(query = query, limit = 100, api_key = NULL)
#' }
#'
#' @seealso \code{\link{pmQueryTotalCount}}
#' @seealso \code{\link{pmApi2df}}
#' @seealso \code{\link{pmQueryBuild}}
#'
#' @export
#' @import XML
#' @import rentrez

pmApiRequest <- function(query, limit, api_key = NULL, batch_size = 200) {
  api_key <- get_api_key(api_key)

  ## query total count
  res <- pmQueryTotalCount(query = query, api_key = api_key)

  if (res$total_count == 0) {
    message("No records found for the given query.")
    P <- list(
      data = list(),
      query = query,
      query_translation = res$query_translation,
      records_downloaded = 0,
      total_count = 0
    )
    return(P)
  }

  n <- min(res$total_count, limit)
  step <- min(n, batch_size)
  metadata <- list()
  s <- 0
  last_time <- NULL
  n_batches <- ceiling(n / step)

  cat("\nDownloading", n, "documents from PubMed...\n")
  pb <- utils::txtProgressBar(
    min = 0,
    max = n,
    initial = 0,
    char = "=",
    style = 3
  )

  ## download metadata in batches
  while (s < n) {
    current_step <- min(step, n - s)

    ## Rate limiting
    last_time <- api_throttle(api_key, last_time)

    ## Fetch with retry
    multi_summs <- api_call_with_retry(
      entrez_fetch(
        db = "pubmed",
        web_history = res$web_history,
        retstart = s,
        retmax = current_step,
        rettype = "xml",
        parsed = TRUE,
        api_key = api_key
      )
    )

    multi_summs <- xmlToList(multi_summs, simplify = FALSE)
    metadata <- c(metadata, multi_summs)

    s <- s + current_step
    utils::setTxtProgressBar(pb, s)
  }

  close(pb)
  cat("\nDownload completed.\n")

  P <- list(
    data = metadata,
    query = query,
    query_translation = res$query_translation,
    records_downloaded = n,
    total_count = res$total_count
  )
  return(P)
}
