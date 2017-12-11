library(httr)
library(jsonlite)
library(DBI)
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

# wd <- "/home/cimentadaj/bicycle"

test_url <-
  paste0(
    "http://opendata-ajuntament.barcelona.cat/data/api/3/action/resource_search?query=name:",
    "bicing"
  )

# Repeat every minute for 3 hours
station <- "379"

# Wrap GET so that whenever there's a 404 it returns an R error
my_GET <- function(x, config = list(), ...) {
  stop_for_status(GET(url = x, config = config, ...))
}

# If it can't connect to the bicing API will throw an error
test_bike <- my_GET(test_url)
bicycle_url <- content(test_bike)$result$results[[1]]$url

# turn that my_GET so that if there's an error the computation doesn't stop
# but changes the result based on that error
safe_GET <- safely(my_GET)


safe_request <- safe_GET(bicycle_url)

# Bcn time (+1 because the server is in amsterdam)
current_time <- as.character(lubridate::now() + lubridate::hours(1))

# If there's an error, return an empty df with the error in the error column
print(safe_request$error)

if (!is.null(safe_request$error)) {
  
  summary_bicing <-
    tibble(id = station,
           slots = NA,
           bikes = NA,
           status = NA,
           time = current_time,
           error = as.character(safe_request$error))
  
} else {
  
  bicing <- fromJSON(rawToChar(safe_request$result$content))$stations
  print(paste0("Dim of whole bicing df: ", dim(bicing)))
  
  station_there <- bicing$id == station
  
  # If the station is not there, return an empty tibble()
  if (!any(station_there)) {
    print("Station not available!")
    summary_bicing <-
      tibble(id = station,
             slots = NA,
             bikes = NA,
             status = NA,
             time = current_time,
             error = "Station not available")
    
    summary_bicing
  } else {
    
    summary_bicing <- bicing[station_there, c("id", "slots", "bikes", "status")]
    
    print(paste0("Dim after subsetting station: ", dim(summary_bicing)))
    summary_bicing$time <- current_time
    summary_bicing$error <- NA
    print(paste0("Dim after time and error vars: ", dim(summary_bicing)))
    
    summary_bicing
  }
}

con <- dbConnect(RMySQL::MySQL(),
                 dbname = "bicing",
                 user = "cimentadaj",
                 password = "Lolasouno2",
                 port = 3306)

# dbListTables(con)

# main_data <- as_tibble(dbReadTable(con, "bicing_station"))


# binded_data <-
#   bind_rows(main_data, summary_bicing)

write_success <-
  dbWriteTable(conn = con, "bicing_station", summary_bicing,
               append = TRUE, row.names = FALSE)

# # 6 hours a days gives 360 rows by 30 days
# (60 * 6) * 30
# 
# # A df with 11k rows is only 0.4 MB, so you can store it on github
# 
# df_large <- map_dfr(1:131400, ~ iterative_bicing[1, ])

if (write_success) print("Append success") else print("No success")