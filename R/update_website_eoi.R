library(tidyverse)
library(httr)
library(openxlsx)

redcap_url <- Sys.getenv("REDCAP_API_URL")
redcap_token <- Sys.getenv("REDCAP_API_TOKEN")
redcap_report_id <- Sys.getenv("REDCAP_REPORT_ID")

if (redcap_url == "" || redcap_token == "" || redcap_report_id == "") {
  stop("Missing REDCAP_API_URL, REDCAP_API_TOKEN, or REDCAP_REPORT_ID")
}

dir.create("data/public", recursive = TRUE, showWarnings = FALSE)

website_eoi <- list(
  token = redcap_token,
  content = "report",
  format = "csv",
  report_id = redcap_report_id,
  csvDelimiter = "",
  rawOrLabel = "label",
  rawOrLabelHeaders = "raw",
  exportCheckboxLabel = "true",
  returnFormat = "json"
) %>%
  POST(redcap_url, body = ., encode = "form") %>%
  content(as = "raw") %>%
  rawToChar() %>%
  iconv(from = "UTF-8", to = "UTF-8") %>%
  read.csv(text = ., stringsAsFactors = FALSE)

income_groupings <- read.xlsx("data/lookup/income_groupings.xlsx")

website_eoi <- website_eoi %>%
  rename(country = country_id) %>%
  left_join(income_groupings, by = "country") %>%
  select(-any_of(c("Code", "Lending.category")))

write.csv(
  website_eoi,
  "data/public/eoi_data.csv",
  row.names = FALSE,
  na = ""
)
