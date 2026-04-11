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
#' To obtain a free access to NCBI API, please visit: \href{https://www.ncbi.nlm.nih.gov/pmc/tools/developers/}{https://www.ncbi.nlm.nih.gov/pmc/tools/developers/}
#'
#' To obtain more information about how to write a NCBI search query, please visit: \href{https://pubmed.ncbi.nlm.nih.gov/help/#search-tags}{https://pubmed.ncbi.nlm.nih.gov/help/#search-tags}
#'
#' @examples
#'
#' # Example: Querying a collection of publications
#'
#' \donttest{
#' query <- "bibliometric*[Title/Abstract] AND english[LA]
#'          AND Journal Article[PT] AND 2000:2020[DP]"
#' D <- pmApiRequest(query = query, limit = 100, api_key = NULL)
#' M <- pmApi2df(D)
#' }
#'
#' @seealso \code{\link{pmApiRequest}}
#' @seealso \code{\link{pmQueryTotalCount}}
#'
#' @export
pmApi2df <- function(P, format = "bibliometrix") {

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
    DI = NA_character_,
    PG = NA_character_,
    GRANT_ID = NA_character_,
    GRANT_ORG = NA_character_,
    UT = NA_character_,
    PMID = NA_character_,
    DB = "PUBMED",
    AU_UN = NA_character_,
    stringsAsFactors = FALSE
  )

  pb <- utils::txtProgressBar(min = 1, max = n, initial = 1, char = "=", style = 3)

  for (i in 1:n) {
    utils::setTxtProgressBar(pb, i)

    a <- list2char(P[[i]])
    items <- names(a)

    ## Language
    df$LA[i] <- a["MedlineCitation.Article.Language"]

    ## Document Type
    df$DT[i] <- a["MedlineCitation.Article.PublicationTypeList.PublicationType.text"]

    ## Title
    df$TI[i] <- a["MedlineCitation.Article.ArticleTitle"]

    ## Publication Year
    ind <- which(items == "PubmedData.History.PubMedPubDate.Year")
    if (length(ind) > 0) {
      df$PY[i] <- min(as.numeric(a[ind]), na.rm = TRUE)
    }
    df$PY_IS[i] <- a["MedlineCitation.Article.Journal.JournalIssue.PubDate.Year"]

    ## Authors
    AU_last_ind <- which(items == "MedlineCitation.Article.AuthorList.Author.LastName")
    AU_first_ind <- which(items == "MedlineCitation.Article.AuthorList.Author.ForeName")
    AU_init_ind <- which(items == "MedlineCitation.Article.AuthorList.Author.Initials")

    if (length(AU_last_ind) > 0) {
      nameAF <- paste(a[AU_last_ind], a[AU_first_ind], sep = ", ")
      nameAU <- paste(a[AU_last_ind], a[AU_init_ind], sep = " ")
      df$AF[i] <- paste(nameAF, collapse = ";")
      df$AU[i] <- paste(nameAU, collapse = ";")
    }

    ## Affiliations - extract all author affiliations
    Aff_name_ind <- which(items == "MedlineCitation.Article.AuthorList.Author.AffiliationInfo.Affiliation")
    if (length(Aff_name_ind) > 0) {
      Affiliations <- a[Aff_name_ind]

      ## Remove email addresses from affiliations
      Affiliations <- vapply(Affiliations, function(l) {
        parts <- unlist(strsplit(l, ", "))
        paste(parts[!grepl("@", parts, fixed = TRUE)], collapse = ", ")
      }, character(1), USE.NAMES = FALSE)

      ## Remove empty affiliations
      Affiliations <- Affiliations[nzchar(trimws(Affiliations))]

      ## Unique affiliations for C1
      unique_aff <- unique(Affiliations)
      df$C1[i] <- paste(unique_aff, collapse = ";")
      df$AU_UN[i] <- df$C1[i]
    }

    ## Keywords and MeSH
    DE_ind <- which(items == "MedlineCitation.KeywordList.Keyword.text")
    if (length(DE_ind) > 0) {
      df$DE[i] <- paste(a[DE_ind], collapse = ";")
    }

    ID_ind <- which(items == "MedlineCitation.MeshHeadingList.MeshHeading.DescriptorName.text")
    if (length(ID_ind) > 0) {
      df$ID[i] <- df$MESH[i] <- paste(a[ID_ind], collapse = ";")
    }

    ## Abstract - handle structured abstracts
    ind <- which(items == "MedlineCitation.Article.Abstract.AbstractText.text")
    if (length(ind) > 0) {
      df$AB[i] <- paste(a[ind], collapse = " ")
    } else {
      ind <- which(items == "MedlineCitation.Article.Abstract.AbstractText")
      if (length(ind) > 0) {
        df$AB[i] <- paste(a[ind], collapse = " ")
      }
    }

    ## Journal
    df$SO[i] <- a["MedlineCitation.Article.Journal.Title"]
    df$JI[i] <- df$J9[i] <- a["MedlineCitation.Article.Journal.ISOAbbreviation"]
    df$SO_CO[i] <- a["MedlineCitation.MedlineJournalInfo.Country"]

    ## DOI
    doi_ind <- which(items == "PubmedData.ArticleIdList.ArticleId..attrs.IdType")
    ind <- which(a[doi_ind] == "doi")
    if (length(ind) > 0) {
      doi_val_ind <- doi_ind[ind] - 1
      df$DI[i] <- a[doi_val_ind]
    }

    ## ISSN
    df$SN[i] <- a["MedlineCitation.Article.Journal.ISSN.text"]

    ## Pages
    df$PG[i] <- a["MedlineCitation.Article.Pagination.MedlinePgn"]

    ## Volume
    df$VL[i] <- a["MedlineCitation.Article.Journal.JournalIssue.Volume"]

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

  ### Remove empty rows (no Document Type)
  df <- df[!is.na(df$DT), ]

  return(df)
}
