read PASS < pw.txt
mysql -uroot -p$PASS bicing -e "SELECT id, error_msg, COUNT(*) AS count FROM bicing_station WHERE time >= CONCAT(CURDATE(),' ','15:00:00') AND time <= CONCAT(CURDATE(),' ','16:01:00') GROUP BY id, error_msg;"
