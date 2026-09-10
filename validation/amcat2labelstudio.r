suppressPackageStartupMessages({
  library(amcat4r)
  library(DBI)
  library(dplyr)
  library(stringr)
  library(jsonlite)
})

if (file.exists(".env")) {
  readRenviron(".env")
}

amcat_login(
  Sys.getenv("AMCAT_API"),
  api_key = Sys.getenv("AMCAT_KEY"),
  cache = 1L,
  force_refresh = TRUE
)

validation_candidates <- query_documents(
  "de-news",
  fields = c(
    ".id",
    "annotated",
    "title",
    "datetime",
    "text",
    "annotation_json"
  ),
  filters = list("hydrated" = "true", annotated = "qwen3.5:9b"),
  per_page = 200,
  max_pages = Inf
)

set.seed(1)
validation_set <- validation_candidates |>
  sample_n(size = 250)

validation_set |>
  mutate(
    date = as.character(as.Date(datetime)),
    fulltext = glue::glue(
      "<strong>Title: {title} (published {as.Date(datetime)})</strong><br><br>{text}"
    ),
    fulltext = str_replace_all(fulltext, "\n", "<br>"),
    # very long texts can't be processed and are usuallylive tickers
    fulltext = str_sub(fulltext, end = 20000)
  ) |>
  select(id = .id, title, date, fulltext) |>
  write_json(
    path = here::here("validation", "labelstudio_tasks.json"),
    auto_unbox = TRUE,
    pretty = TRUE
  )
