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
