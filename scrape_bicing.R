library(httr)
library(jsonlite)
library(DBI)
library(tidyverse)

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

# Bcn time
current_time <- as.character(lubridate::now())

# If there's an error, return an empty df with the error in the error column
print(safe_request$error)

if (!is.null(safe_request$error)) {
  
  summary_bicing <-
    tibble(id = station,
           slots = NA,
           bikes = NA,
           status = NA,
           time = current_time,
           error_msg = as.character(safe_request$error))
  
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
             error_msg = "Station not available")
    
    summary_bicing
  } else {
    
    summary_bicing <- bicing[station_there, c("id", "slots", "bikes", "status")]
    
    print(paste0("Dim after subsetting station: ", dim(summary_bicing)))
    summary_bicing$time <- current_time
    summary_bicing$error_msg <- NA
    print(paste0("Dim after time and error vars: ", dim(summary_bicing)))
    
    summary_bicing
  }
}

# Get password from pw.txt, also used from the scheduele MySQL query
pw <- readLines("pw.txt")

# Connect to the database
con <- dbConnect(RMySQL::MySQL(),
                 dbname = "bicing",
                 user = "cimentadaj",
                 password = pw,
                 port = 3306)

# Append the API request df to the bicing_station table from the database
write_success <-
  dbWriteTable(conn = con, "bicing_station", summary_bicing,
               append = TRUE, row.names = FALSE)

# If write is a success, print success
if (write_success) print("Append success") else print("No success")