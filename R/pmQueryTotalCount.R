#' Count the number of documents returned by a query
#' #'
#' It counts the number of documents that a query returns from the NCBI PubMed database.
#'
#' @param query is a character. It contains a search query formulated using the Entrez query language.
#' A query can be automatically generated using the function \code{pmQueryBuild}.
#' @param api_key is a character. It contains a valid api key API keys for the NCBI E-utilities.
#'
#' @return a list. It contains three objects:
#' \tabular{lll}{
#' n \tab  \tab the total number of records returned by the query\cr
#' query_translation \tab       \tab The query transaltion \cr
#' web_history \tab      \tab the web history object}
#'
#' To obtain a free access to NCBI API, please visit: \href{https://www.ncbi.nlm.nih.gov/pmc/tools/developers/}{https://www.ncbi.nlm.nih.gov/pmc/tools/developers/}
#'
#'
#' @examples
#'
#' # query <- "bibliometric"
#' # D <- pmQueryTotalCount(query = query, api_key = NULL)
#'
#' @seealso \code{\link{pmApiRequest}}
#' @seealso \code{\link{pmApi2df}}
#'
#' @export
pmQueryTotalCount <- function(query, api_key = NULL) {
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
}
