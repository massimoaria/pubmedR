#' Count the documents of a query by publication year
#'
#' It returns the publication trend of a query without downloading its records,
#' with one request per year.
#'
#' @param query is a character. A search query in the Entrez query language.
#' @param years is a numeric vector of years. Default is the last 20 years.
#' @param api_key is a character. A valid API key for the NCBI E-utilities. Default is
#' \code{api_key=NULL}. It can also be set via the environment variable
#' \code{PUBMED_API_KEY} or \code{ENTREZ_KEY}.
#'
#' @return a data frame with the columns \code{year} and \code{count}, in the order
#' of \code{years}.
#'
#' @examplesIf interactive()
#' pmCountByYear("bibliometric*[Title/Abstract]", years = 2015:2024)
#'
#' @seealso \code{\link{pmQueryTotalCount}}, \code{\link{pmQueryBuild}}
#'
#' @export
pmCountByYear <- function(query, years = NULL, api_key = NULL) {
  api_key <- get_api_key(api_key)
  if (is.null(years)) {
    this_year <- as.integer(format(Sys.Date(), "%Y"))
    years <- (this_year - 19L):this_year
  }
  years <- as.integer(years)

  last_time <- NULL
  counts <- vapply(years, function(y) {
    last_time <<- api_throttle(api_key, last_time)
    q <- sprintf("(%s) AND %d[DP]", query, y)
    as.numeric(pmQueryTotalCount(query = q, api_key = api_key)$total_count)
  }, numeric(1))

  data.frame(year = years, count = counts)
}
