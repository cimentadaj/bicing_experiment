library(DBI)
library(RMySQL)

source("bicing_functions.R")

bicing <- get_bicycles()

# Keep important columns that match station information to the minute-to-minute requests
station_variables <- c("year", "month", "id", "streetName", "streetNumber")


bicing <- bicing[, station_variables]

# pw.txt should be a txt file with only the password
# Currently not in the repo but in the server and local computer
pw <- readLines("pw.txt")

#### Insert into database ####
con <- dbConnect(MySQL(),
                 host = "178.62.233.233",
                 dbname = "bicing",
                 user = "scraper",
                 password = pw)

field_types <- c(
  year  = "SMALLINT UNSIGNED",
  month = "TINYINT UNSIGNED",
  id = "INT UNSIGNED",
  streetName = "VARCHAR(100)",
  streetNumber = "VARCHAR(10)"
  )


write_success <- DBI::dbWriteTable(conn = con,
                                   name = "station_information",
                                   value = bicing,
                                   append=TRUE,
                                   row.names=FALSE,
                                   overwrite=FALSE,
                                   field.types = field_types)

# If write is a success, print success
if (write_success) print("Append success") else print("No success")

dbDisconnect(con)
