library(httr)
library(jsonlite)
library(purrr)
library(lubridate)

# Wrap GET so that whenever there's a 404 it returns an R error
get_resp <- function(url, attempts_left = 5, ...) {
  
  resp <- httr::GET(url, ...)
  
  # On a successful GET, return the response's content
  if (httr::status_code(resp) == 200) {
    
    # Ensure that returned response is application/json
    if (httr::http_type(resp) != "application/json") {
      stop("The API returned an unusual format and not a JSON", call. = FALSE)
    }
    
    resp
  } else if (attempts_left == 0) { # When attempts run out, stop with an error
    
    print("Stopped trying to connect to API. 0 attempts left")
    print("-------------------------------------------------")
    httr::stop_for_status(resp) # Return appropiate error message
    
  } else { # Otherwise, sleep a second and try again
    
    Sys.sleep(3)
    print(paste0("Cannot connect to API. Getting status_code: ", httr::status_code(resp)))
    print(paste0(attempts_left, " attempts left"))
    get_resp(url, attempts_left - 1)
    
  }
}

get_bicycles <- function() {
  bicing_url <- "http://wservice.viabicing.cat/v2/stations"
  
  # If it can't connect to the bicing API will throw an error
  bicing_response <- safely(get_resp)(bicing_url)
  
  # If this is the time of the server, then it's a problem because
  # it needs to be converted to Barcelona time. I think I had to
  # convert the time to Barcelona time at some point.
  current_time <- as.character(lubridate::now())
  
  bicing_empty <-
    data.frame(
      id = NA,
      type = NA,
      latitude = NA,
      longitude = NA,
      streetName = NA,
      streetNumber = NA,
      altitude = NA,
      slots = NA,
      bikes = NA,
      nearbyStations = NA,
      status = NA,
      time = NA,
      error_msg = NA,
      year = NA,
      month = NA,
      day = NA
    )
  
  # If error in connecting to API return empty df with error message
  if (!is.null(bicing_response$error)) {
    bicing_empty$error_msg <- as.character(bicing_response$error)
    bicing_empty$time <- current_time
    return(bicing_empty)
  }
  
  bicing <- fromJSON(rawToChar(bicing_response$result$content))$stations
  
  # If bicing data frame has few rows, somethings wrong. It should have over 400 rows.
  if (nrow(bicing) < 2) {
    bicing_empty$error_msg <- "Bicing data frame has less than 2 rows. Probably wrong"
    bicing_empty$time <- current_time
    return(bicing_empty)
  }
  
  bicing$time <- current_time
  bicing$error_msg <- NA
  
  # Turn these strings into numerics because they occupe less space as doubles
  bicing$id <- as.numeric(bicing$id)
  bicing$year <- year(ymd_hms(bicing$time))
  bicing$month <- month(ymd_hms(bicing$time))
  bicing$day <- day(ymd_hms(bicing$time))
  
  
  bicing$latitude <- as.numeric(bicing$latitude)
  bicing$longitude <- as.numeric(bicing$longitude)
  bicing$altitude <- as.numeric(bicing$altitude)
  bicing$slots <- as.numeric(bicing$slots)
  bicing$bikes <- as.numeric(bicing$bikes)  
  
  bicing
}