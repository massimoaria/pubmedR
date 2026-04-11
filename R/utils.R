#' @keywords internal
#' Flatten a nested list into a named character vector
#'
#' @param x A nested list (typically from XML parsing)
#' @param use.names Logical, whether to preserve names
#' @param classes Character vector of classes to include
#' @return A named character vector
#' @noRd
list2char <- function(x, use.names = TRUE, classes = "ANY") {
  lung <- sum(rapply(x, function(x) 1L, classes = classes))
  Ch <- vector("list", lung)
  i <- 0L
  items <- rapply(x, function(x) {
    i <<- i + 1L
    ## Sanitize encoding: convert to UTF-8, replacing invalid bytes
    if (is.character(x)) {
      x <- iconv(x, from = "", to = "UTF-8", sub = "")
    }
    Ch[[i]] <<- x
    TRUE
  }, classes = classes)
  if (use.names && !is.null(nm <- names(items)))
    names(Ch) <- nm
  Ch <- unlist(Ch)
  return(Ch)
}


#' Retrieve NCBI API key
#'
#' Looks for an API key in the following order:
#' 1. Explicit argument passed by user
#' 2. Environment variable PUBMED_API_KEY
#' 3. Environment variable ENTREZ_KEY (rentrez convention)
#'
#' @param api_key A character string or NULL
#' @return A character string (API key) or NULL
#' @noRd
get_api_key <- function(api_key = NULL) {
  if (!is.null(api_key) && nzchar(api_key)) {
    return(api_key)
  }
  key <- Sys.getenv("PUBMED_API_KEY", unset = "")
  if (nzchar(key)) return(key)
  key <- Sys.getenv("ENTREZ_KEY", unset = "")
  if (nzchar(key)) return(key)
  return(NULL)
}


#' Rate-limited pause between API requests
#'
#' Enforces NCBI rate limits: 3 requests/sec without API key,
#' 10 requests/sec with API key.
#'
#' @param api_key A character string or NULL
#' @param last_request_time POSIXct time of the last request
#' @return POSIXct time after the pause (to be used as next last_request_time)
#' @noRd
api_throttle <- function(api_key = NULL, last_request_time = NULL) {
  min_interval <- if (is.null(api_key)) 1 / 3 else 1 / 10
  if (!is.null(last_request_time)) {
    elapsed <- as.numeric(Sys.time() - last_request_time, units = "secs")
    if (elapsed < min_interval) {
      Sys.sleep(min_interval - elapsed)
    }
  }
  return(Sys.time())
}


#' Execute an API call with retry logic
#'
#' Wraps an expression with error handling and exponential backoff retry.
#'
#' @param expr An expression to evaluate (typically an API call)
#' @param max_retries Maximum number of retry attempts
#' @param verbose Logical, whether to print retry messages
#' @return The result of the expression
#' @noRd
api_call_with_retry <- function(expr, max_retries = 3, verbose = TRUE) {
  for (attempt in seq_len(max_retries + 1)) {
    result <- tryCatch(
      expr,
      error = function(e) {
        if (attempt > max_retries) {
          stop(sprintf(
            "API request failed after %d attempts. Last error: %s",
            max_retries + 1, conditionMessage(e)
          ), call. = FALSE)
        }
        wait_time <- min(2^(attempt - 1), 30)
        if (verbose) {
          message(sprintf(
            "API request failed (attempt %d/%d): %s. Retrying in %ds...",
            attempt, max_retries + 1, conditionMessage(e), wait_time
          ))
        }
        Sys.sleep(wait_time)
        return(NULL)
      }
    )
    if (!is.null(result)) return(result)
  }
}
