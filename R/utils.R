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


#' Extract fields from a PubmedBookArticle flattened record
#'
#' Maps the \code{BookDocument.*} / \code{PubmedBookData.*} XML structure
#' (used by GeneReviews, StatPearls, etc.) onto the same data frame columns
#' produced for \code{PubmedArticle} records.
#'
#' @param a A named character vector from \code{list2char}.
#' @param items \code{names(a)}.
#' @return A named list of column values for a single row.
#' @noRd
extract_book_article <- function(a, items) {
  row <- list()

  ## Language
  row$LA <- a["BookDocument.Language"]

  ## Document Type
  dt <- a["BookDocument.PublicationType.text"]
  if (is.na(dt)) dt <- "BOOK CHAPTER"
  row$DT <- dt

  ## Title (chapter)
  ti <- a["BookDocument.ArticleTitle.text"]
  if (is.na(ti)) ti <- a["BookDocument.ArticleTitle"]
  row$TI <- ti

  ## Publication Year: History first, then ContributionDate, then Book.PubDate
  ind <- which(items == "PubmedBookData.History.PubMedPubDate.Year")
  if (length(ind) > 0) {
    row$PY <- suppressWarnings(min(as.numeric(a[ind]), na.rm = TRUE))
  } else {
    py <- a["BookDocument.ContributionDate.Year"]
    if (is.na(py)) py <- a["BookDocument.Book.PubDate.Year"]
    if (!is.na(py)) row$PY <- as.numeric(py)
  }
  row$PY_IS <- a["BookDocument.Book.PubDate.Year"]

  ## Authors of the chapter (NOT the Book's editors under Book.AuthorList)
  AU_last_ind <- which(items == "BookDocument.AuthorList.Author.LastName")
  AU_first_ind <- which(items == "BookDocument.AuthorList.Author.ForeName")
  AU_init_ind <- which(items == "BookDocument.AuthorList.Author.Initials")
  if (length(AU_last_ind) > 0) {
    nameAF <- paste(a[AU_last_ind], a[AU_first_ind], sep = ", ")
    nameAU <- paste(a[AU_last_ind], a[AU_init_ind], sep = " ")
    row$AF <- paste(nameAF, collapse = ";")
    row$AU <- paste(nameAU, collapse = ";")
  }

  ## Affiliations
  Aff_name_ind <- which(
    items == "BookDocument.AuthorList.Author.AffiliationInfo.Affiliation"
  )
  if (length(Aff_name_ind) > 0) {
    Affiliations <- a[Aff_name_ind]
    Affiliations <- vapply(
      Affiliations,
      function(l) {
        parts <- unlist(strsplit(l, ", "))
        paste(parts[!grepl("@", parts, fixed = TRUE)], collapse = ", ")
      },
      character(1),
      USE.NAMES = FALSE
    )
    Affiliations <- Affiliations[nzchar(trimws(Affiliations))]
    unique_aff <- unique(Affiliations)
    row$C1 <- paste(unique_aff, collapse = ";")
    row$AU_UN <- row$C1
  }

  ## Keywords
  DE_ind <- which(items == "BookDocument.KeywordList.Keyword.text")
  if (length(DE_ind) > 0) {
    row$DE <- paste(a[DE_ind], collapse = ";")
  }

  ## Abstract
  ind <- which(items == "BookDocument.Abstract.AbstractText.text")
  if (length(ind) > 0) {
    row$AB <- paste(a[ind], collapse = " ")
  } else {
    ind <- which(items == "BookDocument.Abstract.AbstractText")
    if (length(ind) > 0) {
      row$AB <- paste(a[ind], collapse = " ")
    }
  }

  ## Source = Book title
  book_title <- a["BookDocument.Book.BookTitle.text"]
  if (is.na(book_title)) book_title <- a["BookDocument.Book.BookTitle"]
  row$SO <- book_title
  row$JI <- book_title
  row$J9 <- book_title

  ## Country / publisher location
  row$SO_CO <- a["BookDocument.Book.Publisher.PublisherLocation"]

  ## DOI (usually absent on book chapters but possible)
  doi_ind <- which(
    items == "PubmedBookData.ArticleIdList.ArticleId..attrs.IdType"
  )
  ind <- which(a[doi_ind] == "doi")
  if (length(ind) > 0) {
    doi_val_ind <- doi_ind[ind] - 1
    row$DI <- a[doi_val_ind]
  }

  ## PMID
  row$UT <- row$PMID <- a["BookDocument.PMID.text"]

  ## Grants
  GR_ID <- which(items == "BookDocument.GrantList.Grant.GrantID")
  if (length(GR_ID) > 0) {
    row$GRANT_ID <- paste(a[GR_ID], collapse = ";")
  }
  GR_ORG <- which(items == "BookDocument.GrantList.Grant.Agency")
  if (length(GR_ORG) > 0) {
    row$GRANT_ORG <- paste(a[GR_ORG], collapse = ";")
  }

  row
}


#' Null-coalescing operator
#' @noRd
`%||%` <- function(a, b) if (is.null(a)) b else a


