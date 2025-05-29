#!/bin/bash

# Check dependencies
command -v jq >/dev/null || { echo "Missing jq. Install with: pkg install jq"; exit 1; }
command -v curl >/dev/null || { echo "Missing curl. Install with: pkg install curl"; exit 1; }

# Require exactly one argument (the username)
if [[ $# -ne 1 ]]; then
    echo "Usage: bash $0 <username>"
    exit 1
fi

# Set up folders
username="$1"
base_folder="$username"
scripts_folder="$base_folder/scripts"
images_folder="$base_folder/images"
user_json="$base_folder/user.json"

mkdir -p "$scripts_folder" "$images_folder"
> "$user_json"  # Clear or create JSON output file

page=1
total_pages=1

while (( page <= total_pages )); do
    echo "[*] Fetching page $page..."
    api="https://scriptblox.com/api/user/scripts/$username?page=$page"
    json=$(curl -s "$api")

    # Get total pages only once from the first API response
    if [[ $page -eq 1 ]]; then
        total_pages=$(echo "$json" | jq '.result.totalPages')
        echo "    Total pages: $total_pages"
    fi

    # Append script metadata to JSON file
    echo "$json" | jq '.result.scripts[]' >> "$user_json"

    # Loop through each script entry
    echo "$json" | jq -c '.result.scripts[]' | while read -r script; do
        title=$(echo "$script" | jq -r '.title')
        slug=$(echo "$script" | jq -r '.slug')
        image=$(echo "$script" | jq -r '.image')

        # Sanitize title for safe filenames (remove dangerous characters and limit length)
        safe_title=$(echo "$title" | sed 's#[<>:"/\\|?*]# #g' | tr -s ' ' | cut -c1-50)
        slug_folder="$scripts_folder/$slug"
        mkdir -p "$slug_folder"

        # Check if script already exists and skip redownload if so
        if [[ -n "$(find "$slug_folder" -name '*.lua' -print -quit)" ]]; then
            echo "    [=] Script folder already exists: $slug"
        fi

        # Fetch script code (primary API first, fallback to rawscripts.net)
        script_code=$(curl -s "https://scriptblox.com/api/script/script/$slug" | jq -r '.result.script')
        if [[ -z "$script_code" || "$script_code" == "null" ]]; then
            script_code=$(curl -s "https://rawscripts.net/raw/$slug")
        fi

        # Only proceed if valid script code is found
        if [[ -n "$script_code" && "$script_code" != "null" ]]; then
            script_file_base="$slug_folder/$safe_title"
            script_file="$script_file_base.lua"

            # If file exists, compare content and add suffix if different
            if [[ -f "$script_file" ]]; then
                if ! diff -q <(echo "$script_code") "$script_file" >/dev/null; then
                    i=1
                    while [[ -f "${script_file_base} ($i).lua" ]]; do
                        ((i++))
                    done
                    script_file="${script_file_base} ($i).lua"
                    echo "    [~] Duplicate name, saved as: $script_file"
                else
                    echo "    [=] Script unchanged, skipped: $script_file"
                    continue
                fi
            fi

            # Save the script
            echo "$script_code" > "$script_file"
            echo "    [+] Saved script: $script_file"
        else
            echo "    [!] Script not found for slug: $slug"
        fi

        # Handle image download
        script_image_folder="$images_folder/$slug"
        mkdir -p "$script_image_folder"

        if [[ "$image" != "null" && "$image" != "/images/no-script.webp" ]]; then
            if [[ "$image" == http* ]]; then
                # Handle rbxcdn image
                hash=$(echo "$image" | grep -oP 'tr\.rbxcdn\.com/\K[^/?]+')
                image_url="https://tr.rbxcdn.com/$hash/480/270/Image/Png/noFilter"
                image_name="${hash}.png"
            else
                # Handle scriptblox internal image
                image_url="https://scriptblox.com${image}"
                image_name=$(basename "$image_url" | cut -d'?' -f1)
            fi

            image_dest="$script_image_folder/$image_name"

            # Only download image if not already saved
            if [[ ! -s "$image_dest" ]]; then
                echo "    [+] Downloading image for $slug..."
                curl -sL "$image_url" -o "$image_dest"
                if [[ ! -s "$image_dest" ]]; then
                    echo "      - Failed to download: $image_url"
                    rm -f "$image_dest"
                else
                    echo "      - Saved: $image_dest"
                fi
            fi
        fi
    done

    ((page++))
done

# Final summary
echo "[✓] Finished. Scripts: $(find "$scripts_folder" -type f | wc -l), Images: $(find "$images_folder" -type f | wc -l)"
