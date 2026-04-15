#' Count the number of documents returned by a query
#'
#' It counts the number of documents that a query returns from the NCBI PubMed database.
#'
#' @param query is a character. It contains a search query formulated using the Entrez query language.
#' @param api_key is a character. It contains a valid API key for the NCBI E-utilities. Default is \code{api_key=NULL}.
#' The use of NCBI PubMed APIs is entirely free, and doesn't necessarily require an API key.
#' The API key can also be set via the environment variable \code{PUBMED_API_KEY} or \code{ENTREZ_KEY}.
#'
#' @return a list. It contains three objects:
#' \tabular{lll}{
#' total_count \tab  \tab The total number of records returned by the query\cr
#' query_translation \tab       \tab The query translation by the NCBI Automatic Terms Translation system \cr
#' web_history \tab      \tab The web history object. The NCBI provides search history features, which is useful for dealing with large lists of IDs or repeated searches.}
#'
#' To obtain a free access to NCBI API, please visit: \href{https://pmc.ncbi.nlm.nih.gov/tools/developers/}{https://pmc.ncbi.nlm.nih.gov/tools/developers/}
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
  api_key <- get_api_key(api_key)

  ## Validate query
  terms <- unlist(lapply(strsplit(query, "\\["), function(l) trimws(l[[1]])))
  if (all(terms %in% c("", " "))) {
    results <- list(
      total_count = 0,
      query_translation = "Not valid search terms",
      web_history = NA
    )
    return(results)
  }

  ## Search with retry logic
  d_search <- api_call_with_retry(
    entrez_search(
      db = "pubmed",
      term = query,
      retmax = 0,
      api_key = api_key,
      use_history = TRUE
    )
  )

  results <- list(
    total_count = d_search$count,
    query_translation = d_search$QueryTranslation,
    web_history = d_search$web_history
  )
  return(results)
}
