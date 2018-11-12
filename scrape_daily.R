library(DBI)
library(RMySQL)
library(stringr)
library(lubridate)

##### Grab raw bicing data ####
source("bicing_functions.R")

bicing <- get_bicycles()
#####

##### Transform data ####

# Split nearbystations string into multiple columns to preserve space
matrix_res <- str_split(bicing[, 'nearbyStations'], ",", simplify = TRUE)
matrix_res[matrix_res == ""] <- NA
df <- as.data.frame(matrix_res)

# Just in case some bicycles change of location and do not have
# 5 stations near by, to preserver robustness let's just always
# have 5 columns even if one is empty. This allows me
# not to worry about the code breaking if the 5th column dissapears
# in the future
if (ncol(df) < 5) {
  cols_left <- 5 - ncol(df)
  to_fill <- matrix(NA, nrow = nrow(df), ncol = cols_left)
  df <- cbind(df, to_fill)
}

if (ncol(df) > 5) {
  df <- df[, 1:5]
}


colnames(df) <- paste0("n_stations_", 1:ncol(df))
df[] <- lapply(df, as.numeric)
bicing <- cbind(bicing, df)

# Exclude repetitive columns
cols <- c("time",
          "year",
          "month",
          "day",
          "id",
          "latitude",
          "longitude",
          "altitude",
          "slots",
          "bikes", 
          "status",
          "n_stations_1",
          "n_stations_2", 
          "n_stations_3",
          "n_stations_4",
          "n_stations_5",
          "error_msg"
)

bicing <- bicing[, cols]


#####

# pw.txt should be a txt file with only the password
# Currently not in the repo but in the server and local computer
pw <- readLines("pw.txt")


##### Connceting to database #####

print("-------------------------------------------------")
print("Starting to connect to database")

con <- DBI::dbConnect(RMySQL::MySQL(),
                      host = "178.62.233.233",
                      dbname = "bicing",
                      user = "scraper",
                      password = pw)

print("-------------------------------------------------")
print("Printing sample of connection")
print(con)


print("-------------------------------------------------")
print("Connected to MySQL database")


field_types <- c(
  time = "DATETIME",
  year = "SMALLINT UNSIGNED",
  month = "TINYINT UNSIGNED",
  day = "TINYINT UNSIGNED",
  id = "INT UNSIGNED",
  latitude = "FLOAT(8, 6)",
  longitude = "FLOAT(8, 6)",
  altitude = "SMALLINT(4)",
  slots = "TINYINT(3) UNSIGNED",
  bikes = "TINYINT(3) UNSIGNED",
  status = "CHAR(4)",
  n_stations_1 = "TINYINT(4) UNSIGNED",
  n_stations_2 = "TINYINT(4) UNSIGNED",
  n_stations_3 = "TINYINT(4) UNSIGNED",
  n_stations_4 = "TINYINT(4) UNSIGNED",
  n_stations_5 = "TINYINT(4) UNSIGNED",
  error_msg  = "TEXT"
)

# Grab date and time to check whether this specific month/day/hour/minute is already present
dt_time <- ymd_hms(bicing$time)[1]

query <- paste0(
" SELECT *
  FROM available_bikes
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
  
  write_bicycle(con)
  
} else {
  # If that date and time is in the database, then it means a year passed by and we want to delete to replace
  # with the new data
  print("-------------------------------------------------")
  print(paste0("The current date and time are in the database. Deleting the date ", dt_time, " and appending new results"))
  
  delete_query <- paste0(
  "DELETE FROM available_bikes
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
########3
#####