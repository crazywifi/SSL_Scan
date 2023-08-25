#!/bin/bash

# Specify input and output file names
input_file="domain_port_file.txt"
csv_output_file="scan_output.csv"

# Read domain-port pairs from the input file and process each one in parallel
xargs -P 10 -I {} ./check_script.sh {} < "$input_file" > "$csv_output_file"

echo "Scan results saved to $csv_output_file"

