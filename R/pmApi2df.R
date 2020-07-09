#' Convert xml PubMed bibliographic data into a dataframe
#'
#' It converts PubMed data, downloaded using Entrez API, into a dataframe
#'
#' @param P is a list following the xml PubMed structure, downloaded using the function \code{pmApiRequest}.
#' @param format is a character. If \code{format = "bibliometrix"} data will be converted in the bibliometrix complatible data format.
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
pmApi2df <- function(P, format="bibliometrix"){

    P <- P$data

    n <- length(P)


    ### Data Conversion

    df <- data.frame(AU=rep(NA,n), AF="NA",TI="NA", SO="NA", SO_CO=NA, LA=NA, DT=NA,DE=NA,ID=NA,MESH=NA,AB="NA",C1=NA,CR="NA",
                     TC=NA, SN=NA, J9=NA, JI=NA, PY=NA, PY_IS=NA, VL=NA, DI=NA, PG=NA, GRANT_ID=NA, GRANT_ORG=NA, UT=NA, PMID=NA,
                     DB="PUBMED", AU_UN=NA, stringsAsFactors = FALSE)

    pb <- utils::txtProgressBar(min = 1, max = n, initial = 1, char = "=")

    for (i in 1:n) {
      #if (i%%100==0 | i==n) cat("Documents converted  ",i,"of",n, "\n")
      #print(i)
      utils::setTxtProgressBar(pb, i)

        a <- list2char(P[[i]])

        items<- names(a)

        ## Language
        df$LA[i] <- a["MedlineCitation.Article.Language"]

        ## Document Type
        df$DT[i] <- a["MedlineCitation.Article.PublicationTypeList.PublicationType.text"]

        ## Title
        df$TI[i] <- a["MedlineCitation.Article.ArticleTitle"]

        ## Publication Year

        ind <- which(items == "PubmedData.History.PubMedPubDate.Year")

        if(length(ind)>0){
          df$PY[i] <- min(as.numeric(a[ind]),na.rm = TRUE)
        }else{df$PY[i]=NA}

        df$PY_IS[i] <- a["MedlineCitation.Article.Journal.JournalIssue.PubDate.Year"]

        ## Co-Authors
        AU_last_ind <- which(items == "MedlineCitation.Article.AuthorList.Author.LastName")
        AU_first_ind <- which(items == "MedlineCitation.Article.AuthorList.Author.ForeName")
        AU_init_ind <- which(items == "MedlineCitation.Article.AuthorList.Author.Initials")
        nameAF <-  paste(a[AU_last_ind], a[AU_first_ind], sep=", ")
        nameAU <-  paste(a[AU_last_ind], a[AU_init_ind], sep=" ")
        df$AF[i] <- paste(nameAF, collapse = ";")
        df$AU[i] <- paste(nameAU, collapse = ";")

        ## Affiliations
        Aff_name_ind <- which(items == "MedlineCitation.Article.AuthorList.Author.AffiliationInfo.Affiliation")
        Affiliations <- a[Aff_name_ind]

        Affiliations <- lapply(Affiliations,function(l){
          l <- unlist(strsplit(l,", "))
          l <- paste(l[!(regexpr("\\@",l)>-1)],collapse=", ")
        })
        df$C1[i] <- df$AU_UN[i] <- paste(Affiliations, collapse=";")

        ## Keywords and MeSH
        DE_ind <- which(items == "MedlineCitation.KeywordList.Keyword.text")
        df$DE[i] <- paste(a[DE_ind],collapse=";")
        ID_ind <- which(items == "MedlineCitation.MeshHeadingList.MeshHeading.DescriptorName.text")
        df$ID[i] <- df$MESH[i] <- paste(a[ID_ind],collapse=";")

        ## Abstract
        ind <- which(items %in% "MedlineCitation.Article.Abstract.AbstractText.text" )
        if (length(ind)>0){
          df$AB[i] <- paste(a[ind],collapse=" ")
        }else{
          ind <- which(items %in% "MedlineCitation.Article.Abstract.AbstractText")
          if (length(ind)>0){
            df$AB[i] <- a[ind]
          }
        }

        ## Journals
        df$SO[i] <- a["MedlineCitation.Article.Journal.Title"]

        df$JI[i] <- df$J9[i] <- a["MedlineCitation.Article.Journal.ISOAbbreviation"]

        df$SO_CO[i] <- a["MedlineCitation.MedlineJournalInfo.Country"]

        ## Doi
        doi_ind <- which(items == "PubmedData.ArticleIdList.ArticleId..attrs.IdType" )

        ind <- which(a[doi_ind]=="doi")
        if (length(ind)>0){
          doi_ind <- doi_ind[ind]-1
          df$DI[i] <- a[doi_ind]
        }

        ## ISSN
        df$SN[i] <- a["MedlineCitation.Article.Journal.ISSN.text"]

        ## Pages
        df$PG[i] <- a["MedlineCitation.Article.Pagination.MedlinePgn"]

        ## Volume
        df$VL[i] <- a["MedlineCitation.Article.Journal.JournalIssue.Volume"]

        ## ID
        df$UT[i] <- df$PMID[i] <- a["MedlineCitation.PMID.text"]

        ## grants
        GR_ID <- which(items %in% "MedlineCitation.Article.GrantList.Grant.GrantID")
        df$GRANT_ID[i] <- paste(a[GR_ID], collapse=";")
        GR_ORG <- which(items %in% "MedlineCitation.Article.GrantList.Grant.Agency")
        df$GRANT_ORG[i] <- paste(a[GR_ORG],collapse=";")

    }


    if (format == "bibliometrix") {
      DI <- df$DI
      df <- data.frame(lapply(df, toupper), stringsAsFactors = FALSE)
      df$DI <- DI
      df$AU_CO="NA"
      df$AU1_CO="NA"
    }

    ### PY
    df$PY <- as.numeric(df$PY)

    ### TC and TCR
    df$TC <- as.numeric(df$TC)
    df$TC[is.na(df$TC)] <- 0

    ###  remove empy rows
    df=df[!is.na(df$DT),]

    ### To Add in convert2df
    ### SR field creation
    #suppressWarnings(df <- metaTagExtraction(df, Field="SR"))

    #row.names(df) <- df$SR
    close(pb)

    return(df)

}


#### function list2char ####
list2char <- function (x, use.names = TRUE, classes = "ANY")
{
  lung <- sum(rapply(x, function(x) 1L, classes = classes))
  Ch <- vector("list", lung)
  i <- 0L
  items <- rapply(x, function(x) {
    i <<- i + 1L
    Ch[[i]] <<- x
    TRUE
  }, classes = classes)
  if (use.names && !is.null(nm <- names(items)))
    names(Ch) <- nm
  Ch <- unlist(Ch)
  return(Ch)
}
