#' Build a PubMed search query programmatically
#'
#' It helps to build a valid PubMed search query using the Entrez query language,
#' combining multiple search terms with Boolean operators.
#'
#' @param terms is a character or character vector. Search terms to look for in title and abstract fields.
#' @param fields is a character or character vector. PubMed search tags to apply.
#' Default is \code{c("Title/Abstract")}. Common fields include: "Title/Abstract", "Title", "Author",
#' "MeSH Terms", "Affiliation", "Journal".
#' @param language is a character or NULL. Language filter (e.g. "english", "french"). Default is \code{NULL} (no filter).
#' @param pub_type is a character or NULL. Publication type filter (e.g. "Journal Article", "Review", "Clinical Trial").
#' Default is \code{NULL} (no filter).
#' @param date_range is a character vector of length 2 or NULL. Date range in format \code{c("YYYY", "YYYY")} or
#' \code{c("YYYY/MM/DD", "YYYY/MM/DD")}. Default is \code{NULL} (no filter).
#' @param mesh_terms is a character or character vector or NULL. MeSH (Medical Subject Headings) terms.
#' Default is \code{NULL} (no filter).
#' @param author is a character or character vector or NULL. Author names. Default is \code{NULL}.
#' @param journal is a character or character vector or NULL. Journal names or abbreviations. Default is \code{NULL}.
#' @param operator is a character. Boolean operator to combine multiple \code{terms}. One of "AND", "OR".
#' Default is \code{"AND"}.
#'
#' @return a character string containing the formatted PubMed query.
#'
#' @details
#' The function constructs a query string compatible with NCBI's Entrez search system.
#' Multiple terms within the same parameter are combined with the specified \code{operator},
#' while different parameters (terms, language, pub_type, etc.) are combined with AND.
#'
#' For more information about PubMed search tags, visit:
#' \href{https://pubmed.ncbi.nlm.nih.gov/help/#search-tags}{https://pubmed.ncbi.nlm.nih.gov/help/#search-tags}
#'
#' @examples
#'
#' # Simple query
#' q <- pmQueryBuild(terms = "bibliometrics", language = "english",
#'                   pub_type = "Journal Article", date_range = c("2000", "2023"))
#'
#' # Multiple terms
#' q <- pmQueryBuild(terms = c("machine learning", "deep learning"),
#'                   operator = "OR", language = "english")
#'
#' # MeSH terms query
#' q <- pmQueryBuild(mesh_terms = "COVID-19", pub_type = "Review",
#'                   date_range = c("2020", "2024"))
#'
#' # Author search
#' q <- pmQueryBuild(terms = "bibliometrics", author = "Aria M")
#'
#' @seealso \code{\link{pmQueryTotalCount}}
#' @seealso \code{\link{pmApiRequest}}
#'
#' @export
pmQueryBuild <- function(terms = NULL,
                         fields = "Title/Abstract",
                         language = NULL,
                         pub_type = NULL,
                         date_range = NULL,
                         mesh_terms = NULL,
                         author = NULL,
                         journal = NULL,
                         operator = "AND") {

  operator <- match.arg(toupper(operator), choices = c("AND", "OR"))
  parts <- c()

  ## Search terms with field tags
  if (!is.null(terms) && length(terms) > 0) {
    term_parts <- vapply(terms, function(t) {
      field_queries <- vapply(fields, function(f) {
        sprintf("%s[%s]", t, f)
      }, character(1))
      if (length(field_queries) > 1) {
        paste0("(", paste(field_queries, collapse = " OR "), ")")
      } else {
        field_queries
      }
    }, character(1), USE.NAMES = FALSE)

    if (length(term_parts) > 1) {
      parts <- c(parts, paste0("(", paste(term_parts, collapse = paste0(" ", operator, " ")), ")"))
    } else {
      parts <- c(parts, term_parts)
    }
  }

  ## MeSH terms
  if (!is.null(mesh_terms) && length(mesh_terms) > 0) {
    mesh_parts <- vapply(mesh_terms, function(m) {
      sprintf("%s[MeSH Terms]", m)
    }, character(1), USE.NAMES = FALSE)
    if (length(mesh_parts) > 1) {
      parts <- c(parts, paste0("(", paste(mesh_parts, collapse = " OR "), ")"))
    } else {
      parts <- c(parts, mesh_parts)
    }
  }

  ## Author
  if (!is.null(author) && length(author) > 0) {
    au_parts <- vapply(author, function(a) {
      sprintf("%s[Author]", a)
    }, character(1), USE.NAMES = FALSE)
    if (length(au_parts) > 1) {
      parts <- c(parts, paste0("(", paste(au_parts, collapse = " AND "), ")"))
    } else {
      parts <- c(parts, au_parts)
    }
  }

  ## Journal
  if (!is.null(journal) && length(journal) > 0) {
    jo_parts <- vapply(journal, function(j) {
      sprintf("%s[Journal]", j)
    }, character(1), USE.NAMES = FALSE)
    if (length(jo_parts) > 1) {
      parts <- c(parts, paste0("(", paste(jo_parts, collapse = " OR "), ")"))
    } else {
      parts <- c(parts, jo_parts)
    }
  }

  ## Language
  if (!is.null(language) && nzchar(language)) {
    parts <- c(parts, sprintf("%s[LA]", language))
  }

  ## Publication type
  if (!is.null(pub_type) && nzchar(pub_type)) {
    parts <- c(parts, sprintf("%s[PT]", pub_type))
  }

  ## Date range
  if (!is.null(date_range) && length(date_range) == 2) {
    parts <- c(parts, sprintf("%s:%s[DP]", date_range[1], date_range[2]))
  }

  if (length(parts) == 0) {
    stop("At least one search parameter must be provided.", call. = FALSE)
  }

  query <- paste(parts, collapse = " AND ")
  return(query)
}
