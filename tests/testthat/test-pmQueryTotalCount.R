test_that("pmQueryTotalCount rejects empty query", {
  result <- pmQueryTotalCount(query = "[Title/Abstract]", api_key = NULL)
  expect_equal(result$total_count, 0)
  expect_equal(result$query_translation, "Not valid search terms")
})

test_that("pmQueryTotalCount rejects blank query", {
  result <- pmQueryTotalCount(query = " [Title/Abstract]", api_key = NULL)
  expect_equal(result$total_count, 0)
})

# Integration tests - require network access
test_that("pmQueryTotalCount returns results for valid query", {
  skip_on_cran()
  skip_if_offline()

  result <- pmQueryTotalCount(
    query = "bibliometric*[Title/Abstract] AND english[LA] AND 2020:2020[DP]",
    api_key = NULL
  )
  expect_true(result$total_count > 0)
  expect_type(result$query_translation, "character")
  expect_false(is.null(result$web_history))
})
