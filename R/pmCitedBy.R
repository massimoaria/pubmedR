#' Find articles that cite a given PubMed article
#'
#' It retrieves the PMIDs of articles that cite a given PubMed article,
#' using the NCBI E-Link service (PubMed Cited by).
#'
#' @param pmid is a character or numeric. A single PubMed identifier (PMID).
#' @param api_key is a character. It contains a valid API key for the NCBI E-utilities.
#' Default is \code{api_key=NULL}. The API key can also be set via the environment variable
#' \code{PUBMED_API_KEY} or \code{ENTREZ_KEY}.
#'
#' @return a list containing:
#' \tabular{lll}{
#' pmid \tab \tab The queried PMID.\cr
#' cited_by \tab \tab A character vector of PMIDs that cite the queried article.\cr
#' count \tab \tab The number of citing articles found.}
#'
#' @details
#' This function uses the NCBI E-Link endpoint with linkname "pubmed_pubmed_citedin"
#' to find articles in PubMed that cite the given article.
#'
#' Note: Citation data in PubMed is based on PubMed Central (PMC) and may not be as
#' comprehensive as commercial citation databases (e.g. Web of Science, Scopus).
#'
#' @examples
#'
#' \donttest{
#' # Find articles that cite PMID 25824007
#' cites <- pmCitedBy(pmid = "25824007")
#' cites$count
#' cites$cited_by
#' }
#'
#' @seealso \code{\link{pmReferences}}
#' @seealso \code{\link{pmFetchById}}
#'
#' @export
#' @import rentrez

pmCitedBy <- function(pmid, api_key = NULL) {

  api_key <- get_api_key(api_key)
  pmid <- as.character(pmid)[1]

  links <- api_call_with_retry(
    entrez_link(
      dbfrom = "pubmed",
      id = pmid,
      db = "pubmed",
      linkname = "pubmed_pubmed_citedin",
      api_key = api_key
    )
  )

  cited_by <- character(0)
  if (length(links$links$pubmed_pubmed_citedin) > 0) {
    cited_by <- links$links$pubmed_pubmed_citedin
  }

  result <- list(
    pmid = pmid,
    cited_by = cited_by,
    count = length(cited_by)
  )
  return(result)
}


#' Find references cited by a given PubMed article
#'
#' It retrieves the PMIDs of articles that are cited by (referenced in) a given
#' PubMed article, using the NCBI E-Link service.
#'
#' @param pmid is a character or numeric. A single PubMed identifier (PMID).
#' @param api_key is a character. It contains a valid API key for the NCBI E-utilities.
#' Default is \code{api_key=NULL}. The API key can also be set via the environment variable
#' \code{PUBMED_API_KEY} or \code{ENTREZ_KEY}.
#'
#' @return a list containing:
#' \tabular{lll}{
#' pmid \tab \tab The queried PMID.\cr
#' references \tab \tab A character vector of PMIDs referenced by the queried article.\cr
#' count \tab \tab The number of references found.}
#'
#' @details
#' This function uses the NCBI E-Link endpoint with linkname "pubmed_pubmed_refs"
#' to find articles in PubMed that are referenced by the given article.
#'
#' Note: Reference data is extracted from PubMed Central (PMC) full-text articles and
#' is only available when the full text is deposited in PMC. Not all PubMed articles
#' have reference data available.
#'
#' @examples
#'
#' \donttest{
#' # Find references of PMID 25824007
#' refs <- pmReferences(pmid = "25824007")
#' refs$count
#' refs$references
#' }
#'
#' @seealso \code{\link{pmCitedBy}}
#' @seealso \code{\link{pmFetchById}}
#'
#' @export
#' @import rentrez

pmReferences <- function(pmid, api_key = NULL) {

  api_key <- get_api_key(api_key)
  pmid <- as.character(pmid)[1]

  links <- api_call_with_retry(
    entrez_link(
      dbfrom = "pubmed",
      id = pmid,
      db = "pubmed",
      linkname = "pubmed_pubmed_refs",
      api_key = api_key
    )
  )

  references <- character(0)
  if (length(links$links$pubmed_pubmed_refs) > 0) {
    references <- links$links$pubmed_pubmed_refs
  }

  result <- list(
    pmid = pmid,
    references = references,
    count = length(references)
  )
  return(result)
}


