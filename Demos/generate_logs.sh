#!/bin/bash
# Generate realistic-looking web server logs

LOG_FILE="access.log"
> "$LOG_FILE"  # Clear the file

IPS=("192.168.1.10" "192.168.1.25" "10.0.0.5" "172.16.0.100" "192.168.1.10" "10.0.0.5" "192.168.1.10")
METHODS=("GET" "POST" "GET" "GET" "PUT" "DELETE" "GET" "GET" "GET" "POST")
PATHS=("/index.html" "/api/users" "/images/logo.png" "/api/products" "/css/style.css" "/api/users/1" "/about.html" "/api/login" "/api/search?q=test" "/favicon.ico")
CODES=("200" "200" "200" "301" "404" "500" "200" "403" "200" "200" "404" "500" "200" "200")

for i in $(seq 1 200); do
    IP=${IPS[$((RANDOM % ${#IPS[@]}))]}
    METHOD=${METHODS[$((RANDOM % ${#METHODS[@]}))]}
    PATH_=${PATHS[$((RANDOM % ${#PATHS[@]}))]}
    CODE=${CODES[$((RANDOM % ${#CODES[@]}))]}
    SIZE=$((RANDOM % 50000 + 100))
    HOUR=$((RANDOM % 24))
    MIN=$((RANDOM % 60))
    SEC=$((RANDOM % 60))
    printf '%s - - [05/Apr/2026:%02d:%02d:%02d +0000] "%s %s HTTP/1.1" %s %d\n' \
        "$IP" "$HOUR" "$MIN" "$SEC" "$METHOD" "$PATH_" "$CODE" "$SIZE" >> "$LOG_FILE"
done

echo "Generated $(wc -l < "$LOG_FILE") log entries in $LOG_FILE