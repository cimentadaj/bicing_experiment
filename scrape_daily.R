library(DBI)
library(RMySQL)
library(stringr)
library(lubridate)

##### Grab raw bicing data ####
source("bicing_functions.R")

bicing <- get_bicycles()

#####

# pw.txt should be a txt file with only the password
# Currently not in the repo but in the server and local computer
pw <- readLines("pw.txt")

##### Connceting to database #####

print("-------------------------------------------------")
print("Starting to connect to database")

con <- DBI::dbConnect(RMySQL::MySQL(),
                      host = "0.0.0.0",
                      dbname = "bicing",
                      user = "scraper",
                      password = pw)

print("-------------------------------------------------")
print("Printing sample of connection")
print(con)

print("-------------------------------------------------")
print("Connected to MySQL database")

field_types <- c(
  id_hash = "TEXT",
  id = "INT UNSIGNED",
  latitude = "FLOAT(8, 6)",
  longitude = "FLOAT(8, 6)",
  address = "TEXT",
  slots = "TINYINT(3) UNSIGNED",
  empty_slots = "TINYINT(3) UNSIGNED",
  free_bikes = "TINYINT(3) UNSIGNED",
  ebikes = "TINYINT(3) UNSIGNED",
  has_ebikes = "BOOLEAN",
  status = "BOOLEAN",
  time = "DATETIME",
  day = "TINYINT UNSIGNED",
  month = "TINYINT UNSIGNED",
  year = "SMALLINT UNSIGNED",
  error_msg  = "TEXT"
)

# Grab date and time to check whether this specific month/day/hour/minute is already present
dt_time <- ymd_hms(bicing$time)[1]

query <- paste0(
" SELECT *
  FROM bicing_stations
  WHERE MONTH(time) = ", month(dt_time), "
        AND DAY(time) = ", day(dt_time), "
        AND HOUR(time) = ", hour(dt_time), "
        AND MINUTE(time) = ", minute(dt_time), "
  LIMIT 10
")

res <- DBI::dbGetQuery(con, query)

print("-------------------------------------------------")
print("Checking that the current month/date/hour/minute is not in the database")

# If there is NOT a month/day/hour/minute then it means that a YEAR HAS NOT passed by and we're
# only working with a 1 year rolling windows
if (nrow(res) == 0) {
  print("-------------------------------------------------")
  print("The current date and time are not in the database. Appending results")

  write_bicycle(con, bicing, field_types)

} else {

  # If that date and time is in the database, then it means a year passed by and we want to delete to replace
  # with the new data
  print("-------------------------------------------------")
  print(paste0("The current date and time are in the database. Deleting the date ", dt_time, " and appending new results"))

  delete_query <- paste0(
  "DELETE FROM bicing_stations
   WHERE MONTH(time) = ", month(dt_time), "
         AND DAY(time) = ", day(dt_time), "
         AND HOUR(time) = ", hour(dt_time), "
         AND MINUTE(time) = ", minute(dt_time), "
  "
  )

  DBI::dbSendStatement(con, delete_query)
  print("-------------------------------------------------")
  print("The current date and time were deleted from the database")


  write_bicycle(con)
}

print("-------------------------------------------------")
print("Printing warnings for traceback")
print(warnings())


dbDisconnect(con)
########
########
