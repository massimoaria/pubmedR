test_that("pmApi2df handles empty data", {
  P <- list(data = list())
  result <- pmApi2df(P)
  expect_true(is.data.frame(result))
  expect_equal(nrow(result), 0)
})

test_that("pmApi2df output has expected columns in bibliometrix format", {
  skip_on_cran()
  skip_if_offline()
  skip_if_not(
    nzchar(Sys.getenv("PUBMED_API_KEY")) || nzchar(Sys.getenv("ENTREZ_KEY")),
    "no PubMed API key set"
  )

  D <- pmApiRequest(
    query = "bibliometric*[Title/Abstract] AND english[LA] AND 2020:2020[DP]",
    limit = 5,
    api_key = NULL
  )
  M <- pmApi2df(D, format = "bibliometrix")

  expected_cols <- c("AU", "AF", "TI", "SO", "LA", "DT", "DE", "ID",
                     "AB", "C1", "CR", "TC", "SN", "J9", "JI", "PY",
                     "VL", "DI", "PG", "UT", "PMID", "DB", "AU_UN",
                     "AU_CO", "AU1_CO")
  for (col in expected_cols) {
    expect_true(col %in% names(M), info = paste("Missing column:", col))
  }
  expect_true(nrow(M) > 0)
  expect_equal(unique(M$DB), "PUBMED")
})

test_that("pmApi2df raw format does not add AU_CO columns", {
  skip_on_cran()
  skip_if_offline()
  skip_if_not(
    nzchar(Sys.getenv("PUBMED_API_KEY")) || nzchar(Sys.getenv("ENTREZ_KEY")),
    "no PubMed API key set"
  )

  D <- pmApiRequest(
    query = "bibliometric*[Title/Abstract] AND english[LA] AND 2020:2020[DP]",
    limit = 3,
    api_key = NULL
  )
  M <- pmApi2df(D, format = "raw")

  expect_false("AU_CO" %in% names(M))
  expect_false("AU1_CO" %in% names(M))
})

pm_year_record <- function(pubdate) {
  xml <- paste0(
    "<PubmedArticleSet><PubmedArticle><MedlineCitation><PMID Version=\"1\">1</PMID><Article>",
    "<Journal><JournalIssue>", pubdate, "</JournalIssue><Title>J</Title></Journal>",
    "<ArticleTitle>T</ArticleTitle><PublicationTypeList><PublicationType UI=\"D016428\">Journal Article</PublicationType></PublicationTypeList>",
    "<AuthorList><Author><LastName>Silver</LastName><ForeName>F H</ForeName><Initials>FH</Initials></Author></AuthorList>",
    "</Article></MedlineCitation><PubmedData><History>",
    "<PubMedPubDate PubStatus='entrez'><Year>1990</Year><Month>12</Month><Day>10</Day></PubMedPubDate>",
    "</History></PubmedData></PubmedArticle></PubmedArticleSet>"
  )
  list(data = XML::xmlToList(XML::xmlParse(xml, asText = TRUE), simplify = FALSE))
}

test_that("PY is the year of the journal issue, not of the record's history", {
  quiet <- function(x) { utils::capture.output(r <- pmApi2df(x)); r }
  expect_equal(quiet(pm_year_record("<PubDate><Year>1991</Year></PubDate>"))$PY, 1991)
  expect_equal(
    quiet(pm_year_record("<PubDate><MedlineDate>1998 Dec-1999 Jan</MedlineDate></PubDate>"))$PY,
    1998
  )
  expect_equal(quiet(pm_year_record(""))$PY, 1990)
})