#' Extract the source PMID from a parsed XML record
#'
#' Handles both \code{PubmedArticle} and \code{PubmedBookArticle} structures.
#'
#' @param rec A single record from \code{pmApiRequest()$data} or
#'   \code{pmFetchById()$data}.
#' @return A character PMID, or \code{NA_character_} if not found.
#' @noRd
extract_record_pmid <- function(rec) {
  pm <- rec$MedlineCitation$PMID
  if (is.null(pm)) pm <- rec$BookDocument$PMID
  if (is.null(pm)) return(NA_character_)
  if (is.list(pm)) pm <- pm$text %||% pm[[1]]
  pm <- as.character(pm)
  if (length(pm) == 0 || !nzchar(pm)) NA_character_ else pm[1]
}


#' Extract references from a parsed XML record
#'
#' Walks \code{PubmedData$ReferenceList} (or \code{PubmedBookData$ReferenceList})
#' and returns one row per cited \code{<Reference>}. Each row carries the
#' free-text citation plus PMID / DOI parsed from any \code{<ArticleIdList>}.
#'
#' @param rec A single record from \code{pmApiRequest()$data} or
#'   \code{pmFetchById()$data}.
#' @return A data.frame with columns \code{citation}, \code{pmid}, \code{doi}.
#' @noRd
extract_refs_from_record <- function(rec) {
  refs <- rec$PubmedData$ReferenceList
  if (is.null(refs)) refs <- rec$PubmedBookData$ReferenceList
  if (is.null(refs) || length(refs) == 0) return(empty_refs_df())

  out <- vector("list", length(refs))
  k <- 0L
  for (j in seq_along(refs)) {
    if (!identical(names(refs)[j], "Reference")) next
    r <- refs[[j]]

    citation <- r$Citation
    if (is.list(citation)) citation <- citation$text %||% paste(unlist(citation), collapse = " ")
    citation <- if (is.null(citation)) NA_character_ else as.character(citation)

    pmid <- NA_character_
    doi <- NA_character_
    aid_list <- r$ArticleIdList
    if (!is.null(aid_list)) {
      for (m in seq_along(aid_list)) {
        if (!identical(names(aid_list)[m], "ArticleId")) next
        ai <- aid_list[[m]]
        if (is.list(ai)) {
          id_val  <- ai$text %||% ai[[1]]
          id_type <- if (!is.null(ai$.attrs)) ai$.attrs[["IdType"]] else NULL
        } else {
          id_val  <- as.character(ai)
          id_type <- attr(ai, "IdType")
        }
        if (is.null(id_type) || is.null(id_val)) next
        if (identical(id_type, "pubmed") && is.na(pmid)) pmid <- as.character(id_val)
        if (identical(id_type, "doi")    && is.na(doi))  doi  <- as.character(id_val)
      }
    }

    k <- k + 1L
    out[[k]] <- data.frame(
      citation = citation,
      pmid = pmid,
      doi = doi,
      stringsAsFactors = FALSE
    )
  }
  if (k == 0L) return(empty_refs_df())
  do.call(rbind, out[seq_len(k)])
}


#' Empty references data.frame schema
#' @noRd
empty_refs_df <- function() {
  data.frame(
    citation = character(0),
    pmid = character(0),
    doi = character(0),
    stringsAsFactors = FALSE
  )
}


#' Build a WoS-style CR string from a \code{pmApi2df} row
#'
#' Produces "AUTHOR YYYY, JOURNAL ABBREV, V##, P##, DOI ..." as understood by
#' downstream bibliometrix functions.
#'
#' @param row A list (or one-row data.frame coerced to list) with at least the
#'   AU/PY/J9/JI/VL/PG/DI columns produced by \code{pmApi2df}.
#' @return Character WoS-style citation, or \code{NA_character_} when nothing
#'   meaningful can be derived.
#' @noRd
build_wos_cr_string <- function(row) {
  parts <- character(0)

  AU <- row$AU
  if (!is.null(AU) && !is.na(AU) && nzchar(AU)) {
    first_au <- trimws(strsplit(AU, ";", fixed = TRUE)[[1]][1])
    if (length(first_au) && !is.na(first_au) && nzchar(first_au)) {
      parts <- c(parts, toupper(first_au))
    }
  }

  PY <- row$PY
  if (!is.null(PY) && !is.na(PY) && nzchar(as.character(PY))) {
    parts <- c(parts, as.character(PY))
  }

  src <- row$J9
  if (is.null(src) || is.na(src) || !nzchar(src)) src <- row$JI
  if (is.null(src) || is.na(src) || !nzchar(src)) src <- row$SO
  if (!is.null(src) && !is.na(src) && nzchar(src)) parts <- c(parts, toupper(src))

  VL <- row$VL
  if (!is.null(VL) && !is.na(VL) && nzchar(VL)) parts <- c(parts, paste0("V", VL))

  PG <- row$PG
  if (!is.null(PG) && !is.na(PG) && nzchar(PG)) {
    fp <- trimws(strsplit(PG, "-", fixed = TRUE)[[1]][1])
    if (length(fp) && !is.na(fp) && nzchar(fp)) parts <- c(parts, paste0("P", fp))
  }

  DI <- row$DI
  if (!is.null(DI) && !is.na(DI) && nzchar(DI)) {
    doi_clean <- gsub("^https?://doi\\.org/", "", DI)
    parts <- c(parts, paste0("DOI ", toupper(doi_clean)))
  }

  if (length(parts) == 0) return(NA_character_)
  paste(parts, collapse = ", ")
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
