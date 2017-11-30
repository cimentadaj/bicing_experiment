library(httr)
library(jsonlite)
library(tidyverse)


# # grab the list of datasets from the API
# open_data <-
#   GET("http://opendata-ajuntament.barcelona.cat/data/api/3/action/package_list",
#       config = list(`content-type` = "application/json"))
# 
# # Grab the names to identify the bicing data
# data_names <-
#   content(open_data)[-c(1, 2)] %>%
#   .[[1]] %>%
#   as.character()
# 
# 
# bicycle_names <-
#   data_names %>%
#   map_lgl(~ grepl("bic", .x)) %>%
#   data_names[.]

test_url <-
  paste0(
    "http://opendata-ajuntament.barcelona.cat/data/api/3/action/resource_search?query=name:",
    "bicing"
    )



iterative_bicing <-
  map(1:5, ~ {
  test_bike <- GET(test_url)
  # I think dataset codes are under "code"
  
  bicycle_url <- content(test_bike)$result$results[[1]]$url
  
  bicing <-
    bicycle_url %>%
    GET() %>%
    .$content %>%
    rawToChar() %>%
    fromJSON() %>%
    .$stations %>%
    select(id, slots, bikes, status) %>%
    filter(id == 379) %>%
    mutate(time = lubridate::now())
  
  Sys.sleep(5)
  bicing
})
