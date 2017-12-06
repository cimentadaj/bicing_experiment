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

# For how to package an api
# http://conjugateprior.org/2017/06/packaging-the-twfy-api/

# to give permission to run scrap
# chmod +x daily_job.sh
# chmod +x scrape_bicing.R

wd <- "/Users/cimentadaj/Downloads/gitrepo/bicing_experiment"
file_path <- file.path(wd, "bicing.rds")

main_data <- read_rds(file_path)

test_url <-
  paste0(
    "http://opendata-ajuntament.barcelona.cat/data/api/3/action/resource_search?query=name:",
    "bicing"
    )

# Repeat every minute for 3 hours
repeat_length <- 60 * 3

iterative_bicing <-
  map_dfr(seq_len(repeat_length), ~ {
  test_bike <- GET(test_url)
  # I think dataset codes are under "code"
  
  bicycle_url <- content(test_bike)$result$results[[1]]$url
  
  bicing <- fromJSON(rawToChar(GET(bicycle_url)$content))$stations
    
  bicing_summary <- bicing[bicing$id == 379, c("id", "slots", "bikes", "status")]
    
  bicing_summary$time <- lubridate::now() + lubridate::hours(1)

  Sys.sleep(60)
  bicing_summary
})

binded_data <-
  bind_rows(main_data, iterative_bicing)

write_rds(binded_data, file_path)

# # 6 hours a days gives 360 rows by 30 days
# (60 * 6) * 30
# 
# # A df with 11k rows is only 0.4 MB, so you can store it on github
# 
# df_large <- map_dfr(1:131400, ~ iterative_bicing[1, ])

# R
# readr::read_rds("bicing.rds")
# quit()
# n
# 
# 
# R
# readr::write_rds(tibble::tibble(), "bicing.rds")
# quit()
# n