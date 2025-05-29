#!/bin/bash

# ─────────────────────────────────────────────
# ScriptBlox User Archiver
# Downloads all scripts and images for a given ScriptBlox username.
# Saves script metadata as JSON, scripts as .lua, and images by slug.
# ─────────────────────────────────────────────

# ───── Check dependencies ─────
command -v jq >/dev/null || { echo "Missing jq. Install with: pkg install jq"; exit 1; }
command -v curl >/dev/null || { echo "Missing curl. Install with: pkg install curl"; exit 1; }

# ───── Require username argument ─────
if [[ $# -ne 1 ]]; then
    echo "Usage: bash $0 <username>"
    exit 1
fi

username="$1"
base_folder="$username"
scripts_folder="$base_folder/scripts"
images_folder="$base_folder/images"
user_json="$base_folder/user.json"

# ───── Create necessary folders ─────
mkdir -p "$scripts_folder" "$images_folder"
> "$user_json"  # Truncate or create JSON output

page=1
total_pages=1

# ───── Main loop over paginated API ─────
while (( page <= total_pages )); do
    echo "[*] Fetching page $page..."
    api="https://scriptblox.com/api/user/scripts/$username?page=$page"
    json=$(curl -s "$api")

    # Determine total pages (only once)
    if [[ $page -eq 1 ]]; then
        total_pages=$(echo "$json" | jq '.result.totalPages')
        echo "    Total pages: $total_pages"
    fi

    # Append script metadata to master JSON
    echo "$json" | jq '.result.scripts[]' >> "$user_json"

    # ───── Loop over each script entry ─────
    echo "$json" | jq -c '.result.scripts[]' | while read -r script; do
        title=$(echo "$script" | jq -r '.title')
        slug=$(echo "$script" | jq -r '.slug')
        image=$(echo "$script" | jq -r '.image')

        # Sanitize title for filename (truncate to 50 chars)
        safe_title=$(echo "$title" | sed 's#[<>:"/\\|?*]# #g' | tr -s ' ' | cut -c1-50)

        # Sanitize slug for folder name (replace forbidden characters)
        safe_slug=$(echo "$slug" | sed 's#[<>:"/\\|?*]#_#g')

        slug_folder="$scripts_folder/$safe_slug"
        mkdir -p "$slug_folder"

        # ───── Download script code ─────
        script_code=$(curl -s "https://scriptblox.com/api/script/script/$slug" | jq -r '.result.script')

        # Fallback to rawscripts.net if null
        if [[ -z "$script_code" || "$script_code" == "null" ]]; then
            script_code=$(curl -s "https://rawscripts.net/raw/$slug")
        fi

        # Save .lua file if code was found
        if [[ -n "$script_code" && "$script_code" != "null" ]]; then
            script_file="$slug_folder/$safe_title.lua"
            echo "$script_code" > "$script_file" 2>/dev/null

            if [[ $? -eq 0 ]]; then
                echo "    [+] Saved script: $script_file"
            else
                echo "    [!] Failed to save script: $script_file (check permissions)"
            fi
        else
            echo "    [!] Script not found for slug: $slug"
        fi

        # ───── Download image if available ─────
        script_image_folder="$images_folder/$safe_slug"
        mkdir -p "$script_image_folder"

        if [[ "$image" != "null" && "$image" != "/images/no-script.webp" ]]; then
            if [[ "$image" == http* ]]; then
                # rbxcdn image
                hash=$(echo "$image" | grep -oP 'tr\.rbxcdn\.com/\K[^/?]+')
                image_url="https://tr.rbxcdn.com/$hash/480/270/Image/Png/noFilter"
                image_name="${hash}.png"
            else
                # scriptblox.com hosted image
                image_url="https://scriptblox.com${image}"
                image_name=$(basename "$image_url" | cut -d'?' -f1)
            fi

            image_dest="$script_image_folder/$image_name"

            # Download image only if it doesn't already exist
            if [[ ! -s "$image_dest" ]]; then
                echo "    [+] Downloading image for $slug..."
                curl -sL "$image_url" -o "$image_dest"
                if [[ ! -s "$image_dest" ]]; then
                    echo "      - Failed: $image_url"
                    rm -f "$image_dest"
                else
                    echo "      - Saved: $image_dest"
                fi
            fi
        fi
    done

    ((page++))
done

# ───── Summary ─────
echo "[✓] Finished. Scripts: $(find "$scripts_folder" -type f | wc -l), Images: $(find "$images_folder" -type f | wc -l)"
