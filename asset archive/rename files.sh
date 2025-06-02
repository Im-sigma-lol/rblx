#!/data/data/com.termux/files/usr/bin/bash

# ===[ Input and Safety Check ]===
file="$1"

# Ensure the file was passed in
if [ -z "$file" ]; then
  echo "Usage: $0 <filename>"
  exit 1
fi

# Make sure file exists
if [ ! -f "$file" ]; then
  echo "Error: '$file' does not exist or is not a file"
  exit 1
fi

# ===[ File Type Detection ]===
type=$(file -b "$file")
ext=".bin"  # default fallback extension

# Match known types
if echo "$type" | grep -qi "PNG image"; then
  ext=".png"
elif echo "$type" | grep -qi "JPEG image"; then
  ext=".jpg"
elif echo "$type" | grep -qi "GIF image"; then
  ext=".gif"
elif echo "$type" | grep -qi "Zip archive"; then
  ext=".zip"
elif echo "$type" | grep -qi "ASCII text"; then
  # Pretty-printed JSON might show up as ASCII text
  if python3 -c "import json; json.load(open('$file'))" 2>/dev/null; then
    ext=".json"
  else
    ext=".txt"
  fi
# If file is binary but still valid JSON (edge case)
elif python3 -c "import json; json.load(open('$file'))" 2>/dev/null; then
  ext=".json"
fi

# ===[ Output ]===
echo "Detected type: $type"
echo "Using extension: $ext"

# Example: rename the file (uncomment this if desired)
# mv "$file" "${file}${ext}"
