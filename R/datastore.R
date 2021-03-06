#' @title Retrieve git hbgd repository addresses from data store explorer
#' @description Copy URL of current data store explorer state on clipboard and function returns list of
#' checked studies with their respective clone paths on the git repository.
#' @param con character, contains URI address or 'clipboard' which reads the URI from system clipboard, Default: 'clipboard'
#' @return data.frame
#' @importFrom httr http_error
#' @importFrom rvest html_nodes html_attr html_text
#' @importFrom utils sessionInfo read.table
#' @importFrom xml2 read_html
#' @examples
#' \donttest{
#' query='Country=BFA&Country=BGD&Country=BGD%2C+BRA%2C+IND%2C+NPL%2C+PER%2C+PAK%2C+ZAF%2C+TZA'
#' ghap_uri_base='http://hbgddatastoreserver-env.us-west-2.elasticbeanstalk.com/studies/explorer'
#' uri=sprintf('%s?%s',ghap_uri_base,query)
#' paste_repos(uri)
#'
#' writeClipboard(uri)
#' paste_repos()
#'
#' }
#' @export
paste_repos <- function(con = "clipboard") {

  # check git credentials & fetch current study list
  ghap_studies <- ghap::get_study_list()

  # read URI path
  if (con == "clipboard") {
    uri <- ifelse(grepl("apple", utils::sessionInfo()[[1]]$platform),
      suppressWarnings(
       utils::read.table(pipe("pbpaste"), stringsAsFactors = FALSE)[, 1]),
      suppressWarnings(
       utils::read.table("clipboard", stringsAsFactors = FALSE)[, 1])
    )
  } else {
    uri <- con
  }

  # check URI head
  if (httr::http_error(uri))
    stop(sprintf("error in URL address: %s"), uri)

  # read in URI html
  ds <- xml2::read_html(uri)

  # parse html for study list what studies are listed?
  xpth <- "//*[contains(concat( \" \", @class, \" \" ), concat( \" \", \"switch-label\", \" \" ))]"
  ds_studies <- ds %>%
    rvest::html_nodes(xpath = xpth) %>%
    rvest::html_text()

  # what studies are checked?
  ds_check <- ds %>%
    rvest::html_nodes(xpath = "//*[starts-with(@id,\"id_study\")]") %>%
    rvest::html_attr("checked")

  # filter checked studies
  check_studies <- ds_studies[!is.na(ds_check)]

  # filter git study list with checked studies
  ret_studies <- ghap_studies[ghap_studies$studyid %in%
    check_studies, c("study_id", "grant_folder")]

  # create valid git repo paths for selected repositories
  ret_studies$git_path <- sprintf("https://git.ghap.io/stash/scm/hbgd/%s.git",
    ret_studies$grant_folder)

  # return studies
  ret_studies
}
