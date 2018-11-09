library(DBI)
library(RMySQL)
library(stringr)

#### Grab raw bicing data ####
source("bicing_functions.R")

bicing <- get_bicycles()
#####

#### Transform data ####

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

#### Insert into database ####
con <- DBI::dbConnect(RMySQL::MySQL(),
                      host = "178.62.233.233",
                      dbname = "bicing",
                      user = "scraper",
                      password = pw)

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


write_success <- DBI::dbWriteTable(conn = con,
                                   name = "available_bikes",
                                   value = bicing,
                                   append=TRUE,
                                   row.names=FALSE,
                                   overwrite=FALSE,
                                   field.types = field_types)

# If write is a success, print success
if (write_success) print("Append success") else print("No success")

dbDisconnect(con)
#####