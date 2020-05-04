#' Gather bibliographic content from PubMed database using NCBI entrez APIs
#'
#' It gathers metadata about publications from the NCBI PubMed database.
#' The use of NCBI PubMed APIs is entirely free, and doesn't necessary require an API key.
#' The function \code{pmApiRequest} queries NCBI PubMed using an entrez query formulated through the function \code{pmQueryBuild}.
#'
#' Official API documentation is \href{https://www.ncbi.nlm.nih.gov/books/NBK25500/}{https://www.ncbi.nlm.nih.gov/books/NBK25500/}.
#' @param query is a character. It contains a search query formulated using the Entrez query language.
#' @param limit is numeric. It indicates the max number of records to download.
#' @param api_key is a character. It contains a valid api key API keys for the NCBI E-utilities.
#'
#' @return a list D composed by 5 objects:
#'\tabular{lll}{
#' data \tab \tab It is the xml-structured list containing the bibliographic metadata collection downloaded from the PubMed database.\cr
#' query \tab \tab It a character object containing the original query formulated by the user.\cr
#' query_translation \tab \tab It a character object containing the query, translated by the NCBI Automatic Terms Translation system and submitted to the PubMed database.\cr
#' records_downloaded \tab \tab It is an integer object indicating the total number of records downloaded and stored in "data".\cr
#' total_counts \tab \tab It is an integer object indicating the total number of records matching the query (stored in the "query_translation" object").}
#'
#' To obtain a free access to NCBI API, please visit: \href{https://www.ncbi.nlm.nih.gov/pmc/tools/developers/}{https://www.ncbi.nlm.nih.gov/pmc/tools/developers/}
#'
#' To obtain more information about how to write a NCBI search query, please visit: \href{https://pubmed.ncbi.nlm.nih.gov/help/#search-tags}{https://pubmed.ncbi.nlm.nih.gov/help/#search-tags}
#'
#' @examples
#'
#' \donttest{
#' query <- query <- "bibliometric*[Title/Abstract] AND english[LA]
#'                     AND Journal Article[PT] AND 2000:2020[DP]"
#'  D <- pmApiRequest(query = query, limit = 100, api_key = NULL)
#' }
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
    cat("Documents ",s+step - 1," of ", n,"\n")
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

