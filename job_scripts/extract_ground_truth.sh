#!/bin/bash

# Check arguments
if [ "$#" -ne 3 ]; then
    echo "Usage: $0 first.paf second.paf output.paf"
    exit 1
fi

first_paf="$1"
second_paf="$2"
output_paf="$3"

# Extract read IDs from first.paf and filter second.paf
awk 'NR==FNR { ids[$1]; next } $1 in ids' <(cut -f1 "$first_paf" | sort | uniq) "$second_paf" > "$output_paf"

