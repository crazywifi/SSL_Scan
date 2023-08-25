#!/bin/bash

# Specify input and output file names
input_file="domain_port_file.txt"
csv_output_file="scan_output.csv"

# Function to convert date format
convert_date_format() {
    input_date="$1"
    new_date=$(date -d "$input_date" "+%e-%m-%Y")
    echo "$new_date"
}

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

        echo "$domain,$port,$not_before_converted,$not_after_converted,$status" >> "$csv_output_file"
        echo "Domain: $domain, Status: $status"
    else
        echo "$domain,$port,ERROR,ERROR,Certificate Error" >> "$csv_output_file"
        echo "Domain: $domain, Status: Certificate Error"
    fi
}

# Create or truncate the CSV output file and add headers
echo "Domain,Port,NotBefore,NotAfter,Status" > "$csv_output_file"

# Read domain-port pairs from the input file and process each one
while IFS= read -r line; do
    trimmed_line=$(echo "$line" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
    echo "Processing domain: $trimmed_line"
    check_certificate "$trimmed_line"
done < "$input_file"

echo "Scan results saved to $csv_output_file"

