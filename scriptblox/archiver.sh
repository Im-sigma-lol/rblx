#!/bin/bash

# Required tools check
command -v jq >/dev/null || { echo "Missing: jq. Install with 'pkg install jq'"; exit 1; }
command -v curl >/dev/null || { echo "Missing: curl. Install with 'pkg install curl'"; exit 1; }

# Parse username from args or prompt
while [[ $# -gt 0 ]]; do
    case "$1" in
        -usr=*|-user=*|-username=*)
            username="${1#*=}"; shift ;;
        -usr|-user|-username)
            username="$2"; shift 2 ;;
        *)
            echo "Unknown option: $1"; exit 1 ;;
    esac
done

# Ask if not provided
if [[ -z "$username" ]]; then
    read -rp "Enter ScriptBlox username: " username
fi

# Setup folders
mkdir -p "scripts" "images/script"

# Empty metadata JSON file
user_json="user.json"
> "$user_json"

# Start scraping
page=1
total_pages=1

while (( page <= total_pages )); do
    echo "Fetching page $page of scripts for $username..."
    api_url="https://scriptblox.com/api/user/scripts/$username?page=$page"
    json=$(curl -s "$api_url")

    if [[ $page -eq 1 ]]; then
        total_pages=$(echo "$json" | jq '.result.totalPages')
        echo "Total pages: $total_pages"
    fi

    echo "$json" | jq '.result.scripts[]' >> "$user_json"

    echo "$json" | jq -c '.result.scripts[]' | while read -r script; do
        title=$(echo "$script" | jq -r '.title')
        slug=$(echo "$script" | jq -r '.slug')
        image=$(echo "$script" | jq -r '.image')

        safe_title=$(echo "$title" | tr -cd '[:alnum:]_-' | cut -c1-50)
        slug_folder="scripts/$slug"
        mkdir -p "$slug_folder"

        # Try to fetch script code from main API
        script_code=$(curl -s "https://scriptblox.com/api/script/script/$slug" | jq -r '.result.script')

        # Fallback to rawscripts.net if null or empty
        if [[ -z "$script_code" || "$script_code" == "null" ]]; then
            script_code=$(curl -s "https://rawscripts.net/raw/$slug")
        fi

        # Save script code if non-empty
        if [[ -n "$script_code" && "$script_code" != "null" ]]; then
            script_file="$slug_folder/$safe_title.lua"
            echo "$script_code" > "$script_file"
            echo "Saved: $script_file"
        else
            echo "Warning: Script code not found for $slug"
        fi

        # Download image if valid
        if [[ "$image" != "null" && "$image" != "/images/no-script.webp" ]]; then
            # Full image URL
            if [[ "$image" == http* ]]; then
                image_url="$image"
            else
                image_url="https://scriptblox.com$image"
            fi
            image_name=$(basename "$image_url")
            image_folder="images/$slug"
            mkdir -p "$image_folder"
            image_dest="$image_folder/$image_name"

            # Download if not already
            if [[ ! -f "$image_dest" || ! -s "$image_dest" ]]; then
                echo "Downloading image for $slug..."
                curl -s "$image_url" -o "$image_dest"
                if [[ ! -s "$image_dest" ]]; then
                    echo "  - Failed to download image: $image_url"
                    rm -f "$image_dest"
                else
                    echo "  - Image saved: $image_dest"
                fi
            fi
        fi
    done

    ((page++))
done

# Final summary
echo "Done. Scripts: $(find scripts -type f | wc -l), Images: $(find images -type f | wc -l)"
