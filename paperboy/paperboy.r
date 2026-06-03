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
  fields = c(".id", "url", "hydrated", "hydration_attempts"),
  filters = list(
    hydrated = list(exists = FALSE)
  ),
  verbose = FALSE
)

unhydrated_fails <- query_documents(
  "de-news",
  fields = c(".id", "url", "hydrated", "hydration_attempts"),
  filters = list(
    hydrated = "false",
    hydration_attempts = list(lt = 3L)
  ),
  verbose = FALSE
)

if (nrow(unhydrated) > 0 & nrow(unhydrated_fails) > 0) {
  unhydrated <- bind_rows(unhydrated, unhydrated_fails)
}

cli::cli_alert_info("Retrieved {nrow(unhydrated)} new documents")

if (!"hydration_attempts" %in% colnames(unhydrated)) {
  unhydrated <- mutate(unhydrated, hydration_attempts = 0)
}

unhydrated <- unhydrated |>
  mutate(
    hydration_attempts = ifelse(
      is.na(hydration_attempts),
      0L,
      hydration_attempts
    )
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
      # this doesn't quite work as many articles have no text
      # (paywall, video or audio conten) clogging up the pipeline
      # nchar(text) > 25L
    ) |>
    mutate(text = ifelse(text == "", "[could not be hydrated]", text)) |>
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

  # 5. set hydration counter for failed documents
  processed_entries_failed <- unhydrated |>
    filter(!.id %in% processed_entries$.id) |>
    mutate(hydration_attempts = hydration_attempts + 1)

  update_documents("de-news", documents = processed_entries_failed)

  cli::cli_alert_success("Hydrated {nrow(processed_entries)} documents")
} else {
  # if there are no documents to process, wait for 10 minutes
  Sys.sleep(10 * 60)
}
