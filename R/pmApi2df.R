#' Convert xml PubMed bibliographic data into a dataframe
#'
#' It converts PubMed data, downloaded using Entrez API, into a dataframe
#'
#' @param P is a list following the xml PubMed structure, downloaded using the function \code{pmApiRequest}.
#' @param format is a character. If \code{format = "bibliometrix"} data will be converted in the bibliometrix compatible data format.
#' If \code{format = "raw"} data will save in a data frame without any other data editing procedure.
#'
#' @return a dataframe containing bibliographic records.
#'
#' To obtain a free access to NCBI API, please visit: \href{https://pmc.ncbi.nlm.nih.gov/tools/developers/}{https://pmc.ncbi.nlm.nih.gov/tools/developers/}
#'
#' To obtain more information about how to write a NCBI search query, please visit: \href{https://pubmed.ncbi.nlm.nih.gov/help/#search-tags}{https://pubmed.ncbi.nlm.nih.gov/help/#search-tags}
#'
#' @examplesIf interactive()
#' # Example: Querying a collection of publications
#'
#' query <- "bibliometric*[Title/Abstract] AND english[LA]
#'          AND Journal Article[PT] AND 2000:2020[DP]"
#' D <- pmApiRequest(query = query, limit = 100, api_key = NULL)
#' M <- pmApi2df(D)
#'
#' @seealso \code{\link{pmApiRequest}}
#' @seealso \code{\link{pmQueryTotalCount}}
#'
#' @export
pmApi2df <- function(P, format = "bibliometrix") {
  format <- match.arg(format, c("bibliometrix", "raw"))
  P <- P$data

  n <- length(P)

  if (n == 0) {
    message("No records to convert.")
    return(data.frame())
  }

  ### Data Conversion
  df <- data.frame(
    AU = rep(NA_character_, n),
    AF = NA_character_,
    TI = NA_character_,
    SO = NA_character_,
    SO_CO = NA_character_,
    LA = NA_character_,
    DT = NA_character_,
    PT = NA_character_,
    DE = NA_character_,
    ID = NA_character_,
    MESH = NA_character_,
    AB = NA_character_,
    C1 = NA_character_,
    CR = NA_character_,
    TC = 0,
    SN = NA_character_,
    J9 = NA_character_,
    JI = NA_character_,
    PY = NA_integer_,
    PY_IS = NA_character_,
    VL = NA_character_,
    IS = NA_character_,
    DI = NA_character_,
    PG = NA_character_,
    GRANT_ID = NA_character_,
    GRANT_ORG = NA_character_,
    UT = NA_character_,
    PMID = NA_character_,
    PMCID = NA_character_,
    DB = "PUBMED",
    AU_UN = NA_character_,
    stringsAsFactors = FALSE
  )

  pb <- utils::txtProgressBar(
    min = 0,
    max = n,
    initial = 0,
    char = "=",
    style = 3
  )

  record_types <- names(P)
  if (is.null(record_types)) record_types <- rep(NA_character_, n)

  for (i in 1:n) {
    utils::setTxtProgressBar(pb, i)

    rec <- P[[i]]
    a <- list2char(rec)
    items <- names(a)

    ## Dispatch on record type: book chapters use a different XML structure
    if (identical(record_types[i], "PubmedBookArticle")) {
      row <- extract_book_article(a, items, rec)
      for (col in names(row)) df[[col]][i] <- row[[col]]
      next
    }

    ## Language
    df$LA[i] <- a["MedlineCitation.Article.Language"]

    ## Document Type
    df$DT[i] <- a[
      "MedlineCitation.Article.PublicationTypeList.PublicationType.text"
    ]

    ## All the publication types: DT holds only the first, usually "Journal
    ## Article" even for a review
    PT_ind <- which(
      items == "MedlineCitation.Article.PublicationTypeList.PublicationType.text"
    )
    if (length(PT_ind) > 0) {
      df$PT[i] <- paste(a[PT_ind], collapse = ";")
    }

    ## Title
    article <- rec$MedlineCitation$Article
    df$TI[i] <- node_text(article$ArticleTitle)

    ## Publication Year: the journal issue. Its date is sometimes free text
    ## ("1998 Dec-1999 Jan"), and only without one the record's history, whose
    ## earliest date (entered, received, ...) often precedes the publication.
    df$PY_IS[i] <- a[
      "MedlineCitation.Article.Journal.JournalIssue.PubDate.Year"
    ]
    py <- df$PY_IS[i]
    if (is.na(py)) {
      py <- substr(
        a["MedlineCitation.Article.Journal.JournalIssue.PubDate.MedlineDate"],
        1,
        4
      )
    }
    py <- suppressWarnings(as.numeric(py))
    if (is.na(py)) {
      ind <- which(items == "PubmedData.History.PubMedPubDate.Year")
      if (length(ind) > 0) py <- min(as.numeric(a[ind]), na.rm = TRUE)
    }
    df$PY[i] <- py

    ## Authors and affiliations
    authors <- parse_authors(article$AuthorList)
    df$AU[i] <- authors$AU
    df$AF[i] <- authors$AF
    df$C1[i] <- df$AU_UN[i] <- authors$C1

    ## Keywords and MeSH
    df$DE[i] <- collapse_nodes(
      unlist(
        lapply(
          rec$MedlineCitation[names(rec$MedlineCitation) == "KeywordList"],
          function(k) k[names(k) == "Keyword"]
        ),
        recursive = FALSE
      ),
      ";"
    )

    ID_ind <- which(
      items == "MedlineCitation.MeshHeadingList.MeshHeading.DescriptorName.text"
    )
    if (length(ID_ind) > 0) {
      df$ID[i] <- df$MESH[i] <- paste(a[ID_ind], collapse = ";")
    }

    ## Abstract: every section of a structured one, with its inline tags
    df$AB[i] <- collapse_nodes(
      article$Abstract[names(article$Abstract) == "AbstractText"],
      " "
    )

    ## Journal
    df$SO[i] <- a["MedlineCitation.Article.Journal.Title"]
    df$JI[i] <- df$J9[i] <- a["MedlineCitation.Article.Journal.ISOAbbreviation"]
    df$SO_CO[i] <- a["MedlineCitation.MedlineJournalInfo.Country"]

    ## DOI
    doi_ind <- which(
      items == "PubmedData.ArticleIdList.ArticleId..attrs.IdType"
    )
    ind <- which(a[doi_ind] == "doi")
    if (length(ind) > 0) {
      doi_val_ind <- doi_ind[ind] - 1
      df$DI[i] <- a[doi_val_ind]
    }

    ## PubMed Central identifier
    pmc_val <- which(a[doi_ind] == "pmc")
    if (length(pmc_val) > 0) {
      df$PMCID[i] <- a[doi_ind[pmc_val[1]] - 1]
    }

    ## ISSN
    df$SN[i] <- a["MedlineCitation.Article.Journal.ISSN.text"]

    ## Pages
    df$PG[i] <- a["MedlineCitation.Article.Pagination.MedlinePgn"]

    ## Volume
    df$VL[i] <- a["MedlineCitation.Article.Journal.JournalIssue.Volume"]

    ## Issue
    df$IS[i] <- a["MedlineCitation.Article.Journal.JournalIssue.Issue"]

    ## PMID
    df$UT[i] <- df$PMID[i] <- a["MedlineCitation.PMID.text"]

    ## Grants
    GR_ID <- which(items == "MedlineCitation.Article.GrantList.Grant.GrantID")
    if (length(GR_ID) > 0) {
      df$GRANT_ID[i] <- paste(a[GR_ID], collapse = ";")
    }
    GR_ORG <- which(items == "MedlineCitation.Article.GrantList.Grant.Agency")
    if (length(GR_ORG) > 0) {
      df$GRANT_ORG[i] <- paste(a[GR_ORG], collapse = ";")
    }
  }

  close(pb)

  if (format == "bibliometrix") {
    DI <- df$DI
    df <- data.frame(lapply(df, toupper), stringsAsFactors = FALSE)
    df$DI <- DI
    df$AU_CO <- NA_character_
    df$AU1_CO <- NA_character_
  }

  ### PY
  df$PY <- as.numeric(df$PY)

  ### TC
  df$TC <- as.numeric(df$TC)
  df$TC[is.na(df$TC)] <- 0

  ### Remove empty rows (no Document Type) and report them
  missing_idx <- which(is.na(df$DT))
  if (length(missing_idx) > 0) {
    dropped_pmids <- df$PMID[missing_idx]
    dropped_pmids <- dropped_pmids[!is.na(dropped_pmids) & nzchar(dropped_pmids)]
    if (length(dropped_pmids) > 0) {
      message(sprintf(
        "Dropped %d record(s) with no Document Type. PMID: %s",
        length(missing_idx),
        paste(dropped_pmids, collapse = ", ")
      ))
    } else {
      message(sprintf(
        "Dropped %d record(s) with no Document Type (PMID not extractable).",
        length(missing_idx)
      ))
    }
    df <- df[-missing_idx, ]
  }

  return(df)
}
