#!/bin/bash

set -e

# Normalize input
arg=$(echo "$*" | tr '[:upper:]' '[:lower:]' | tr -d ' ')
if [[ "$arg" != "usr" && "$arg" != "user" && "$arg" != "username" ]]; then
    echo "Usage: bash $0 username"
    exit 1
fi

# Get actual username input
read -p "Enter ScriptBlox username: " username
base_api="https://scriptblox.com/api/user/scripts/$username"

# Create folders
mkdir -p images/script scripts
json_file="user.json"

echo "[*] Fetching page 1 to determine total pages..."
page1=$(curl -s "$base_api?page=1")
total_pages=$(echo "$page1" | jq '.result.totalPages')

if [[ "$total_pages" == "null" || -z "$total_pages" ]]; then
    echo "[!] Failed to fetch or user not found."
    exit 1
fi

# Save first page to user.json
echo "$page1" > "$json_file"

# Append additional pages if > 1
for (( page=2; page<=total_pages; page++ )); do
    echo "[*] Fetching page $page of $total_pages..."
    curl -s "$base_api?page=$page" > "page_$page.json"
    jq -c '.result.scripts[]' "page_$page.json" >> all_scripts.json
done

# Combine all scripts into one file
jq -c '.result.scripts[]' "$json_file" > all_scripts.json

# Parse and download scripts/images
counter=0
while IFS= read -r script; do
    slug=$(echo "$script" | jq -r '.slug')
    title=$(echo "$script" | jq -r '.title' | sed 's/[\/:*?"<>|]/_/g')
    image_path=$(echo "$script" | jq -r '.image')
    image_name=$(basename "$image_path")

    echo "[*] Processing: $title"
    # Download image
    if [[ ! -f "images/script/$image_name" ]]; then
        echo "  - Downloading image: $image_name"
        curl -s "https://scriptblox.com$image_path" -o "images/script/$image_name"
    else
        echo "  - Image already exists: $image_name"
    fi

    # Download script source
    script_url="https://scriptblox.com/api/script/raw/$slug"
    script_data=$(curl -s "$script_url")
    code=$(echo "$script_data" | jq -r '.script')

    script_dir="scripts/$slug"
    mkdir -p "$script_dir"
    echo "$code" > "$script_dir/$title.lua"

    ((counter++))
done < all_scripts.json

echo "[✓] Finished downloading $counter scripts for $username"
