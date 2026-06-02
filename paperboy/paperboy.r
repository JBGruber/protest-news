# 0. load packages
suppressPackageStartupMessages({
  library(amcat4r)
  library(dplyr)
})

if (file.exists(".env")) {
  readRenviron(".env")
}

# 1. connect to AmCAT and get unhydrated articles from AmCAT
amcat_login(
  Sys.getenv("AMCAT_API"),
  api_key = Sys.getenv("AMCAT_KEY"),
  cache = 1L,
  force_refresh = TRUE
)
# get_fields("de-news")

unhydrated <- query_documents(
  "de-news",
  fields = c(".id", "url", "hydrated"),
  filters = list("hydrated" = "false")
)

if (nrow(unhydrated) > 0) {
  pak::pak("JBGruber/paperboy")
  library(paperboy)
  # 2. hydrate articles
  processed_entries_raw <- unhydrated |>
    pull(url) |>
    pb_collect(collect_rss = FALSE, ignore_fails = TRUE) |>
    pb_deliver(try_default = FALSE, ignore_fails = TRUE)

  # 3. process for AmCAT
  processed_entries <- processed_entries_raw |>
    filter(
      status == 200L,
      !is.na(datetime),
      nchar(headline) > 1L,
      nchar(text) > 25L
    ) |>
    left_join(unhydrated, by = "url") |>
    mutate(hydrated = TRUE) |>
    select(
      .id,
      url,
      expanded_url,
      domain,
      datetime,
      author,
      title = headline,
      text,
      hydrated
    )

  # 4. update in place
  update_documents("de-news", documents = processed_entries)
  cli::cli_alert_success("Hydrated {nrow(processed_entries)} documents")
} else {
  # if there are no documents to process, wait for 10 minutes
  Sys.sleep(10 * 60)
}
