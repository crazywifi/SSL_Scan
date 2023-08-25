#!/bin/bash

# This script invokes the check_certificate function

# Function to check certificate expiration
check_certificate() {
    domain_port="$1"
    IFS=":" read -r domain port <<< "$domain_port"
    output=$(openssl s_client -servername "$domain" -connect "$domain":"$port" -showcerts </dev/null 2>/dev/null | openssl x509 -noout -dates)
    if [ $? -eq 0 ]; then
        not_before=$(echo "$output" | grep "notBefore" | cut -d= -f2)
        not_after=$(echo "$output" | grep "notAfter" | cut -d= -f2)

        today=$(date +%s)
        not_after_unix=$(date -d "$not_after" +%s)

        if [ "$today" -gt "$not_after_unix" ]; then
            status="Expired"
        else
            status="Not Expired"
        fi

        not_before_converted=$(convert_date_format "$not_before")
        not_after_converted=$(convert_date_format "$not_after")

        echo "$domain,$port,$not_before_converted,$not_after_converted,$status"
    else
        echo "$domain,$port,ERROR,ERROR,Certificate Error"
    fi
}

# Function to convert date format
convert_date_format() {
    input_date="$1"
    new_date=$(date -d "$input_date" "+%e-%m-%Y")
    echo "$new_date"
}

# Invoke the check_certificate function
check_certificate "$1"

