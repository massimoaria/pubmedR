#' Collect and process PubMed bibliographic data in one step
#'
#' A convenience wrapper that executes the full pubmedR workflow:
#' query building, record count check, metadata download, conversion to
#' data frame, and (optionally) citation enrichment via NCBI E-Link.
#'
#' @param query is a character. A PubMed search query in Entrez syntax.
#' Alternatively, if \code{terms} is provided, the query is built automatically
#' using \code{\link{pmQueryBuild}} and this argument is ignored.
#' @param terms is a character or character vector or NULL. Search terms passed to
#' \code{\link{pmQueryBuild}}. When provided, a query is built automatically
#' and the \code{query} argument is ignored. Default is \code{NULL}.
#' @param fields is a character or character vector. PubMed search tags used
#' when building the query from \code{terms}. Default is \code{"Title/Abstract"}.
#' @param language is a character or NULL. Language filter for query building.
#' Default is \code{NULL}.
#' @param pub_type is a character or NULL. Publication type filter for query building.
#' Default is \code{NULL}.
#' @param date_range is a character vector of length 2 or NULL. Date range
#' in format \code{c("YYYY", "YYYY")}. Default is \code{NULL}.
#' @param mesh_terms is a character or character vector or NULL. MeSH terms
#' for query building. Default is \code{NULL}.
#' @param limit is numeric. Maximum number of records to download.
#' Default is \code{2000}.
#' @param enrich is logical. If \code{TRUE}, citation counts (TC) and cited
#' references (CR) are added via \code{\link{pmEnrichCitations}}.
#' Default is \code{FALSE} because enrichment makes 2 API calls per article
#' and can be slow for large collections.
#' @param format is a character. Output format passed to \code{\link{pmApi2df}}.
#' Either \code{"bibliometrix"} (default) or \code{"raw"}.
#' @param api_key is a character or NULL. NCBI API key. Can also be set via
#' the environment variable \code{PUBMED_API_KEY} or \code{ENTREZ_KEY}.
#' Default is \code{NULL}.
#' @param batch_size is numeric. Records per API request. Default is 200.
#' @param verbose is logical. If \code{TRUE} (default), prints progress messages.
#'
#' @return a data frame containing bibliographic records, compatible with the
#' \code{bibliometrix} package when \code{format = "bibliometrix"}.
#'
#' @details
#' This function chains together the core pubmedR functions in the recommended order:
#' \enumerate{
#'   \item \strong{Query}: If \code{terms} is provided, builds the query with
#'         \code{\link{pmQueryBuild}}; otherwise uses the \code{query} string directly.
#'   \item \strong{Count}: Checks the total number of matching records with
#'         \code{\link{pmQueryTotalCount}}.
#'   \item \strong{Download}: Fetches metadata with \code{\link{pmApiRequest}}.
#'   \item \strong{Convert}: Transforms XML to a data frame with \code{\link{pmApi2df}}.
#'   \item \strong{Enrich} (optional): Adds citation data with
#'         \code{\link{pmEnrichCitations}}.
#' }
#'
#' @examples
#'
#' \donttest{
#' # Using a raw query string
#' M <- pmCollect(
#'   query = "bibliometric*[Title/Abstract] AND english[LA] AND 2020:2024[DP]",
#'   limit = 50
#' )
#'
#' # Using the query builder parameters
#' M <- pmCollect(
#'   terms = "bibliometric*",
#'   language = "english",
#'   pub_type = "Journal Article",
#'   date_range = c("2020", "2024"),
#'   limit = 50
#' )
#'
#' # With citation enrichment (slower, requires extra API calls)
#' M <- pmCollect(
#'   terms = "bibliometric*",
#'   date_range = c("2023", "2024"),
#'   limit = 10,
#'   enrich = TRUE
#' )
#' }
#'
#' @seealso \code{\link{pmQueryBuild}}, \code{\link{pmQueryTotalCount}},
#' \code{\link{pmApiRequest}}, \code{\link{pmApi2df}}, \code{\link{pmEnrichCitations}}
#'
#' @export

pmCollect <- function(query = NULL,
                      terms = NULL,
                      fields = "Title/Abstract",
                      language = NULL,
                      pub_type = NULL,
                      date_range = NULL,
                      mesh_terms = NULL,
                      limit = 2000,
                      enrich = FALSE,
                      format = "bibliometrix",
                      api_key = NULL,
                      batch_size = 200,
                      verbose = TRUE) {

  api_key <- get_api_key(api_key)

  ## Step 1: Build or validate query
  if (!is.null(terms)) {
    query <- pmQueryBuild(
      terms = terms,
      fields = fields,
      language = language,
      pub_type = pub_type,
      date_range = date_range,
      mesh_terms = mesh_terms
    )
    if (verbose) cat("Query: ", query, "\n\n")
  }

  if (is.null(query) || !nzchar(trimws(query))) {
    stop("A query string or search terms must be provided.", call. = FALSE)
  }

  ## Step 2: Count matching records
  res <- pmQueryTotalCount(query = query, api_key = api_key)

  if (verbose) {
    cat("Total records found:", res$total_count, "\n")
    cat("Records to download:", min(res$total_count, limit), "\n\n")
  }

  if (res$total_count == 0) {
    message("No records found. Returning empty data frame.")
    return(data.frame())
  }

  ## Step 3: Download metadata
  D <- pmApiRequest(
    query = query,
    limit = limit,
    api_key = api_key,
    batch_size = batch_size
  )

  ## Step 4: Convert to data frame
  M <- pmApi2df(D, format = format)

  if (verbose) {
    cat("\nRecords converted:", nrow(M), "\n")
  }

  ## Step 5: Enrich with citation data (optional)
  if (enrich) {
    if (verbose) cat("\nEnriching with citation data...\n")
    M <- pmEnrichCitations(M, api_key = api_key)
  }

  if (verbose) cat("\nDone.\n")

  return(M)
}
