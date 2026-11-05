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
#' @details
#' PubMed serves only the first 9,999 records of a search. When more than that are
#' requested, the query is split by the date each record was added to PubMed, and each
#' part is downloaded in turn, so \code{limit} can exceed this figure. Records then
#' come ordered by that date period, newest first, not as in the whole search.
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
#' @examplesIf interactive()
#' query <- "bibliometric*[Title/Abstract] AND english[LA]
#'           AND Journal Article[PT] AND 2000:2020[DP]"
#'  D <- pmApiRequest(query = query, limit = 100, api_key = NULL)
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
  metadata <- list()
  last_time <- NULL

  ## PubMed serves at most 9,999 records of a search
  queries <- if (n > pm_search_cap) {
    message(
      "PubMed serves at most ", format(pm_search_cap, big.mark = ","),
      " records per search: splitting the query by the date records were added."
    )
    split_query_by_date(query, api_key)
  } else {
    list(res$web_history)
  }

  cat("\nDownloading", n, "documents from PubMed...\n")
  pb <- utils::txtProgressBar(
    min = 0,
    max = max(n, 1),
    initial = 0,
    char = "=",
    style = 3
  )

  ## download metadata in batches
  downloaded <- 0
  for (part in queries) {
    if (downloaded >= n) break
    if (is.character(part)) {
      part <- pmQueryTotalCount(query = part, api_key = api_key)
      part_n <- part$total_count
      part <- part$web_history
    } else {
      part_n <- n
    }
    part_n <- min(part_n, n - downloaded, pm_search_cap)

    s <- 0
    while (s < part_n) {
      current_step <- min(batch_size, part_n - s)

      ## Rate limiting
      last_time <- api_throttle(api_key, last_time)

      ## Fetch with retry
      multi_summs <- api_call_with_retry(
        parse_batch(entrez_fetch(
          db = "pubmed",
          web_history = part,
          retstart = s,
          retmax = current_step,
          rettype = "xml",
          parsed = TRUE,
          api_key = api_key
        ))
      )

      metadata <- c(metadata, multi_summs)

      s <- s + current_step
      utils::setTxtProgressBar(pb, downloaded + s)
    }
    downloaded <- downloaded + part_n
  }

  close(pb)
  cat("\nDownload completed.\n")

  P <- list(
    data = metadata,
    query = query,
    query_translation = res$query_translation,
    records_downloaded = length(metadata),
    total_count = res$total_count
  )
  return(P)
}


## The number of records PubMed serves for one search
pm_search_cap <- 9999L


#' Split a query into parts small enough to download
#'
#' Halves the range of years until each part fits within the cap, and goes down to
#' months and days for a year too large by itself. It uses the date a record was
#' added to PubMed ([CRDT]), which a record has only one of: the publication date
#' ([DP]) matches both the print and the electronic date, so a record could fall
#' in two parts.
#'
#' @param query The query.
#' @param api_key The API key, or \code{NULL}.
#' @return A list of query strings.
#' @noRd
split_query_by_date <- function(query, api_key = NULL) {
  last_time <- NULL
  count <- function(range) {
    last_time <<- api_throttle(api_key, last_time)
    q <- sprintf("(%s) AND %s[CRDT]", query, range)
    list(q = q, n = pmQueryTotalCount(query = q, api_key = api_key)$total_count)
  }
  warned <- FALSE
  over_cap <- function(x, what) {
    if (!warned) {
      warning(
        "The records of ", what, " exceed what PubMed can serve: only the first ",
        format(pm_search_cap, big.mark = ","), " of them can be downloaded.",
        call. = FALSE
      )
      warned <<- TRUE
    }
    list(x$q)
  }
  by_day <- function(year, month) {
    last <- as.integer(format(
      seq(as.Date(sprintf("%d-%02d-01", year, month)), by = "month", length.out = 2)[2] - 1,
      "%d"
    ))
    unlist(lapply(seq_len(last), function(d) {
      x <- count(sprintf("%d/%02d/%02d", year, month, d))
      if (x$n == 0) return(list())
      if (x$n > pm_search_cap) return(over_cap(x, sprintf("%d/%02d/%02d", year, month, d)))
      list(x$q)
    }), recursive = FALSE)
  }
  by_month <- function(year) {
    unlist(lapply(1:12, function(m) {
      x <- count(sprintf("%d/%02d", year, m))
      if (x$n == 0) return(list())
      if (x$n > pm_search_cap) return(by_day(year, m))
      list(x$q)
    }), recursive = FALSE)
  }
  halve <- function(from, to) {
    range <- if (from == to) as.character(from) else sprintf("%d:%d", from, to)
    x <- count(range)
    if (x$n == 0) return(list())
    if (x$n <= pm_search_cap) return(list(x$q))
    if (from == to) return(by_month(from))
    mid <- (from + to) %/% 2L
    c(halve(mid + 1L, to), halve(from, mid))
  }
  halve(1800L, as.integer(format(Sys.Date(), "%Y")) + 1L)
}
