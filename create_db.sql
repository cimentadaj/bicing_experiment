CREATE DATABASE bicing

USE bicing;

-- Grant access to a username from any IP
-- The % means that it accepts any IP
CREATE USER 'username'@'%' IDENTIFIED BY 'password';
GRANT ALL PRIVILEGES ON bicing.* TO 'username'@'%' IDENTIFIED BY 'password' WITH GRANT OPTION;
