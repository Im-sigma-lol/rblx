#!/bin/bash

# Ensure required tools are installed
command -v jq >/dev/null || { echo "jq not installed. Install it with: pkg install jq"; exit 1; }
command -v curl >/dev/null || { echo "curl not installed. Install it with: pkg install curl"; exit 1; }

# Allow flexible arg parsing (e.g., -usr, --user, --username)
for arg in "$@"; do
    case "$arg" in
        -usr=*|--usr=*|--user=*|--username=*)
            username="${arg#*=}"
            ;;
    esac
done

# Error if username wasn't found
if [[ -z "$username" ]]; then
    echo "Usage: $0 --username=USERNAME"
    exit 1
fi

# Normalize output folders
mkdir -p images/script scripts

# Prepare user JSON output
user_json="user.json"
echo "Fetching scripts for user: $username"
echo -n > "$user_json"  # Empty the file first

# Page fetching loop
page=1
total_pages=1

while (( page <= total_pages )); do
    echo "Downloading page $page..."

    # Fetch JSON from the API
    url="https://scriptblox.com/api/user/scripts/$username?page=$page"
    json=$(curl -s "$url")

    # On first page, get total page count
    if [[ $page -eq 1 ]]; then
        total_pages=$(echo "$json" | jq '.result.totalPages')
        echo "Total pages: $total_pages"
    fi

    # Append result JSON to the main file
    echo "$json" | jq '.result.scripts[]' >> "$user_json"

    # Process each script on the current page
    echo "$json" | jq -c '.result.scripts[]' | while read -r script; do
        title=$(echo "$script" | jq -r '.title')
        slug=$(echo "$script" | jq -r '.slug')
        script_id=$(echo "$script" | jq -r '._id')
        image_path=$(echo "$script" | jq -r '.image')

        # Clean filename (remove dangerous characters)
        safe_title=$(echo "$title" | tr -cd '[:alnum:]_-' | cut -c1-40)

        echo "Processing: $title"

        # Download script source from API
        slug_api="https://scriptblox.com/api/script/script/$slug"
        script_json=$(curl -s "$slug_api")

        script_code=$(echo "$script_json" | jq -r '.result.script')

        # Create folder and save .lua file
        slug_folder="scripts/$slug"
        mkdir -p "$slug_folder"
        echo "$script_code" > "$slug_folder/$safe_title.lua"
        echo "  - Script saved: $slug_folder/$safe_title.lua"

        # Process image
        if [[ "$image_path" == "null" || "$image_path" == "/images/no-script.webp" ]]; then
            echo "  - Skipping default or missing image"
        else
            image_name=$(basename "$image_path")

            if [[ "$image_path" =~ ^http ]]; then
                image_url="$image_path"
                image_dest="images/script/$image_name"
                mkdir -p "images/script"
            else
                image_url="https://scriptblox.com$image_path"
                image_dest="images/$slug/$image_name"
                mkdir -p "images/$slug"
            fi

            if [[ ! -f "$image_dest" ]]; then
                echo "  - Downloading image: $image_dest"
                curl -s "$image_url" -o "$image_dest"
            else
                echo "  - Image already exists: $image_dest"
            fi
        fi
    done

    ((page++))
done

echo "Archiving complete."
