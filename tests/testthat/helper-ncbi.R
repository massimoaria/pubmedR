# Evaluate a live call, and skip the test if NCBI does not answer: an outage says
# nothing about the package.
ncbi_or_skip <- function(expr) {
  tryCatch(expr, error = function(e) {
    if (grepl("API request failed after", conditionMessage(e), fixed = TRUE)) {
      testthat::skip("NCBI is not answering")
    }
    stop(e)
  })
}
