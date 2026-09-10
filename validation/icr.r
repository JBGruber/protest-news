library(amcat4r)
library(DBI)
library(tidyverse)
library(stringr)
library(jsonlite)
library(tidycomm)
library(gt)
library(yardstick)
library(httr2)

if (file.exists(".env")) {
  readRenviron(".env")
}

amcat_login(
  Sys.getenv("AMCAT_API"),
  api_key = Sys.getenv("AMCAT_KEY"),
  cache = 1L,
  force_refresh = TRUE
)


# α-levels (Krippendorff, 2004, pp. 241-243):
# α > 0.8: reliable
# 0.667 < α ≤ 0.8: tentative conclusions
# α ≤ 0.667: not reliable
icr_print <- function(
  tbl,
  cols = c("Agreement", "Krippendorffs_Alpha")
) {
  alpha_color <- function(x) {
    seg_high <- scales::col_numeric(c("#90EE90", "#006400"), domain = c(0.8, 1))
    seg_mid <- scales::col_numeric(
      c("#FFA500", "#ADFF2F"),
      domain = c(0.667, 0.8)
    )
    seg_low <- scales::col_numeric(
      c("#8B0000", "#FF6B6B"),
      domain = c(-1, 0.667)
    )

    out <- character(length(x))
    high <- !is.na(x) & x >= 0.8
    mid <- !is.na(x) & x >= 0.667 & x < 0.8
    low <- !is.na(x) & x < 0.667
    out[high] <- seg_high(x[high])
    out[mid] <- seg_mid(x[mid])
    out[low] <- seg_low(x[low])
    out[is.na(x)] <- "#FFFFFF"
    out
  }

  tbl |>
    gt() |>
    fmt_number(
      columns = all_of(cols),
      decimals = 2L,
      drop_trailing_zeros = TRUE
    ) |>
    data_color(columns = all_of(cols), fn = alpha_color)
}

ml_metrics <- metric_set(accuracy, precision, recall, f_meas)
ml_metrics <- metric_set(precision, recall, f_meas)


project_id <- 9
f_path <- here::here("validation", "manual_validation.json")
if (!file.exists(f_path)) {
  response <- request(Sys.getenv("LABEL_STUDIO_HOST")) |>
    req_url_path("api", "projects", project_id, "export") |>
    req_headers(
      Authorization = paste("Token", Sys.getenv("LABEL_STUDIO_TOKEN")),
      Accept = "application/json"
    ) |>
    req_url_query(exportType = "JSON") |>
    req_perform(path = f_path)
}

annotations_raw <- read_json(f_path, simplifyVector = TRUE)

llm_raw <- read_json(here::here("validation", "labelstudio_tasks.json")) |>
  map("data") |>
  bind_rows()

llm_annotation <- get_documents(
  "de-news",
  llm_raw$id,
  fields = c(".id", "annotated", "title", "datetime", "text", "annotation_json")
)


# ---------------------------------------------------------------------------
# 1. Parse the HUMAN (Label Studio) annotations into long format
#    one row per: document x protest x variable x annotator
# ---------------------------------------------------------------------------
# Field names in the Label Studio config carry a protest suffix (`_1`, `_2`,
# ...); document-level fields (e.g. `has_protest`) have none. We split that
# suffix off so the variable variable name matches the LLM side, and use protest
# index 0 for document-level fields.
human_tasks <- read_json(f_path, simplifyVector = FALSE)

parse_human <- function(tasks) {
  map_dfr(tasks, function(task) {
    doc_id <- as.character(task$data$id)
    map_dfr(task$annotations, function(ann) {
      annotator <- paste0("human_", ann$completed_by)
      map_dfr(ann$result, function(res) {
        # a result value is either a set of `choices` or free `text`
        val <- res$value$choices %||% res$value$text
        tibble(
          doc_id = doc_id,
          source = annotator,
          field = res$from_name,
          value = paste(unlist(val), collapse = "; ")
        )
      })
    })
  }) |>
    # split trailing "_<n>" into variable variable + protest index (0 = doc level)
    mutate(
      protest = as.integer(str_match(field, "_(\\d+)$")[, 2]),
      protest = replace_na(protest, 0L),
      variable = str_remove(field, "_\\d+$")
    ) |>
    select(doc_id, protest, variable, source, value) |>
    pivot_wider(
      id_cols = c(doc_id, variable),
      names_from = source,
      values_from = value
    )
}

human_long <- parse_human(human_tasks)


# ---------------------------------------------------------------------------
# 2. Parse the LLM annotations (nested list in annotation_json) into the
#    same long format, mapping field names onto the human variables.
# ---------------------------------------------------------------------------
first_chr <- function(x) {
  v <- unlist(x, use.names = FALSE)
  if (length(v) == 0) NA_character_ else as.character(v[[1]])
}

# yes/no flag from a {reported: [true/false]} sub-object
reported_flag <- function(x) {
  r <- first_chr(x$reported)
  if (is.na(r)) {
    return(NA_character_)
  }
  if (tolower(r) %in% c("true", "yes")) "yes" else "no"
}

# normalise police "present" onto the human levels (yes / no / not_reported)
norm_present <- function(x) {
  v <- first_chr(x)
  if (is.na(v)) {
    return(NA_character_)
  }
  v <- tolower(v)
  dplyr::recode(v, "true" = "yes", "false" = "no", .default = gsub(" ", "_", v))
}

