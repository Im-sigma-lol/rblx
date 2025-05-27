#!/bin/bash

# Normalize and extract argument
input=$(echo "$*" | tr '[:upper:]' '[:lower:]' | tr -d ' ')
if [[ "$input" != "usr" && "$input" != "user" && "$input" != "username" ]]; then
    echo "Usage: bash $0 username"
    exit 1
fi

read -p "Enter ScriptBlox username: " username
api_url="https://scriptblox.com/api/user/scripts/$username"
json_file="user.json"

mkdir -p images/script scripts

# Download user script list
curl -s "$api_url" -o "$json_file"

# Parse each script
jq -c '.result.scripts[]' "$json_file" | while read -r script; do
    # Extract fields
    slug=$(echo "$script" | jq -r '.slug')
    title=$(echo "$script" | jq -r '.title' | sed 's/[\/:*?"<>|]/_/g')
    image_path=$(echo "$script" | jq -r '.image')
    image_name=$(basename "$image_path")
    
    # Download image
    curl -s "https://scriptblox.com$image_path" -o "images/script/$image_name"

    # Download script source
    script_url="https://scriptblox.com/api/script/raw/$slug"
    script_data=$(curl -s "$script_url")
    code=$(echo "$script_data" | jq -r '.script')

    # Save script
    mkdir -p "scripts/$slug"
    echo "$code" > "scripts/$slug/$title.lua"

    echo "Downloaded: $title"
done
