#!/bin/bash

# Check dependencies
command -v jq >/dev/null || { echo "Missing jq. Install with: pkg install jq"; exit 1; }
command -v curl >/dev/null || { echo "Missing curl. Install with: pkg install curl"; exit 1; }

# Parse args or ask
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

if [[ -z "$username" ]]; then
    read -rp "Enter ScriptBlox username: " username
fi

# Setup folders
mkdir -p "scripts" "images"

# Output metadata
user_json="user.json"
> "$user_json"

page=1
total_pages=1

while (( page <= total_pages )); do
    echo "Fetching page $page..."
    api="https://scriptblox.com/api/user/scripts/$username?page=$page"
    json=$(curl -s "$api")

    if [[ $page -eq 1 ]]; then
        total_pages=$(echo "$json" | jq '.result.totalPages')
        echo "Total pages: $total_pages"
    fi

    echo "$json" | jq '.result.scripts[]' >> "$user_json"

    echo "$json" | jq -c '.result.scripts[]' | while read -r script; do
        title=$(echo "$script" | jq -r '.title')
        slug=$(echo "$script" | jq -r '.slug')
        image=$(echo "$script" | jq -r '.image')

        # Sanitize title
        safe_title=$(echo "$title" | sed 's#[<>:"/\\|?*]# #g' | tr -s ' ' | cut -c1-50)
        slug_folder="scripts/$slug"
        mkdir -p "$slug_folder"

        # Script code
        script_code=$(curl -s "https://scriptblox.com/api/script/script/$slug" | jq -r '.result.script')
        if [[ -z "$script_code" || "$script_code" == "null" ]]; then
            script_code=$(curl -s "https://rawscripts.net/raw/$slug")
        fi

        if [[ -n "$script_code" && "$script_code" != "null" ]]; then
            script_file="$slug_folder/$safe_title.lua"
            echo "$script_code" > "$script_file"
            echo "Saved script: $script_file"
        else
            echo "Warning: Script for $slug not found"
        fi

        # IMAGE HANDLING
        image_folder="images/$slug"
        mkdir -p "$image_folder"

        if [[ "$image" != "null" && "$image" != "/images/no-script.webp" ]]; then
            # Full image URL resolution
            if [[ "$image" == http* ]]; then
                image_url="$image"

                # Extract hash and extension
                hash=$(echo "$image_url" | grep -oP 'tr\.rbxcdn\.com/\K[^/]+')
                ext=$(echo "$image_url" | grep -oP '/Image/\K\w+')
                [[ -z "$ext" ]] && ext="jpg"  # fallback default

                image_name="${hash}.${ext}"
            else
                image_url="https://scriptblox.com${image}"
                image_name=$(basename "$image_url")
            fi

            image_dest="$image_folder/$image_name"

            if [[ ! -f "$image_dest" || ! -s "$image_dest" ]]; then
                echo "Downloading image for $slug..."
                curl -s "$image_url" -o "$image_dest"
                if [[ ! -s "$image_dest" ]]; then
                    echo "  - Failed: $image_url"
                    rm -f "$image_dest"
                else
                    echo "  - Saved: $image_dest"
                fi
            fi
        fi
    done

    ((page++))
done

echo "Finished. Scripts: $(find scripts -type f | wc -l), Images: $(find images -type f | wc -l)"
