#' Count the number of documents returned by a query
#'
#' It counts the number of documents that a query returns from the NCBI PubMed database.
#'
#' @param query is a character. It contains a search query formulated using the Entrez query language.
#' @param api_key is a character. It contains a valid API keys for the NCBI E-utilities. Default is \code{api_key=NULL}
#' The use of NCBI PubMed APIs is entirely free, and doesn't necessary require an API key.
#'
#' @return a list. It contains three objects:
#' \tabular{lll}{
#' n \tab  \tab The total number of records returned by the query\cr
#' query_translation \tab       \tab The query transaltion by the NCBI Automatic Terms Translation system \cr
#' web_history \tab      \tab The web history object. The NCBI provides search history features, which isuseful for dealing with large lists of IDs or repeated searches.}
#'
#' To obtain a free access to NCBI API, please visit: \href{https://www.ncbi.nlm.nih.gov/pmc/tools/developers/}{https://www.ncbi.nlm.nih.gov/pmc/tools/developers/}
#'
#'
#' @examples
#'
#' \donttest{
#' query <- "bibliometric*[Title/Abstract] AND english[LA]
#'            AND Journal Article[PT] AND 2000:2020[DP]"
#' D <- pmQueryTotalCount(query = query, api_key = NULL)
#' }
#'
#' @seealso \code{\link{pmApiRequest}}
#' @seealso \code{\link{pmApi2df}}
#'
#' @export
pmQueryTotalCount <- function(query, api_key = NULL) {
  terms <- unlist(lapply(strsplit(query,"\\["), function(l) l[[1]]))
  if (terms %in% c(""," ")){
    results <-
      list(
        total_count = 0,
        query_translation = "Not valid search terms",
        web_history = NA
      )
    return(results)
  }

  d_search <- entrez_search(
    db = "pubmed",
    term = query ,
    retmax = 0,
    api_key = api_key,
    use_history = T
  )

  results <-
    list(
      total_count = d_search$count,
      query_translation = d_search$QueryTranslation,
      web_history = d_search$web_history
    )
  return(results)
}
