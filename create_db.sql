CREATE DATABASE bicing

USE bicing;
-- Create table that contains the stations information in the last month
CREATE TABLE station_information (
    year SMALLINT UNSIGNED,
    month TINYINT UNSIGNED,
    id TINYINT UNSIGNED,
    streetName VARCHAR(100),
    streetNumber VARCHAR(6),
--     PRIMARY KEY (year, month, id),
--     FOREIGN KEY (year, month, id) REFERENCES available_bikes(id)
)

-- Create table that has all the minute-to-minute bike information
CREATE TABLE available_bikes (
	time DATETIME,
	year SMALLINT UNSIGNED,
	month TINYINT UNSIGNED,
	day TINYINT UNSIGNED,
	id TINYINT UNSIGNED,
	latitude FLOAT(3, 6), -- 3 digits to the left and 6 after decimal
	longitude FLOAT(2, 6), -- 2 digits to the left and 6 after decimal,
	altitude SMALLINT(4),
	slots TINYINT(3) UNSIGNED,
	bikes TINYINT(3) UNSIGNED,
	status CHAR(4),
	n_stations_1 TINYINT(4) UNSIGNED,
	n_stations_2 TINYINT(4) UNSIGNED,
	n_stations_3 TINYINT(4) UNSIGNED,
	n_stations_4 TINYINT(4) UNSIGNED,
	n_stations_5 TINYINT(4) UNSIGNED,
	error_msg TEXT
--     PRIMARY KEY (year, month, id),
--     FOREIGN KEY (year, month, id) REFERENCES available_bikes(id)
)

# Grant access to a username from any IP
GRANT ALL PRIVILEGES ON bicing.* TO 'username'@'%' IDENTIFIED BY 'password' WITH GRANT OPTION;