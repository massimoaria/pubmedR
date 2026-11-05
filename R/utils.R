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
#' @param rec The parsed record that \code{a} comes from.
#' @return A named list of column values for a single row.
#' @noRd
extract_book_article <- function(a, items, rec) {
  row <- list()

  ## Language
  row$LA <- a["BookDocument.Language"]

  ## Document Type
  dt <- a["BookDocument.PublicationType.text"]
  if (is.na(dt)) dt <- "BOOK CHAPTER"
  row$DT <- dt

  ## Title (chapter)
  row$TI <- node_text(rec$BookDocument$ArticleTitle)

  ## Publication Year: Book.PubDate, then ContributionDate, then History
  py <- a["BookDocument.Book.PubDate.Year"]
  if (is.na(py)) py <- a["BookDocument.ContributionDate.Year"]
  if (!is.na(py)) {
    row$PY <- as.numeric(py)
  } else {
    ind <- which(items == "PubmedBookData.History.PubMedPubDate.Year")
    if (length(ind) > 0) {
      row$PY <- suppressWarnings(min(as.numeric(a[ind]), na.rm = TRUE))
    }
  }
  row$PY_IS <- a["BookDocument.Book.PubDate.Year"]

  ## Authors of the chapter (NOT the Book's editors under Book.AuthorList)
  authors <- parse_authors(rec$BookDocument$AuthorList)
  row$AU <- authors$AU
  row$AF <- authors$AF
  row$C1 <- row$AU_UN <- authors$C1

  ## Keywords
  DE_ind <- which(items == "BookDocument.KeywordList.Keyword.text")
  if (length(DE_ind) > 0) {
    row$DE <- paste(a[DE_ind], collapse = ";")
  }

  ## Abstract
  abstract <- rec$BookDocument$Abstract
  row$AB <- collapse_nodes(abstract[names(abstract) == "AbstractText"], " ")

  ## Source = Book title
  book_title <- node_text(rec$BookDocument$Book$BookTitle)
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


#' The text of a parsed XML element
#'
#' An element holding inline tags ("PM<sub>2.5</sub> levels") reaches R as a list
#' of pieces, and only a plain element as a string. Put the pieces back in order,
#' leaving out the attributes.
#'
#' @param x An element from \code{xmlToList()}, or \code{NULL}.
#' @return A string, or \code{NA_character_} if the element is missing or empty.
#' @noRd
node_text <- function(x) {
  if (is.null(x)) return(NA_character_)
  if (is.list(x)) {
    if (!is.null(names(x))) x <- x[names(x) != ".attrs"]
    x <- vapply(x, function(piece) {
      if (is.list(piece)) node_text(piece) else paste(piece, collapse = "")
    }, character(1))
    x <- paste(x[!is.na(x)], collapse = "")
  }
  x <- trimws(paste(x, collapse = ""))
  if (nzchar(x)) x else NA_character_
}


#' The text of several XML elements in one string
#' @param nodes A list of elements, or \code{NULL}.
#' @param sep The separator.
#' @return A string, or \code{NA_character_} if there is no text.
#' @noRd
collapse_nodes <- function(nodes, sep) {
  if (length(nodes) == 0) return(NA_character_)
  x <- vapply(nodes, node_text, character(1), USE.NAMES = FALSE)
  x <- x[!is.na(x)]
  if (length(x) == 0) NA_character_ else paste(x, collapse = sep)
}


#' Remove an e-mail address from an affiliation
#'
#' PubMed appends the address to the affiliation ("Pavia, Italy. Electronic
#' address: m.rossi@unipv.it."), so everything else in that piece, the country
#' above all, must stay.
#'
#' @param x A character vector of affiliations.
#' @return The affiliations without addresses or the trailing punctuation.
#' @noRd
clean_affiliation <- function(x) {
  label <- "(electronic address|e-?mail(\\s+address)?|email|correspondence)"
  x <- gsub(
    paste0("(?i)\\b", label, "\\s*:?\\s*(?=[^\\s,;]+@)"),
    "",
    x,
    perl = TRUE
  )
  x <- gsub("[^\\s,;()]+@[^\\s,;()]+", "", x, perl = TRUE)
  x <- gsub("\\(\\s*\\)", "", x)
  x <- gsub("\\s+([,.;])", "\\1", gsub("\\s+", " ", x))
  x <- gsub("[,.;]+\\s*[,.;]+", ".", x)
  trimws(gsub("[,;:\\s]+$", "", trimws(x), perl = TRUE))
}


#' Read the author list of a record
#'
#' Each author is read as a whole: a name lacking its fore name or initials, as a
#' single-name author or a collective author does, must not shift the following
#' ones. Collective authors are kept, in their place in the list.
#'
#' @param author_list The \code{AuthorList} element of a parsed record.
#' @return A list with the strings \code{AU}, \code{AF} and \code{C1}, each
#'   \code{NA_character_} if there is nothing to report.
#' @noRd
parse_authors <- function(author_list) {
  empty <- list(AU = NA_character_, AF = NA_character_, C1 = NA_character_)
  authors <- author_list[names(author_list) == "Author"]
  if (length(authors) == 0) return(empty)

  names_au <- names_af <- character(length(authors))
  aff <- character(0)
  for (j in seq_along(authors)) {
    author <- authors[[j]]
    last <- node_text(author$CollectiveName)
    if (!is.na(last)) {
      names_au[j] <- names_af[j] <- last
    } else {
      last <- node_text(author$LastName)
      if (!is.na(last)) {
        initials <- node_text(author$Initials)
        fore <- node_text(author$ForeName)
        names_au[j] <- if (is.na(initials)) last else paste(last, initials)
        names_af[j] <- if (is.na(fore)) last else paste0(last, ", ", fore)
      }
    }
    info <- author[names(author) == "AffiliationInfo"]
    aff <- c(aff, vapply(info, function(k) node_text(k$Affiliation), character(1)))
  }

  aff <- aff[!is.na(aff)]
  aff <- clean_affiliation(aff)
  aff <- unique(aff[nzchar(aff)])
  list(
    AU = if (any(nzchar(names_au))) paste(names_au[nzchar(names_au)], collapse = ";") else NA_character_,
    AF = if (any(nzchar(names_af))) paste(names_af[nzchar(names_af)], collapse = ";") else NA_character_,
    C1 = if (length(aff) > 0) paste(aff, collapse = ";") else NA_character_
  )
}


#' Parse a batch returned by efetch
#'
#' @param doc The parsed XML document.
#' @return The list of records.
#' @noRd
parse_batch <- function(doc) {
  records <- xmlToList(doc, simplify = FALSE)
  if ("ERROR" %in% names(records)) {
    stop("PubMed returned an error: ", node_text(records$ERROR), call. = FALSE)
  }
  records
}


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

    citation <- node_text(r$Citation)

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
#' Wraps an expression with error handling and exponential backoff retry. A
#' client error (HTTP 4xx other than 429) is final, and is not retried. The
#' expression is evaluated anew at each attempt: re-forcing a failed promise
#' would raise a warning every time.
#'
#' @param expr An expression to evaluate (typically an API call)
#' @param max_retries Maximum number of retry attempts
#' @param verbose Logical, whether to print retry messages
#' @return The result of the expression
#' @noRd
api_call_with_retry <- function(expr, max_retries = 3, verbose = TRUE) {
  call <- substitute(expr)
  env <- parent.frame()
  for (attempt in seq_len(max_retries + 1)) {
    result <- tryCatch(
      list(value = eval(call, env)),
      error = function(e) e
    )
    if (!inherits(result, "error")) return(result$value)

    ## The first line only: NCBI appends a whole HTML page to the message
    reason <- strsplit(conditionMessage(result), "\n", fixed = TRUE)[[1]][1]
    final <- grepl("HTTP failure: 4", reason, fixed = TRUE) &&
      !grepl("HTTP failure: 429", reason, fixed = TRUE)
    if (final) {
      stop(sprintf("API request failed. %s", reason), call. = FALSE)
    }
    if (attempt > max_retries) {
      stop(sprintf(
        "API request failed after %d attempts. Last error: %s",
        max_retries + 1, reason
      ), call. = FALSE)
    }
    wait_time <- min(2^(attempt - 1), 30)
    if (verbose) {
      message(sprintf(
        "API request failed (attempt %d/%d): %s. Retrying in %ds...",
        attempt, max_retries + 1, reason, wait_time
      ))
    }
    Sys.sleep(wait_time)
  }
}
