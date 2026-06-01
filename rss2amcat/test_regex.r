library(stringr)
rgx <- "protest|demonstr"
str_detect(
  c(
    "Klimaprotest",
    "protest",
    "Demonstration",
    "Demonstranten",
    "Protestierende"
  ),
  regex(rgx, ignore_case = TRUE)
)
