Setup MySQL DB
================
Jorge Cimentada
12/11/2017

This is a short tutorial on the steps I had to take to setup a database on my remote server and connect both from my local computer as well as from my server.

This worked for my Digital Ocean droplet 512 MB and 20 GB disk with Ubuntu 16.04.3 x64.

It's better to do *ALL* of this as root because I sometimes forgot to write `sudo` and many of the things I installed were raising errors. For example, when installing R packages that where ran by `cron` in a script, if installed through a non-root user the packages were said to be `'not installed'` (when I fact running the script separately was fine). However, when I installed the packages loggin in as root the packages were installed successfully.

All steps:

-   [Install R](https://www.digitalocean.com/community/tutorials/how-to-install-r-on-ubuntu-16-04-2)

-   [Install MySQL](https://www.digitalocean.com/community/tutorials/how-to-install-mysql-on-ubuntu-16-04)

-   Type `mysql -u root -p` to log in to MySQL

-   Follow these steps to create an empty table within a database

<!-- -->

    CREATE DATABASE bicing;
    USE bicing;
    CREATE TABLE bicing_station (id VARCHAR(30), slots VARCHAR(30), bikes VARCHAR(30), status VARCHAR(30), time VARCHAR(30), error VARCHAR(30));

-   [This](https://www.digitalocean.com/community/tutorials/how-to-set-up-a-remote-database-to-optimize-site-performance-with-mysql) is an outdated guide by Digital Ocean which might be helpful. Some of the steps below are taken from that guide.

-   Alter `sudo nano /etc/mysql/mysql.conf.d/mysqld.cnf` and change `bind-address` to have the '0.0.0.0' This is so your server can listen to IP's from outside the localhost network.

-   Create two users to access the data base: a user from your local computer and a user from your server.

[This](#%20https://www.digitalocean.com/community/tutorials/how-to-create-a-new-user-and-grant-permissions-in-mysql) is a Digital Ocean tutorial to create and grant access to new users. Some of the steps below are taken from that guide.

    mysql -u root -p /* Log in to MySQL */

    /* Create user for local computer. Note that when username and ip are in '' they need to be in those quotes. Also, the ip address you can find easily by writing what's my ip in Google*/

    CREATE USER 'username'@'ip_address_of_your_computer' IDENTIFIED BY 'password';
    GRANT ALL ON bicing.* TO username@ip_address_of_your_computer;

    /* Create user for server. For this user don't change localhost as that already specifies that it belongs to the same computer. */

    CREATE USER 'username'@'localhost' IDENTIFIED BY 'password';
    GRANT ALL ON bicing.* TO username@localhost;

    /* Make sure the privileges are isntalled */
    FLUSH PRIVILEGES;

    quit /* To quit MySQL*/

-   Test whether the access worked for both users

<!-- -->

    /* Login from your server. Replace username for your username */
    mysql -u username -h localhost -p


    /* Login from your LOCAL computer. Replace username for your username and your_server_ip from the server's IP */
    mysql -u username -h your_server_ip -p

-   Now install `odbc` in your Ubuntu server. I follow [this](I%20followed%20this:%20https://askubuntu.com/questions/800216/installing-ubuntu-16-04-lts-how-to-install-odbc)

Note: you might need to change the url's and directories to a **newer** version of `odbc` so don't simply copy and paste the links from below.

``` bash
sudo mkdir mysql && cd mysql

# Download odbc in mysql folder
sudo wget https://dev.mysql.com/get/Downloads/Connector-ODBC/5.3/mysql-connector-odbc-5.3.9-linux-ubuntu16.04-x86-64bit.tar.gz

# Unzip it and copy it somewhere.
sudo tar -xvf mysql-connector-odbc-5.3.9-linux-ubuntu16.04-x86-64bit.tar.gz 
sudo cp mysql/mysql-connector-odbc-5.3.9-linux-ubuntu16.04-x86-64bit/lib/libmyodbc5a.so /usr/lib/x86_64-linux-gnu/odbc/
# If the odbc folder doesn't exists, create it with mkdir /usr/lib/x86_64-linux-gnu/odbc/
```

-   Create and update the `odbc` settings.

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

ln -s /var/run/mysqld/mysqld.sock /tmp/mysql.sock

# to move the socket to the folder where the DBI pkgs
# search for it

# Finish by

sudo service mysql restart;

# to restart mysql server
```

That did it for me. Now I could connect to the database from R from my local computer and from the server itself. Remember to change some of the arguments from below.

From my local computer:

``` r
library(DBI)
library(RMySQL)

con <- dbConnect(MySQL(), # If the database changed, change this
                 host = your_server_ip,
                 dbname = "bicing",
                 user = username,
                 password = password,
                 port = 3306)

dbListTables(con)

bike_stations <- dbReadTable(con, "bicing_station")
```

From R in the server

``` r
con <- dbConnect(RMySQL::MySQL(),
                 dbname = "bicing",
                 user = username,
                 password = password,
                 port = 3306)

dbListTables(con)

bike_stations <- dbReadTable(con, "bicing_station")
```

-   [Basic MySQL tutorial](https://www.digitalocean.com/community/tutorials/a-basic-mysql-tutorial)
