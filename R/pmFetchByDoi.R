#' Fetch PubMed records by DOI
#'
#' It downloads the PubMed records of a set of articles identified by their DOI,
#' for instance to complete a collection coming from another database.
#'
#' @param dois is a character vector of DOIs, with or without the
#' \code{https://doi.org/} prefix.
#' @param api_key is a character. A valid API key for the NCBI E-utilities. Default is
#' \code{api_key=NULL}. It can also be set via the environment variable
#' \code{PUBMED_API_KEY} or \code{ENTREZ_KEY}.
#' @param batch_size is numeric. DOIs per search. Default is 50.
#'
#' @return a list with the same structure as the output of
#' \code{\link{pmFetchById}}, ready for \code{\link{pmApi2df}}, with one more
#' element: \code{not_found}, the DOIs with no PubMed record.
#'
#' @examplesIf interactive()
#' D <- pmFetchByDoi(c("10.1016/j.joi.2017.08.007", "10.1038/nature14539"))
#' D$not_found
#' M <- pmApi2df(D)
#'
#' @seealso \code{\link{pmFetchById}}, \code{\link{pmApi2df}}
#'
#' @export
pmFetchByDoi <- function(dois, api_key = NULL, batch_size = 50) {
  api_key <- get_api_key(api_key)
  dois <- sub("^(https?://(dx\\.)?doi\\.org/|doi:)", "", trimws(as.character(dois)),
              ignore.case = TRUE)
  dois <- unique(dois[!is.na(dois) & nzchar(dois)])
  if (length(dois) == 0) {
    stop("No valid DOIs provided.", call. = FALSE)
  }

  pmids <- character(0)
  last_time <- NULL
  for (batch in split(dois, ceiling(seq_along(dois) / batch_size))) {
    last_time <- api_throttle(api_key, last_time)
    term <- paste(sprintf('"%s"[AID]', batch), collapse = " OR ")
    found <- api_call_with_retry(
      entrez_search(db = "pubmed", term = term, retmax = length(batch) * 2L, api_key = api_key)
    )
    pmids <- c(pmids, found$ids)
  }

  if (length(pmids) == 0) {
    return(list(
      data = list(),
      query = paste(length(dois), "DOIs"),
      query_translation = paste(length(dois), "DOIs"),
      records_downloaded = 0,
      total_count = 0,
      not_found = dois
    ))
  }

  P <- pmFetchById(pmids, api_key = api_key)
  found <- unlist(lapply(P$data, record_ids, type = "doi"), use.names = FALSE)
  P$query <- paste(length(dois), "DOIs")
  P$query_translation <- P$query
  P$not_found <- dois[!tolower(dois) %in% tolower(found)]
  P
}


#' The identifiers of a given type of a parsed record
#' @noRd
record_ids <- function(rec, type) {
  ids <- rec$PubmedData$ArticleIdList
  if (is.null(ids)) ids <- rec$PubmedBookData$ArticleIdList
  ids <- ids[names(ids) == "ArticleId"]
  keep <- vapply(
    ids,
    function(x) is.list(x) && identical(unname(x$.attrs["IdType"]), type),
    logical(1)
  )
  vapply(ids[keep], node_text, character(1), USE.NAMES = FALSE)
}