parse_llm_protest <- function(p) {
  # primary topic = the topic flagged relevance == "primary"
  primary_topic <- NA_character_
  if (length(p$topics) > 0) {
    rel <- map_chr(p$topics, ~ first_chr(.x$relevance))
    nm <- map_chr(p$topics, ~ first_chr(.x$topic_name))
    hit <- which(rel == "primary")
    if (length(hit) > 0) primary_topic <- nm[hit[1]]
  }

  tibble(
    is_protest = first_chr(p$is_protest),
    event_date = first_chr(p$event_date),
    num_days = first_chr(p$number_of_days),
    main_issue = first_chr(p$main_issue),
    target = first_chr(p$target),
    primary_topic = primary_topic,
    sentiment = first_chr(p$sentiment),
    police_present = norm_present(p$police$present),
    counterprotestors_reported = reported_flag(p$counterprotestors),
    arrests_reported = reported_flag(p$arrests),
    prot_violence_reported = reported_flag(p$protester_violence),
    property_damage_reported = reported_flag(p$property_damage),
    injuries_protesters = reported_flag(p$injuries$protesters),
    injuries_bystanders = reported_flag(p$injuries$bystanders),
    injuries_police = reported_flag(p$injuries$police),
    injuries_others = reported_flag(p$injuries$others),
    deaths_protesters = reported_flag(p$deaths$protesters),
    deaths_bystanders = reported_flag(p$deaths$bystanders),
    deaths_police = reported_flag(p$deaths$police),
    deaths_others = reported_flag(p$deaths$others)
  )
}

parse_llm_doc <- function(doc_id, aj) {
  # annotation_json may arrive as a JSON string or an already-parsed list
  if (is.character(aj)) {
    aj <- fromJSON(aj, simplifyVector = FALSE)
  }
  protests <- aj$protests

  # document-level: did the LLM code any protest at all?
  doc_level <- tibble(
    doc_id = doc_id,
    protest = 0L,
    variable = "has_protest",
    value = if (length(protests) > 0) "yes_or_unsure" else "no"
  )
  if (length(protests) == 0) {
    return(doc_level)
  }

  per_protest <- imap_dfr(protests, function(p, i) {
    parse_llm_protest(p) |>
      pivot_longer(everything(), names_to = "variable", values_to = "value") |>
      mutate(doc_id = doc_id, protest = as.integer(i), .before = 1)
  })

  bind_rows(doc_level, per_protest) |>
    filter(!is.na(value))
}

llm_long <- llm_annotation |>
  filter(!map_lgl(annotation_json, is.null)) |>
  transmute(doc_id = as.character(`.id`), annotation_json) |>
  pmap_dfr(function(doc_id, annotation_json) {
    parse_llm_doc(doc_id, annotation_json)
  }) |>
  mutate(source = "llm") |>
  pivot_wider(
    id_cols = c(doc_id, variable),
    names_from = source,
    values_from = value
  )

cmp_df <- full_join(human_long, llm_long, by = c("doc_id", "variable")) |>
  filter(doc_id %in% human_long$doc_id) |>
  complete(doc_id, variable) |>
  mutate(across(c("llm", starts_with("human")), ~ replace_na(.x, "(none)")))


cmp_df_filt <- cmp_df |>
  filter(
    !variable %in%
      c(
        "keywords",
        "locations",
        "main_issue",
        "notes",
        "primary_topic",
        "target",
        "topics"
      )
  ) |>
  group_by(variable) |>
  mutate(
    across(c(human_1, llm), ~ as.factor(.)),
    human_1 = fct_unify(list(human_1, llm))[[1]],
    llm = fct_unify(list(human_1, llm))[[2]]
  )

cmp_df_filt |>
  ml_metrics(truth = "human_1", estimate = "llm") |>
  pivot_wider(
    id_cols = variable,
    names_from = .metric,
    values_from = .estimate
  ) |>
  icr_print(cols = c("precision", "recall", "f_meas"))


icr_select <- cmp_df |>
  filter(
    variable %in%
      c(
        # enum / categorical
        "has_protest",
        "is_protest",
        "police_present",
        "sentiment",
        "primary_topic",
        # binary reported-flags
        "counterprotestors_reported",
        "arrests_reported",
        "prot_violence_reported"
        #"property_damage_reported",
        # "injuries_protesters",
        # "injuries_bystanders",
        # "injuries_police",
        # "injuries_others",
        # "deaths_protesters",
        # "deaths_bystanders",
        # "deaths_police",
        # "deaths_others"
      )
  ) |>
  group_by(variable) |>
  mutate(
    across(c(human_1, llm), ~ as.factor(.)),
    human_1 = fct_unify(list(human_1, llm))[[1]],
    llm = fct_unify(list(human_1, llm))[[2]]
  ) |>
  ml_metrics(truth = "human_1", estimate = "llm") |>
  pivot_wider(
    id_cols = variable,
    names_from = .metric,
    values_from = .estimate
  ) |>
  arrange(variable) |>
  icr_print(cols = c("precision", "recall", "f_meas"))
icr_select

gtsave(icr_select, "validation.png")

cmp_df_filt |>
  filter(variable == "police_present") |>
  View()


cmp_df_filt |>
  filter(doc_id == "1781303405166953") |>
  View()


filter(str_detect(title, "IG Metall ruft Tausende Sta")) |>
  pull(annotation_json) |>
  toJSON(pretty = T)
llm_annotation |>
  filter(.id == "1781303405166953") |>
  pull(title)
