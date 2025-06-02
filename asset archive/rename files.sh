#!/data/data/com.termux/files/usr/bin/bash

# Path to the file you want to check
file="$1"

# Default extension
ext=".bin"

# Use `file -b` to get basic description without file name prefix
type=$(file -b "$file")

# Detect known binary or image types
if echo "$type" | grep -qi "PNG image"; then
    ext=".png"
elif echo "$type" | grep -qi "JPEG image"; then
    ext=".jpg"
elif echo "$type" | grep -qi "GIF image"; then
    ext=".gif"
elif echo "$type" | grep -qi "Zip archive"; then
    ext=".zip"
elif echo "$type" | grep -qi "ASCII text"; then
    # Try parsing it as JSON using Python to verify if it's not just plain text
    if python3 -c "import json; json.load(open('$file'))" 2>/dev/null; then
        ext=".json"
    else
        ext=".txt"
    fi
elif python3 -c "import json; json.load(open('$file'))" 2>/dev/null; then
    # Fallback check for pretty-printed or text-encoded JSON
    ext=".json"
fi

# Output detected type and extension
echo "Detected type: $type"
echo "Using extension: $ext"

# Rename or copy to desired name if needed
# For example:
# mv "$file" "${file}${ext}"
