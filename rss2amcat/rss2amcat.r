# 0. load packages
suppressPackageStartupMessages({
  library(amcat4r)
  library(DBI)
  library(dplyr)
  library(stringr)
})
Sys.setenv(AMCT_API = "http://amcat-frontend:80/api")
if (file.exists(".env")) {
  readRenviron(".env")
  Sys.setenv(AMCT_API = "https://protest.jbgruber.online/api")
}

# 0. connect to AmCAT and create index
amcat_login(
  Sys.getenv("AMCT_API"),
  api_key = Sys.getenv("AMCAT_KEY"),
  cache = 1L,
  force_refresh = TRUE
)
if (!"de-news" %in% list_indexes()$id) {
  fields <- list(
    url = "url",
    expanded_url = "url",
    domain = "keyword",
    datetime = "date",
    modified = "date",
    author = "text",
    title = "text",
    text = "text",
    hydrated = "boolean",
    annotated = "keyword",
    annotation_json = "object"
  )
  create_index(
    index = "de-news",
    name = "Protest News",
    description = "German News about protests scraped from several RSS Feeds",
    create_fields = fields,
    guest_role = "metareader"
  )
  set_metareader_access(
    "de-news",
    list(
      url = list(access = "read"),
      # expanded_url = "url",
      domain = list(access = "read"),
      datetime = list(access = "read"),
      author = list(access = "read"),
      title = list(access = "read"),
      text = list(access = "snippet", max_snippet = list(nomatch_chars = 50)),
      hydrated = list(access = "read"),
      annotated = list(access = "read"),
      annotation_json = list(access = "read")
    )
  )
  # get_fields("de-news")
}


# 1. get unread articles from FreshRSS
con <- dbConnect(
  drv = RPostgres::Postgres(),
  dbname = "freshrss-db",
  host = Sys.getenv("POSTGRES_DB", unset = "localhost"),
  port = 5432,
  user = Sys.getenv("POSTGRES_USER", unset = "freshrss"),
  password = Sys.getenv("POSTGRES_PASSWORD", unset = "freshrss")
)

unread_entries <- tbl(con, "freshrss_admin_entry") |>
  filter(is_read == 0) |>
  select(
    id,
    date,
    modified = lastModified,
    link,
    title,
    author,
    text = content,
    tags,
    is_read
  ) |>
  head(1000) |>
  collect() |>
  mutate(
    date = as.POSIXct(date, origin = "1970-01-01"),
    modified = as.POSIXct(modified, origin = "1970-01-01")
  )

# 2. filter protest articles
rgx <- "protest|demonstr"
entries_protest <- unread_entries |>
  mutate(
    protest = str_detect(
      paste(title, text, tags),
      regex(rgx, ignore_case = TRUE)
    )
  )


# 3. upload to amcat
entries_protest |>
  filter(protest) |>
  select(.id = id, url = link, datetime = date, title, author, text) |>
  upload_documents(index = "de-news", documents = _)
# query_documents("de-news")

# 4. mark processed entries as read
dbExecute(
  con,
  sprintf(
    "
  UPDATE freshrss_admin_entry
  SET is_read = 1
  WHERE id IN (%s)
  ",
    paste0(entries_protest$id, collapse = ",")
  )
)
