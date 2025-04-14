#!/bin/bash

# Überprüfe, ob eine Datei angegeben wurde
if [ -z "$1" ]; then
    echo -e "\033[31mFehler: Keine Eingabedatei angegeben.\033[0m"
    echo "Verwendung: $0 <bash_skript.sh>"
    exit 1
fi

input_file="$1"
output_file="funktionsliste.txt"

# Lösche die alte Ausgabedatei (falls vorhanden)
# shellcheck disable=SC2188
> "$output_file"

# Extrahiere Funktionsnamen mit grep
# - Erkennung von 'function XYZ()' oder 'XYZ()'
grep -E '^[[:space:]]*(function[[:space:]]+)?[a-zA-Z_][a-zA-Z0-9_]*[[:space:]]*\(\)' "$input_file" | \
while read -r line; do
    # Entferne 'function ' und '()'
    func_name=$(echo "$line" | sed -E 's/^[[:space:]]*function[[:space:]]+//; s/[[:space:]]*\(\)[[:space:]]*//')
    echo "$func_name" >> "$output_file"
done

echo -e "\033[32mFunktionen wurden in \033[1m$output_file\033[0m \033[32mgespeichert.\033[0m"
echo "Anzahl gefundener Funktionen: $(wc -l < "$output_file")"