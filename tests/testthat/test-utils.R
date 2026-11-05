test_that("list2char flattens nested lists correctly", {
  x <- list(a = list(b = "hello", c = "world"), d = "foo")
  result <- pubmedR:::list2char(x)
  expect_type(result, "character")
  expect_true(length(result) == 3)
  expect_equal(unname(result[1]), "hello")
})

test_that("get_api_key returns explicit key first", {
  result <- pubmedR:::get_api_key("my_key_123")
  expect_equal(result, "my_key_123")
})

test_that("get_api_key returns NULL when no key available", {
  withr::with_envvar(
    c(PUBMED_API_KEY = "", ENTREZ_KEY = ""),
    {
      result <- pubmedR:::get_api_key(NULL)
      expect_null(result)
    }
  )
})

test_that("get_api_key reads PUBMED_API_KEY env var", {
  withr::with_envvar(
    c(PUBMED_API_KEY = "env_key_123", ENTREZ_KEY = ""),
    {
      result <- pubmedR:::get_api_key(NULL)
      expect_equal(result, "env_key_123")
    }
  )
})

test_that("get_api_key reads ENTREZ_KEY as fallback", {
  withr::with_envvar(
    c(PUBMED_API_KEY = "", ENTREZ_KEY = "entrez_key_456"),
    {
      result <- pubmedR:::get_api_key(NULL)
      expect_equal(result, "entrez_key_456")
    }
  )
})

test_that("api_throttle enforces rate limiting", {
  t1 <- Sys.time()
  t2 <- pubmedR:::api_throttle(api_key = NULL, last_request_time = t1)
  elapsed <- as.numeric(t2 - t1, units = "secs")
  # Without API key, should wait at least ~0.33s

  expect_true(elapsed >= 0.3)
})

test_that("api_throttle is faster with API key", {
  t1 <- Sys.time()
  t2 <- pubmedR:::api_throttle(api_key = "key", last_request_time = t1)
  elapsed <- as.numeric(t2 - t1, units = "secs")
  # With API key, should wait at least ~0.1s but less than 0.33s
  expect_true(elapsed >= 0.09)
  expect_true(elapsed < 0.33)
})


test_that("api_call_with_retry retries without warnings and gets the value", {
  k <- 0
  res <- suppressMessages(expect_no_warning(pubmedR:::api_call_with_retry({
    k <- k + 1
    if (k < 2) stop("HTTP failure: 500\n<html>")
    "ok"
  })))
  expect_equal(res, "ok")
  expect_equal(k, 2)
})

test_that("api_call_with_retry does not retry a client error, nor quote the page", {
  k <- 0
  expect_error(
    pubmedR:::api_call_with_retry({
      k <- k + 1
      stop("HTTP failure: 400\n<html>page</html>")
    }),
    "^API request failed. HTTP failure: 400$"
  )
  expect_equal(k, 1)
})

test_that("api_call_with_retry returns a NULL result at once", {
  k <- 0
  expect_null(pubmedR:::api_call_with_retry({
    k <- k + 1
    NULL
  }))
  expect_equal(k, 1)
})

test_that("node_text keeps the pieces in order and leaves out the attributes", {
  x <- list(text = "PM", sub = "2.5", text = " and O", sub = "3", .attrs = c(Label = "L"))
  expect_equal(pubmedR:::node_text(x), "PM2.5 and O3")
  expect_equal(pubmedR:::node_text("plain"), "plain")
  expect_true(is.na(pubmedR:::node_text(NULL)))
})

test_that("parse_batch stops on an error from PubMed", {
  doc <- XML::xmlParse("<x><ERROR>too far</ERROR></x>", asText = TRUE)
  expect_error(pubmedR:::parse_batch(doc), "too far")
})

test_that("split_query_by_date halves until each part fits, and goes down to months", {
  counts <- function(q) {
    range <- sub(".*AND (.*)\\[CRDT\\]$", "\\1", q)
    if (grepl("/", range)) return(if (grepl("^2024/01", range)) 12000 else 100)
    parts <- as.integer(strsplit(range, ":")[[1]])
    if (length(parts) == 1) parts <- rep(parts, 2)
    if (parts[2] < 2020) return(0)
    if (parts[1] <= 2024 && parts[2] >= 2024) return(20000)
    100
  }
  local_mocked_bindings(
    pmQueryTotalCount = function(query, api_key = NULL) list(total_count = counts(query)),
    api_throttle = function(...) Sys.time()
  )
  parts <- suppressWarnings(pubmedR:::split_query_by_date("x"))
  ranges <- sub(".*AND (.*)\\[CRDT\\]$", "\\1", unlist(parts))
  expect_false(any(grepl("^2024$", ranges)))
  expect_true("2024/02" %in% ranges)
  expect_true("2024/01/15" %in% ranges)
  expect_true(any(grepl("^2\\d{3}", ranges)))
})

test_that("pmApiRequest goes through every part, up to the limit", {
  fixture <- pubmedR:::parse_batch(XML::xmlParse(test_path("fixtures", "records.xml")))
  seen <- list()
  local_mocked_bindings(
    pmQueryTotalCount = function(query, api_key = NULL) {
      list(total_count = if (identical(query, "big")) 20000 else 3,
           query_translation = query, web_history = query)
    },
    split_query_by_date = function(query, api_key = NULL) list("part1", "part2", "part3"),
    entrez_fetch = function(web_history, retstart, retmax, ...) {
      seen[[length(seen) + 1]] <<- c(web_history, retstart, retmax)
      XML::xmlParse(test_path("fixtures", "records.xml"))
    },
    api_throttle = function(...) Sys.time(),
    pm_search_cap = 2L
  )
  utils::capture.output(suppressMessages(
    D <- pmApiRequest("big", limit = 5, batch_size = 2)
  ))
  by_part <- table(vapply(seen, `[`, "", 1))
  expect_equal(names(by_part), c("part1", "part2", "part3"))
  expect_equal(D$query, "big")
  expect_equal(D$total_count, 20000)
  expect_equal(D$records_downloaded, length(D$data))
  expect_gt(length(fixture), 0)
})
