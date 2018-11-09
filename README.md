
This guide is OUTDATE. New guide coming soon.

## Setting up the data base

This is a short tutorial on the steps I had to take to setup a database
on my remote server and connect both from my local computer as well as
from my server.

This worked for my Digital Ocean droplet 512 MB and 20 GB disk with
Ubuntu 16.04.3 x64.

It’s better to do *ALL* of this as a user in your server but remember to
append `sudo` to everything. Nonetheless, beware of problems like the
ones I encountered. For example, when installing R packages that where
ran by `cron` in a script, if installed through a non-root user the
packages were said to be `'not installed'` (when I fact running the
script separately was fine). However, when I installed the packages
logged in as root the packages were installed successfully.

All steps:

  - [Install
    R](https://www.digitalocean.com/community/tutorials/how-to-install-r-on-ubuntu-16-04-2)

  - [Install
    MySQL](https://www.digitalocean.com/community/tutorials/how-to-install-mysql-on-ubuntu-16-04)

  - Type `mysql -u root -p` to log in to MySQL

  - Follow these steps to create an empty table within a database

<!-- end list -->

``` sql
CREATE DATABASE bicing;
USE bicing;
CREATE TABLE bicing_station (id VARCHAR(30), slots VARCHAR(30), bikes VARCHAR(30), status VARCHAR(30), time VARCHAR(30), error VARCHAR(30));
```

  - [This](https://www.digitalocean.com/community/tutorials/how-to-set-up-a-remote-database-to-optimize-site-performance-with-mysql)
    is an outdated guide by Digital Ocean which might be helpful. Some
    of the steps below are taken from that guide.

  - Alter `sudo nano /etc/mysql/mysql.conf.d/mysqld.cnf` and change
    `bind-address` to have the ‘0.0.0.0’ This is so your server can
    listen to IP’s from outside the localhost network.

  - Create two users to access the data base: a user from your local
    computer and a user from your
server.

<!-- end list -->

``` bash
mysql -u root -p # Log in to MySQL. -u stands for user and -p for password
```

``` sql
/* Create user for local computer. Note that when username and ip are in '' they need to be in those quotes. Also, the ip address you can find easily by writing what's my ip in Google*/

CREATE USER 'username'@'ip_address_of_your_computer' IDENTIFIED BY 'password';
GRANT ALL ON bicing.* TO username@ip_address_of_your_computer;

/* Create user for server. For this user don't change localhost as that already specifies that it belongs to the same computer. */

CREATE USER 'username'@'localhost' IDENTIFIED BY 'password';
GRANT ALL ON bicing.* TO username@localhost;

/* Make sure the privileges are isntalled */
FLUSH PRIVILEGES;

quit /* To quit MySQL*/
```

  - Test whether the access worked for both users

<!-- end list -->

``` bash
# Login from your server. Replace username for your username 
# -u stands for user and -p will ask for your password 
mysql -u username -h localhost -p


# Login from your LOCAL computer. Replace username for your username and your_server_ip from the server's IP
mysql -u username -h your_server_ip -p
```

  - Now install `odbc` in your Ubuntu server. I follow
    [this](I%20followed%20this:%20https://askubuntu.com/questions/800216/installing-ubuntu-16-04-lts-how-to-install-odbc)

<!-- end list -->

``` bash
sudo mkdir mysql && cd mysql

# Download odbc in mysql folder
sudo wget https://dev.mysql.com/get/Downloads/Connector-ODBC/5.3/mysql-connector-odbc-5.3.9-linux-ubuntu16.04-x86-64bit.tar.gz

# Unzip it and copy it somewhere.
sudo tar -xvf mysql-connector-odbc-5.3.9-linux-ubuntu16.04-x86-64bit.tar.gz 
sudo cp mysql/mysql-connector-odbc-5.3.9-linux-ubuntu16.04-x86-64bit/lib/libmyodbc5a.so /usr/lib/x86_64-linux-gnu/odbc/
# If the odbc folder doesn't exists, create it with mkdir /usr/lib/x86_64-linux-gnu/odbc/
```

Note: you might need to change the url’s and directories to a **newer**
version of `odbc` so don’t simply copy and paste the links from below.

  - Create and update the `odbc` settings.

<!-- end list -->

``` bash
sudo touch /etc/odbcinst.ini

sudo nano /etc/odbcinst.ini

# And add

[MySQL Driver]
Description = MySQL
Driver = /usr/lib/x86_64-linux-gnu/odbc/libmyodbc5a.so
Setup = /usr/lib/x86_64-linux-gnu/odbc/libodbcmyS.so
FileUsage = 1

# close the nano
# And continue

sudo touch /etc/odbc.ini

sudo nano /etc/odbc.ini

# and add

[MySQL]
Description           = MySQL connection to database
Driver                = MySQL Driver
Database              = dbname
Server                = 127.0.0.1
User                  = root
Password              = password
Port                  = 3306
Socket                = /var/run/mysqld/mysqld.sock

# Change Database to your database name
# The password to your root password

# Finally, run

sudo ln -s /var/run/mysqld/mysqld.sock /tmp/mysql.sock

# to move the socket to the folder where the DBI pkgs
# search for it

# Finish by

sudo service mysql restart;

# to restart mysql server
```

## Connecting to the database locally and remotely

From my local computer:

``` r
library(DBI)
library(RMySQL)

con <- dbConnect(MySQL(), # If the database changed, change this
                 host = your_server_ip, # in "" quotes.
                 dbname = "bicing",
                 user = username, # remember to change to your username (in quotes)
                 password = password, # remember to change to your password (in quotes)
                 port = 3306)

dbListTables(con)

bike_stations <- dbReadTable(con, "bicing_station")
```

From R in the server

``` r
con <- dbConnect(RMySQL::MySQL(),
                 dbname = "bicing",
                 user = username, # remember to change to your username (in quotes)
                 password = password, # remember to change to your password (in quotes)
                 port = 3306)

dbListTables(con)

bike_stations <- dbReadTable(con, "bicing_station")
```

That did it for me. Now I could connect to the database from R from my
local computer and from the server itself.

## Scraping automatically

So far you should have a database in your server which you can connect
locally and remotely. I assume you have a working script that can
actually add/retrieve information from the remote database. Here I will
explain how to set up the scraping to run automatically as a `cron` job
and get a final email with the summary of the scrape.

  - Create a text file to save the output of the scraping with `sudo
    touch scrape_log.txt`

  - Write `cron -e` logged in as your non-root user.

  - At the bottom of the interactive `cron` specify these
options:

<!-- end list -->

``` bash
SHELL=/bin/bash # the path to the predetermined program to run cron jobs. Default bash

PATH=bla/bla/bla # PATH I’m not sure what’s for but I pasted the output of echo $PATH.

HOME= your/dr/ofinteres # Path to the directory where the scripts will be executed (where the script is)

MAILTO="your@email.com" # Your email to receive emails

# The actual cron jobs. Below each job I explain them
30-59 11 * * * /usr/bin/Rscript scrape_bicing.R >>scrape_log.txt 2>&1

# Run this cron job from 11:30 to 11:59 every day (*), every month (*), every year(*): 30-59 11 * * *

# Use R to run the script: /usr/bin/Rscript
# You can find this directory with which Rscript

# Execute the file scrape_bicing.R (which is looked for in the HOME variable specified above)
# >>scrape_log.txt 2>&1: Save the output to scrape_log.txt (which we created) and DON'T send an email
# because we don't want to received 29 emails.

00 12 * * * /bin/bash sql_query.sh
# Instead of receiving 29 emails, run a query the minute after the scraping ends
# to filter how many rows were added between 11:30 and 11:59
# By default it will send the result of the query to your email
```

Great but what does `scrape_bicing.R` have?

The script should do something along the lines of:

``` r
# Load libraries
library(httr)
library(DBI)
library(RMySQL)

# The url of your api
api_url <- "bla/bla"

# Wrap GET so that whenever the request fails it returns an R error
my_GET <- function(x, config = list(), ...) {
  stop_for_status(GET(url = x, config = config, ...))
}

# If it can't connect to the API will throw an R error
test_bike <- my_GET(api_url)


## Do API calls here
## I assume the result is a data.frame or something like that
## It should have the same column names as the SQL database.

# Establish the connection to the database.
# This script is run within the server, so the connection
# should not specify the server ip, it assumes it's
# the localhost

con <- dbConnect(MySQL(),
                 dbname = database_name, # in "" quotes
                 user = your_user, # in "" quotes
                 password = your_password, # in "" quotes
                 port = 3306)

# Append the table
write_success <-
  dbWriteTable(conn = con, # connection from above
              "table name", # name of the table to append (in quotes)
              api output, # data frame from the API output
              append = TRUE, row.names = FALSE) # to append instead of overwrite and ignore row.names

# Write your results to the database. In my API call
# I considered many possible errors and coded the request
# very defensively, running the script many times under certain
# scenarios (no internet, getting different results).
# If you get unexpected results from your API request then this step will
# not succeed.


# If the append was successfull, write_success should be TRUE
if (write_success) print("Append success") else print("No success")
```

Something to keep in mind, by default you can connect from the your
local computer to the remote DB by port 3306. This port can be closed if
you’re in a public internet network or a network connection from a
university. If you can’t connect, make you sort this out with the
personnel from that network (it happened to me with my university
network).

What does `sql_query.sh` have?

A very simple SQL
query:

``` sql
read PASS < pw.txt /* Read the password from a pw.txt file you create with your user pasword*/

mysql -uroot -p$PASS database_name -e "SELECT id, error_msg, COUNT(*) AS count FROM bicing_station WHERE time >= CONCAT(CURDATE(),' ','11:30:00') AND time <= CONCAT(CURDATE(),' ','12:00:00') GROUP BY id, error_msg;"

/*
mysql: run mysql

-uroot: specify your mysql username (note there are no spaces)

-p$PASS: -p is for password and $PASS is the variable with the password

database_name: is the data base name

-e: is short for -execute a query

The remaining is the query to execute. I would make sure the query
works by running this same line in the server interactively.

What this query means is to get the counts of the id and error messages
where the time is between the scheduele cron of the API request.

This way I get a summary of the error messages and how many lines were
appended between the time the script should've started and should've ended
*/
```

As stated in the first line of the code chunk, create a text file with
your password. You can do so with `echo "Your SQL username password" >>
pw.txt`. That should allow PASS to read in the password just fine.

And that should be it\! Make sure you run each of these steps separately
so that they work on it’s own and you don’get weird errors. This
workflow will now run `cron` jobs at whatever time you set it, return
the output to a text file (in case something bad happens and you want to
look at the log) and run a query after it finishes so that you only get
one email with a summary of API requests.

Hope this was helpful\!

PS:

  - [Basic MySQL
    tutorial](https://www.digitalocean.com/community/tutorials/a-basic-mysql-tutorial)

  - I use SQL Workbench to run queries from my local computer
