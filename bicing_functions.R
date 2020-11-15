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

write_bicycle <- function(conn) {
  print("-------------------------------------------------")
  print("Attempting to write results to available_bikes")

  write_success <- DBI::dbWriteTable(conn = conn,
                                     name = "available_bikes",
                                     value = bicing,
                                     append = TRUE,
                                     row.names = FALSE,
                                     overwrite = FALSE,
                                     field.types = field_types)

  print("-------------------------------------------------")
  if (write_success) print("Successfully wrote to available_bikes") else print("Could not write to available_bikes") #nolintr
}

get_bicycles <- function() {
  print("-------------------------------------------------")
  print("Grabbing bicing data")

  bicing_url <- "http://api.citybik.es/v2/networks/bicing?fields=stations"

  # If it can't connect to the bicing API will throw an error
  bicing_response <- safely(get_resp)(bicing_url)

  # UTC for country-agnostic time zone
  current_time <- lubridate::now(tzone = "UTC")

  col_order <-
    c(
      "id_hash",
      "id",
      "latitude",
      "longitude",
      "address",
      "slots",
      "empty_slots",
      "free_bikes",
      "ebikes",
      "has_ebikes",
      "status",
      "time",
      "day",
      "month",
      "year",
      "error_msg"
    )

  bicing_empty <- as.data.frame(setNames(lapply(col_order, function(x) NA), col_order))

  # If error in connecting to API return empty df with error message
  if (!is.null(bicing_response$error)) {
    bicing_empty$error_msg <- as.character(bicing_response$error)
    bicing_empty$time <- current_time
    return(bicing_empty)
  }

  chr_dt <- rawToChar(bicing_response$result$content)
  bicing <- fromJSON(chr_dt, flatten = TRUE)$network$stations
  names(bicing) <- gsub("extra.", "", names(bicing))
  bicing$slots <- with(bicing, empty_slots + free_bikes)
  bicing <- within(bicing, {
    id_hash <- id
    id <- NULL
    address <- name
    name <- NULL
    time <- current_time
    timestamp <- NULL
    id <- uid
    uid <- NULL
    status <- online
    online <- NULL
  })

  bicing$error_msg <- NA

  # Turn these strings into numerics because they occupe less space as doubles
  bicing <-
    within(bicing, {
      year <- year(time)
      month <- month(time)
      day <- day(time)
    })

  bicing <- bicing[col_order]

  # If bicing data frame has few rows, somethings wrong. It should have over 400
  # rows.
  if (nrow(bicing) < 2) {
    bicing_empty$error_msg <- "Bicing data frame has less than 2 rows. Probably wrong" #nolintr
    bicing_empty$time <- current_time
    return(bicing_empty)
  }


  print("-------------------------------------------------")
  print("Printing sample of bicing data")
  print(head(bicing))

  print("-------------------------------------------------")
  print("Bicing data returned")

  bicing
}
