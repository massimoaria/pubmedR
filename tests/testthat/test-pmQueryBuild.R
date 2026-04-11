test_that("pmQueryBuild creates simple query", {
  q <- pmQueryBuild(terms = "bibliometrics", language = "english")
  expect_true(grepl("bibliometrics\\[Title/Abstract\\]", q))
  expect_true(grepl("english\\[LA\\]", q))
  expect_true(grepl("AND", q))
})

test_that("pmQueryBuild handles multiple terms with OR", {
  q <- pmQueryBuild(terms = c("machine learning", "deep learning"), operator = "OR")
  expect_true(grepl("machine learning", q))
  expect_true(grepl("deep learning", q))
  expect_true(grepl("OR", q))
})

test_that("pmQueryBuild handles date range", {
  q <- pmQueryBuild(terms = "cancer", date_range = c("2020", "2024"))
  expect_true(grepl("2020:2024\\[DP\\]", q))
})

test_that("pmQueryBuild handles MeSH terms", {
  q <- pmQueryBuild(mesh_terms = "COVID-19")
  expect_true(grepl("COVID-19\\[MeSH Terms\\]", q))
})

test_that("pmQueryBuild handles author", {
  q <- pmQueryBuild(terms = "bibliometrics", author = "Aria M")
  expect_true(grepl("Aria M\\[Author\\]", q))
})

test_that("pmQueryBuild handles journal filter", {
  q <- pmQueryBuild(terms = "cancer", journal = "Nature")
  expect_true(grepl("Nature\\[Journal\\]", q))
})

test_that("pmQueryBuild handles publication type", {
  q <- pmQueryBuild(terms = "cancer", pub_type = "Review")
  expect_true(grepl("Review\\[PT\\]", q))
})

test_that("pmQueryBuild combines all parameters", {
  q <- pmQueryBuild(
    terms = "bibliometrics",
    language = "english",
    pub_type = "Journal Article",
    date_range = c("2000", "2023"),
    author = "Aria M"
  )
  expect_true(grepl("bibliometrics\\[Title/Abstract\\]", q))
  expect_true(grepl("english\\[LA\\]", q))
  expect_true(grepl("Journal Article\\[PT\\]", q))
  expect_true(grepl("2000:2023\\[DP\\]", q))
  expect_true(grepl("Aria M\\[Author\\]", q))
})

test_that("pmQueryBuild errors with no parameters", {
  expect_error(pmQueryBuild(), "At least one search parameter")
})

test_that("pmQueryBuild handles multiple fields", {
  q <- pmQueryBuild(terms = "cancer", fields = c("Title", "Abstract"))
  expect_true(grepl("Title", q))
  expect_true(grepl("Abstract", q))
})