#' Enrich a PubMed dataframe with citation data
#'
#' Adds cited references (CR field), reference counts (NR field), and
#' optionally citation counts (TC field) to a dataframe created by
#' \code{\link{pmApi2df}}.
#'
#' @param df is a dataframe. A bibliometric dataframe produced by
#'   \code{\link{pmApi2df}}.
#' @param P is the optional list returned by \code{\link{pmApiRequest}} or
#'   \code{\link{pmFetchById}} that produced \code{df}. Reuse it to avoid an
#'   extra round-trip when references are already available. If \code{NULL},
#'   the function calls \code{pmFetchById} on \code{df$PMID} to retrieve the
#'   underlying XML.
#' @param api_key is a character. It contains a valid API key for the NCBI
#'   E-utilities. Default is \code{api_key=NULL}. The API key can also be set
#'   via the environment variable \code{PUBMED_API_KEY} or \code{ENTREZ_KEY}.
#' @param resolve_pmids logical. When \code{TRUE} (default) the function fetches
#'   metadata for every cited PMID present in the references and assembles
#'   structured WoS-style citation strings ("AUTHOR YYYY, JOURNAL, V##, P##,
#'   DOI ..."). When \code{FALSE} the free-text \code{<Citation>} block from
#'   the XML is used as-is.
#' @param only_multiple logical. When \code{TRUE} only references cited by more
#'   than one source article are resolved to metadata (faster and cheaper).
#'   References not resolved keep their free-text citation. Defaults to
#'   \code{FALSE}.
#' @param include_TC logical. When \code{TRUE} (default) also call
#'   \code{\link{pmCitedBy}} for each source article and write the citation
#'   count to \code{df$TC}. Disable to skip this step.
#' @param batch_size integer. Number of records per API call when fetching
#'   metadata. Defaults to 200 (NCBI's hard cap for efetch).
#'
#' @return The input dataframe with updated \code{CR} (cited references),
#'   \code{NR} (number of references), and \code{TC} (times cited, if
#'   \code{include_TC = TRUE}) fields.
#'
#' @details
#' Cited references are extracted from the article's PubMed XML
#' (\code{<ReferenceList>}). This is more reliable than the previous E-Link
#' \code{pubmed_pubmed_refs} approach, which only worked for articles
#' deposited in PMC. References whose XML carries an \code{ArticleId}
#' \code{IdType="pubmed"} are resolved to bibliographic metadata in
#' batched \code{efetch} requests so that \code{CR} matches the WoS
#' convention used by bibliometrix; references with only free-text citations
#' are kept verbatim (uppercased).
#'
#' @examples
#' \donttest{
#' query <- "bibliometric*[Title/Abstract] AND english[LA]
#'          AND Journal Article[PT] AND 2000:2020[DP]"
#' D <- pmApiRequest(query = query, limit = 10, api_key = NULL)
#' M <- pmApi2df(D)
#' M <- pmEnrichCitations(M, P = D)        # avoid the extra fetch
#' }
#'
#' @seealso \code{\link{pmExtractReferences}}, \code{\link{pmCitedBy}},
#'   \code{\link{pmFetchById}}, \code{\link{pmApi2df}}
#'
#' @export
pmEnrichCitations <- function(df,
                              P = NULL,
                              api_key = NULL,
                              resolve_pmids = TRUE,
                              only_multiple = FALSE,
                              include_TC = TRUE,
                              batch_size = 200) {

  api_key <- get_api_key(api_key)

  if (!"PMID" %in% names(df) || nrow(df) == 0) {
    message("No valid PMID field found in the dataframe.")
    return(df)
  }

  pmids <- as.character(df$PMID)
  valid_pmids <- pmids[!is.na(pmids) & nzchar(pmids)]

  ## ----- Step 1: fetch full XML if not provided ---------------------------
  if (is.null(P)) {
    if (length(valid_pmids) == 0) {
      message("No valid PMIDs to enrich.")
      return(df)
    }
    cat("\nFetching XML for", length(valid_pmids), "articles...\n")
    P <- pmFetchById(valid_pmids, api_key = api_key, batch_size = batch_size)
  }

  ## ----- Step 2: extract references per source PMID -----------------------
  records <- P$data
  cat("\nExtracting references from XML...\n")
  pb <- utils::txtProgressBar(min = 0, max = max(length(records), 1), style = 3)
  pmid_to_refs <- list()
  for (i in seq_along(records)) {
    rec <- records[[i]]
    src <- extract_record_pmid(rec)
    if (!is.na(src) && nzchar(src)) {
      pmid_to_refs[[src]] <- extract_refs_from_record(rec)
    }
    utils::setTxtProgressBar(pb, i)
  }
  close(pb)

  ## ----- Step 3: collect unique cited PMIDs and resolve metadata ----------
  cited_lookup <- character(0)
  if (isTRUE(resolve_pmids)) {
    all_cited <- unlist(lapply(pmid_to_refs, function(d) d$pmid), use.names = FALSE)
    all_cited <- all_cited[!is.na(all_cited) & nzchar(all_cited)]

    if (isTRUE(only_multiple)) {
      freq <- table(all_cited)
      unique_cited <- names(freq[freq > 1])
    } else {
      unique_cited <- unique(all_cited)
    }

    if (length(unique_cited) > 0) {
      cat("\nResolving metadata for", length(unique_cited), "unique cited PMIDs...\n")
      cited_xml <- tryCatch(
        pmFetchById(unique_cited, api_key = api_key, batch_size = batch_size),
        error = function(e) NULL
      )
      if (!is.null(cited_xml)) {
        cited_df <- tryCatch(
          pmApi2df(cited_xml, format = "bibliometrix"),
          error = function(e) NULL
        )
        if (!is.null(cited_df) && nrow(cited_df) > 0) {
          for (i in seq_len(nrow(cited_df))) {
            cr <- build_wos_cr_string(as.list(cited_df[i, , drop = FALSE]))
            key <- as.character(cited_df$PMID[i])
            if (!is.na(cr) && nzchar(key)) cited_lookup[key] <- cr
          }
        }
      }
    }
  }

  ## ----- Step 4: assemble CR / NR per row ---------------------------------
  if (!"CR" %in% names(df)) df$CR <- NA_character_
  if (!"NR" %in% names(df)) df$NR <- 0L

  for (i in seq_along(pmids)) {
    p <- pmids[i]
    if (is.na(p) || !nzchar(p)) next
    refs <- pmid_to_refs[[p]]
    if (is.null(refs) || nrow(refs) == 0) next

    cr_strs <- vapply(seq_len(nrow(refs)), function(j) {
      r <- refs[j, , drop = FALSE]
      cited_pmid <- as.character(r$pmid)
      if (!is.na(cited_pmid) && nzchar(cited_pmid) &&
          cited_pmid %in% names(cited_lookup)) {
        return(cited_lookup[[cited_pmid]])
      }
      ctxt <- r$citation
      if (!is.na(ctxt) && nzchar(ctxt)) return(toupper(trimws(ctxt)))
      NA_character_
    }, character(1))

    cr_strs <- cr_strs[!is.na(cr_strs) & nzchar(cr_strs)]
    if (length(cr_strs) == 0) next

    df$CR[i] <- paste(cr_strs, collapse = "; ")
    df$NR[i] <- length(cr_strs)
  }

  ## ----- Step 5: optional TC enrichment via NCBI cited-by ----------------
  if (isTRUE(include_TC)) {
    cat("\nEnriching TC via NCBI cited-by...\n")
    pb <- utils::txtProgressBar(min = 0, max = length(pmids), style = 3)
    last_time <- NULL
    for (i in seq_along(pmids)) {
      p <- pmids[i]
      if (is.na(p) || !nzchar(p)) {
        utils::setTxtProgressBar(pb, i)
        next
      }
      last_time <- api_throttle(api_key, last_time)
      cites <- tryCatch(
        pmCitedBy(p, api_key = api_key),
        error = function(e) list(cited_by = character(0), count = 0)
      )
      df$TC[i] <- cites$count
      utils::setTxtProgressBar(pb, i)
    }
    close(pb)
  }

  cat("\nCitation enrichment completed.\n")
  df
}
