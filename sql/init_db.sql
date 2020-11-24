
CREATE DATABASE bicing;
CREATE USER 'cimentadaj'@'%' IDENTIFIED WITH mysql_native_password BY '123';
GRANT ALL ON bicing.* TO 'cimentadaj'@'%';
CREATE USER 'scraper'@'localhost' IDENTIFIED WITH mysql_native_password BY '123';
GRANT ALL ON bicing.* TO 'scraper'@'localhost';

/* Make sure the privileges are installed */
FLUSH PRIVILEGES;

USE bicing;

CREATE TABLE bicing_stations (
   id_hash VARCHAR(30),
   id VARCHAR(30),
   latitude VARCHAR(30),
   longitude VARCHAR(30),
   address VARCHAR(30),
   slots VARCHAR(30),
   empty_slots VARCHAR(30),
   free_bikes VARCHAR(30),
   ebikes VARCHAR(30),
   has_ebikes VARCHAR(30),
   status VARCHAR(30),
   time VARCHAR(30),
   day VARCHAR(30),
   month VARCHAR(30),
   year VARCHAR(30),
   error_msg VARCHAR(30)
);


CREATE DATABASE bicing;
CREATE USER 'whatever1'@'%' IDENTIFIED WITH mysql_native_password BY '123';
GRANT ALL ON bicing.* TO 'cimentadaj'@'%';
CREATE USER 'whatever2'@'localhost' IDENTIFIED WITH mysql_native_password BY '123';
GRANT ALL ON bicing.* TO 'scraper'@'localhost';

/* Make sure the privileges are installed */
FLUSH PRIVILEGES;

USE bicing;

CREATE TABLE bicing_stations (
   id_hash VARCHAR(30),
   id VARCHAR(30),
   latitude VARCHAR(30),
   longitude VARCHAR(30),
   address VARCHAR(30),
   slots VARCHAR(30),
   empty_slots VARCHAR(30),
   free_bikes VARCHAR(30),
   ebikes VARCHAR(30),
   has_ebikes VARCHAR(30),
   status VARCHAR(30),
   time VARCHAR(30),
   day VARCHAR(30),
   month VARCHAR(30),
   year VARCHAR(30),
   error_msg VARCHAR(30)
);

