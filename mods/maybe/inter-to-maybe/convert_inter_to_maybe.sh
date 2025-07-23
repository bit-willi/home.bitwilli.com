#!/bin/bash

# Usage: ./convert_inter_to_maybe.sh input.csv output.csv
# Converts a CSV file from Inter bank format to Maybe format.

# Usage: ./convert_inter_to_maybe.sh input.csv output.csv account
# Converts a CSV file from Inter bank format to Maybe format.

if [ "$#" -ne 3 ]; then
    echo "Usage: $0 input.csv output.csv account"
    exit 1
fi

INTER_CSV="$1"
MAYBE_CSV="$2"
ACCOUNT="$3"

if [ ! -f "$INTER_CSV" ]; then
    echo "Input file $INTER_CSV does not exist."
    exit 2
fi

# Write Maybe CSV header
echo "date,amount,name,currency,category,tags,account,notes" > "$MAYBE_CSV"

# Skip header, process each Inter CSV row
tail -n +2 "$INTER_CSV" | \
awk -F'","' '
function trim(s) { sub(/^[ \t\r\n]+/, "", s); sub(/[ \t\r\n]+$/, "", s); return s }
BEGIN { OFS="," }
{
    # Remove leading and trailing quotes
    gsub(/^"/, "", $1)
    gsub(/"$/, "", $NF)
    # Now fields: $1=Data, $2=Lançamento, $3=Categoria, $4=Tipo, $5=Valor
    # Date: convert DD/MM/YYYY to MM/DD/YYYY
    split($1, d, "/")
    date = d[2] "/" d[1] "/" d[3]
    # Amount: remove "R$", non-breaking spaces, spaces, remove thousands separator, convert comma to dot, negate for "Compra à vista"
    amt = $5
    gsub(/R\$/, "", amt)
    gsub(/\xc2\xa0/, "", amt) # Remove non-breaking space
    gsub(/[[:space:]]/, "", amt)
    gsub(/\./, "", amt)       # Remove thousands separator
    gsub(/,/, ".", amt)       # Convert decimal comma to dot
    if ($4 == "Compra à vista") amt = "-" amt
    # Name: Lançamento
    name = trim($2)
    # Currency: BRL
    currency = "BRL"
    # Category: Categoria
    category = trim($3)
    # Tags: empty
    tags = ""
    # Account: empty
    account = ACCOUNT
    # Notes: Tipo
    notes = trim($4)
    print date, amt, name, currency, category, tags, account, notes
}' >> "$MAYBE_CSV"

echo "Conversion complete: $INTER_CSV -> $MAYBE_CSV"
