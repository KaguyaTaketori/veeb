#!/bin/bash
# gather_dart.sh - Gather all Dart files into one txt
# Usage: ./gather_dart.sh

OUTPUT="./dart_code.txt"
FOLDER="./lib"
COUNT=0

# Remove existing output
> "$OUTPUT"

echo "// ============================================================================" >> "$OUTPUT"
echo "// Dart Code - Vee App" >> "$OUTPUT"
echo "// Generated: $(date '+%Y-%m-%d')" >> "$OUTPUT"
echo "// ============================================================================" >> "$OUTPUT"
echo "" >> "$OUTPUT"

while IFS= read -r file; do
    echo "// ---------------------------------------------------------------------------" >> "$OUTPUT"
    echo "// FILE: ${file##*/}" >> "$OUTPUT"
    echo "// ---------------------------------------------------------------------------" >> "$OUTPUT"
    cat "$file" >> "$OUTPUT"
    echo "" >> "$OUTPUT"
    echo "" >> "$OUTPUT"
    ((COUNT++))
done < <(find "$FOLDER" -name "*.dart" -type f | sort)

echo "// ============================================================================" >> "$OUTPUT"
echo "// Total files: $COUNT" >> "$OUTPUT"
echo "// ============================================================================" >> "$OUTPUT"

echo "Done. $COUNT Dart files consolidated to $OUTPUT"
