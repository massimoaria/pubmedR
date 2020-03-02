#' Gather bibliographic content from PubMed database using NCBI entrez API
#'
#' It gathers metadata about publications from the NCBI PubMed database.
#' The function \code{pmApiRequest} queries NCBI PubMed using an entrez query formulated through the function \code{pmQueryBuild}.
#'
#' @param query is a character. It contains a search query formulated using the Entrez query language.
#' @param limit is numeric. It indicates the max number of records to download.
#' @param api_key is a character. It contains a valid api key API keys for the NCBI E-utilities.
#'
#' @return a list cointaining bibliographic metadata downloaded from NCBI PubMed.
#'
#' To obtain a free access to NCBI API, please visit: \href{https://www.ncbi.nlm.nih.gov/pmc/tools/developers/}{https://www.ncbi.nlm.nih.gov/pmc/tools/developers/}
#'
#' To obtain more information about how to write a NCBI search query, please visit: \href{https://pubmed.ncbi.nlm.nih.gov/help/#search-tags}{https://pubmed.ncbi.nlm.nih.gov/help/#search-tags}
#' @examples
#'
#' # query <- "bibliometric"
#' # D <- pmApiRequest(query = query, limit = 1000, api_key = NULL)
#'
#' @seealso \code{\link{pmQueryTotalCount}}
#' @seealso \code{\link{pmApi2df}}
#'
#' @export
#' @import XML
#' @import rentrez

pmApiRequest <- function(query, limit, api_key=NULL){

  ## query total count
  res <- pmQueryTotalCount(query = query, api_key = api_key)

  n <- min(res$total_count,limit)
  step <- 200
  step <- min(limit, step)
  metadata <- list()
  stop <- FALSE
  s <- 1


  ## download metadata
  while(!isTRUE(stop)) {
    cat("Documents ",s+step - 1," of ", limit,"\n")
    multi_summs <-
      entrez_fetch(
        db = "pubmed",
        web_history = res$web_history,
        retstart = s,
        retmax = step,
        rettype = "xml",
        parsed = T,
        api_key = api_key
      )
    multi_summs <- xmlToList(multi_summs, simplify = F)
    metadata <- c(metadata, multi_summs)

    if (n <= (s + step)) {
      stop <- TRUE
    } else{
      s <- s + step
      if ((s + step) > limit) {
        step <- (n - s + 1)
      }

    }
  }

  P <-
    list(
      data = metadata,
      query = query,
      query_translation = res$query_translation,
      records_downloaded = n,
      total_count = res$total_count
    )
  return(P)
}

