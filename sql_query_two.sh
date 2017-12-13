read PASS < pw.txt # pw.txt should be a txt file with only the password
mysql -uroot -p$PASS bicing -e "SELECT id, error_msg, COUNT(*) AS count FROM bicing_station WHERE time >= CONCAT(CURDATE(),' ','20:00:00') AND time <= CONCAT(CURDATE(),' ','21:01:00') GROUP BY id, error_msg;"
