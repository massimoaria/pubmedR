library(rentrez)
library(XML)
api_key=NULL
entrez_db_searchable('pubmed')

d_search <- entrez_search(db="pubmed", term="Diabetes Mellitus, Type 1[MeSH Terms]" , retmax=0,
                          api_key =api_key, use_history = T)
d_search
limit <- 152
n <- d_search$count
n <- min(n,limit)
step <- 200
step <- min(limit, step)
metadata <- list()
stop <- FALSE
s <- 1

while(!isTRUE(stop)) {
  multi_summs <-
    entrez_fetch(
      db = "pubmed",
      web_history = d_search$web_history,
      retstart = s,
      retmax = step,
      rettype = "xml",
      parsed = T,
      api_key = api_key
    )
  multi_summs <- xmlToList(multi_summs, simplify = F)
  metadata <- c(metadata, multi_summs)

  if (n <= (s + step)) {
    stop <- TRUE
  } else{
    s <- s + step
    if ((s + step) > limit) {
      step <- (n - s + 1)
    }
    print(s - 1)
  }
}



i=1

a <- list2char(metadata[[i]])
items <- names(a)






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
