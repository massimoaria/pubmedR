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

  D <- ncbi_or_skip(pmApiRequest(
    query = "bibliometric*[Title/Abstract] AND english[LA] AND 2020:2020[DP]",
    limit = 5,
    api_key = NULL
  ))
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

  D <- ncbi_or_skip(pmApiRequest(
    query = "bibliometric*[Title/Abstract] AND english[LA] AND 2020:2020[DP]",
    limit = 3,
    api_key = NULL
  ))
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

# ----- Real records (tests/testthat/fixtures/records.xml) ----------------------

fixture_df <- function(format = "bibliometrix") {
  doc <- XML::xmlParse(test_path("fixtures", "records.xml"))
  P <- list(data = pubmedR:::parse_batch(doc))
  utils::capture.output(M <- pmApi2df(P, format = format))
  M[match(c("10171110", "36648155", "40330265", "40841021", "42038533", "2278147",
            "40973412", "42777106", "40383892"), M$PMID), ]
}

test_that("a title or a keyword with inline tags is read in full", {
  M <- fixture_df()
  expect_false(anyNA(M$TI))
  expect_match(M$TI[M$PMID == "40841021"], "URBAN PM2.5 AND O3: A CASE STUDY", fixed = TRUE)
  expect_match(M$DE[M$PMID == "40383892"], "ELEVATED ATMOSPHERIC CO2 CONCENTRATION", fixed = TRUE)
})

test_that("an abstract with inline tags keeps the tagged words", {
  M <- fixture_df()
  expect_match(M$AB[M$PMID == "42038533"], "(N = 3 IMAGES)|N = 3 IMAGES")
})

test_that("an author with no fore name does not shift the following ones", {
  M <- fixture_df("raw")
  af <- strsplit(M$AF[M$PMID == "36648155"], ";")[[1]]
  au <- strsplit(M$AU[M$PMID == "36648155"], ";")[[1]]
  expect_true("Abhishek" %in% af)
  expect_true("Abhishek" %in% au)
  expect_true("Vinodh Kumar, Obli Rajendhran" %in% af)
  expect_true("Vinodh Kumar OR" %in% au)
})

test_that("a collective author stays in its place", {
  M <- fixture_df()
  au <- strsplit(M$AU[M$PMID == "40330265"], ";")[[1]]
  expect_equal(
    au,
    c("JAKI T", "CHANG C", "KUHLEMEIER A",
      "POOLED RESOURCE OPEN-ACCESS ALS CLINICAL TRIALS CONSORTIUM", "VAN HORN ML")
  )
})

test_that("an e-mail address leaves the affiliation, and the country stays", {
  M <- fixture_df()
  c1 <- M$C1[M$PMID == "40973412"]
  expect_false(grepl("@", c1, fixed = TRUE))
  expect_false(grepl("ELECTRONIC ADDRESS", c1, fixed = TRUE))
  expect_match(c1, "P.R. CHINA", fixed = TRUE)
  expect_equal(
    pubmedR:::clean_affiliation(c(
      "Dept, Pavia, Italy. Electronic address: m.rossi@unipv.it.",
      "Univ of Padua, Italy. silvia@univr.it",
      "Hospital, Rome, Italy (a.b@c.it)",
      "Dept X, Boston, MA, USA; email: q@w.edu",
      "No address, Italy.",
      "E-mail: x@y.org"
    )),
    c("Dept, Pavia, Italy.", "Univ of Padua, Italy.", "Hospital, Rome, Italy",
      "Dept X, Boston, MA, USA", "No address, Italy.", "")
  )
})

test_that("the columns bibliometrix reads are all there, plus PT and PMCID", {
  M <- fixture_df()
  expect_true(all(c(
    "AU", "AF", "TI", "SO", "SO_CO", "LA", "DT", "DE", "ID", "MESH", "AB", "C1", "CR",
    "TC", "SN", "J9", "JI", "PY", "PY_IS", "VL", "IS", "DI", "PG", "GRANT_ID",
    "GRANT_ORG", "UT", "PMID", "DB", "AU_UN", "AU_CO", "AU1_CO", "PT", "PMCID"
  ) %in% names(M)))
  silver <- M[M$PMID == "10171110", ]
  expect_equal(silver$PY, 1991)
  expect_equal(silver$DT, "JOURNAL ARTICLE")
  expect_match(silver$PT, "REVIEW", fixed = TRUE)
})

test_that("a free-text issue date gives the year, and a book record is read", {
  M <- fixture_df()
  expect_equal(M$PY[M$PMID == "2278147"], 1990)
  book <- M[M$PMID == "42777106", ]
  expect_equal(book$PY, 2026)
  expect_false(is.na(book$TI))
  expect_false(is.na(book$SO))
})

test_that("an invalid format is an error", {
  expect_error(pmApi2df(list(data = list()), format = "nope"))
})

test_that("PY is the year of the journal issue, not of the record's history", {
  quiet <- function(x) { utils::capture.output(r <- pmApi2df(x)); r }
  expect_equal(quiet(pm_year_record("<PubDate><Year>1991</Year></PubDate>"))$PY, 1991)
  expect_equal(
    quiet(pm_year_record("<PubDate><MedlineDate>1998 Dec-1999 Jan</MedlineDate></PubDate>"))$PY,
    1998
  )
  expect_equal(quiet(pm_year_record(""))$PY, 1990)
})
