# 0. load packages
suppressPackageStartupMessages({
  library(rollama)
  library(amcat4r)
  library(dplyr)
  library(purrr)
  library(stringr)
  library(tidyr)
})

if (file.exists(".env")) {
  readRenviron(".env")
  setwd(here::here("llm-annotation"))
}

options(
  rollama_server = Sys.getenv("OLLAMA")
)
model <- "qwen3.5:9b"
check_model_installed(model, auto_pull = TRUE)

# 1. connect to AmCAT and get annotation candidates
amcat_login(
  Sys.getenv("AMCAT_API"),
  api_key = Sys.getenv("AMCAT_KEY"),
  cache = 1L,
  force_refresh = TRUE
)

annotation_candidates <- query_documents(
  "de-news",
  fields = NULL, #c(".id", "url", "hydrated"),
  filters = list("hydrated" = "true", annotated = list(exists = FALSE)),
  per_page = 25,
  max_pages = 1
) |>
  mutate(
    fulltext = glue::glue(
      "Title: {title} (published {as.Date(datetime)})\n\n{text})"
    ),
    # very long texts can't be processed and are usuallylive tickers
    fulltext = str_sub(fulltext, end = 20000)
  )

if (nrow(annotation_candidates) > 0) {
  # 2. read in prompt and annotate data
  prompt <- readr::read_file("prompt.md")
  schema <- jsonlite::read_json("ollama_schema.json")

  articles_annotated <- annotation_candidates |>
    mutate(
      query = make_query(
        text = fulltext,
        prompt = prompt,
        template = "\n{prompt}\n{text}"
      ),
      annotation_raw = query(
        query,
        screen = FALSE,
        stream = FALSE,
        model_params = list(num_ctx = 20000L),
        think = FALSE,
        model = model,
        output = "response",
        format = schema
      ),
      annotated = model
    )

  # 3. parse annotation
  parse_annotation <- function(annotation) {
    first_protest <- map(annotation, list("protests", 1))

    format_locations <- function(locs) {
      if (is.null(locs) || length(locs) == 0) {
        return(NA_character_)
      }
      loc_strs <- map_chr(locs, \(loc) {
        parts <- Filter(
          Negate(is.null),
          list(loc[["city"]], loc[["bundesland"]], loc[["country"]])
        )
        paste(parts, collapse = ", ")
      })
      paste(loc_strs, collapse = "; ")
    }

    tibble::tibble(
      is_protest = map_lgl(first_protest, \(p) {
        !is.null(p) && identical(p[["is_protest"]], "yes")
      }),
      event_date = map_chr(first_protest, \(p) {
        if (is.null(p) || is.null(p[["event_date"]])) {
          NA_character_
        } else {
          as.character(p[["event_date"]])
        }
      }),
      location = map_chr(first_protest, \(p) {
        if (is.null(p)) NA_character_ else format_locations(p[["locations"]])
      }),
      main_issue = map_chr(first_protest, \(p) {
        if (is.null(p) || is.null(p[["main_issue"]])) {
          NA_character_
        } else {
          p[["main_issue"]]
        }
      }),
      topic = map_chr(first_protest, \(p) {
        if (is.null(p)) {
          return(NA_character_)
        }
        topics <- p[["topics"]]
        primary <- Filter(\(t) identical(t[["relevance"]], "primary"), topics)
        if (length(primary) == 0) {
          primary <- topics
        }
        if (length(primary) == 0) {
          return(NA_character_)
        }
        t_name <- primary[[1]][["topic_name"]]
        if (is.null(t_name)) NA_character_ else t_name
      }),
      sentiment = map_chr(first_protest, \(p) {
        if (is.null(p) || is.null(p[["sentiment"]])) {
          NA_character_
        } else {
          p[["sentiment"]]
        }
      }),
      number_of_days = map_int(first_protest, \(p) {
        if (is.null(p) || is.null(p[["number_of_days"]])) {
          NA_integer_
        } else {
          as.integer(p[["number_of_days"]])
        }
      }),
      protest_size_numeric = map_int(first_protest, \(p) {
        if (is.null(p)) {
          return(NA_integer_)
        }
        est <- p[["protest_size_estimates"]]
        if (length(est) == 0 || is.null(est[[1]][["numerical_value"]])) {
          NA_integer_
        } else {
          as.integer(est[[1]][["numerical_value"]])
        }
      }),
      protest_size_text = map_chr(first_protest, \(p) {
        if (is.null(p)) {
          return(NA_character_)
        }
        est <- p[["protest_size_estimates"]]
        if (length(est) == 0 || is.null(est[[1]][["text"]])) {
          NA_character_
        } else {
          est[[1]][["text"]]
        }
      }),
      target = map_chr(first_protest, \(p) {
        if (is.null(p) || is.null(p[["target"]])) {
          return(NA_character_)
        }
        paste(unlist(p[["target"]]), collapse = "; ")
      }),
      organizations = map(first_protest, \(p) {
        if (is.null(p)) {
          return(NULL)
        }
        Filter(Negate(is.null), p[["organizations"]])
      }),
      arrests_reported = map_lgl(first_protest, \(p) {
        if (is.null(p)) FALSE else isTRUE(p[["arrests"]][["reported"]])
      }),
      police_present = map_lgl(first_protest, \(p) {
        if (is.null(p)) FALSE else identical(p[["police"]][["present"]], "yes")
      }),
      counterprotestors_reported = map_lgl(first_protest, \(p) {
        if (is.null(p)) {
          FALSE
        } else {
          isTRUE(p[["counterprotestors"]][["reported"]])
        }
      }),
      protester_violence_reported = map_lgl(first_protest, \(p) {
        if (is.null(p)) {
          FALSE
        } else {
          isTRUE(p[["protester_violence"]][["reported"]])
        }
      }),
      keywords = map(first_protest, \(p) {
        if (is.null(p)) {
          return(NULL)
        }
        Filter(Negate(is.null), p[["keywords"]])
      })
    )
  }

  articles_annotated_parsed <- articles_annotated |>
    mutate(
      annotation_json = map_chr(annotation_raw, list("message", "content", 1)),
      annotation_json = map(annotation_json, \(j) {
        try(
          jsonlite::fromJSON(j, silent = TRUE, simplifyVector = FALSE),
          silent = TRUE
        )
      })
    ) |>
    filter(!map_lgl(annotation_json, \(x) methods::is(x, "try-error"))) |>
    mutate(protest_data = parse_annotation(annotation_json)) |>
    unnest_wider(protest_data) |>
    select(-fulltext, -query, -annotation_raw)

  # 4. update data
  update_documents(index = "de-news", documents = articles_annotated_parsed)

  cli::cli_alert_success(
    "{nrow(articles_annotated_parsed)} documents updated [{nrow(articles_annotated) - nrow(articles_annotated_parsed)} failed]."
  )
} else {
  # if there are no documents to process, wait for 10 minutes
  Sys.sleep(10 * 60)
}
