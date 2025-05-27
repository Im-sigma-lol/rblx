#!/bin/bash

# Prompt or accept username
for arg in "$@"; do
    case $arg in
        -username=*|-user=*|-usr=*)
            username="${arg#*=}"
            ;;
    esac
done

if [ -z "$username" ]; then
    read -p "Enter ScriptBlox username: " username
fi

# Create account folder structure
account_dir="${username}"
scripts_dir="${account_dir}/scripts"
images_dir="${account_dir}/images"
json_file="${account_dir}/user.json"
mkdir -p "$scripts_dir" "$images_dir"

# Clean filenames
clean_name() {
    echo "$1" | sed 's#[<>:"/\\|?*]# #g'
}

# Download from URL safely
safe_download() {
    url="$1"
    out="$2"
    if [[ ! -f "$out" ]]; then
        echo "  - Downloading: $out"
        curl -sL --fail "$url" -o "$out" || echo "    [!] Failed to download: $url"
    fi
}

# Get total pages
echo "[*] Fetching page count..."
initial_url="https://scriptblox.com/api/user/scripts/$username?page=1"
initial_data=$(curl -s "$initial_url")
total_pages=$(echo "$initial_data" | jq -r '.result.totalPages')

if [[ "$total_pages" == "null" || -z "$total_pages" ]]; then
    echo "[!] Could not get total pages. Check if the username exists."
    exit 1
fi

echo "[*] Total pages: $total_pages"
echo "$initial_data" > "$json_file"

# Loop through pages
for ((page=1; page<=total_pages; page++)); do
    echo "[*] Processing page $page..."

    data=$(curl -s "https://scriptblox.com/api/user/scripts/$username?page=$page")
    echo "$data" | jq -c '.result.scripts[]' | while read -r script; do
        slug=$(echo "$script" | jq -r '.slug')
        title=$(echo "$script" | jq -r '.title')
        clean_title=$(clean_name "$title")

        echo "  - Archiving: $clean_title"
        script_path="${scripts_dir}/${slug}/${clean_title}.lua"
        mkdir -p "$(dirname "$script_path")"

        # Get script source
        src=$(curl -s "https://scriptblox.com/api/script/$slug")
        code=$(echo "$src" | jq -r '.result.code')

        if [[ "$code" == "null" || -z "$code" ]]; then
            fallback_url="https://rawscripts.net/raw/$title"
            echo "    [!] ScriptBlox null, trying fallback: $fallback_url"
            curl -sL "$fallback_url" -o "$script_path" || echo "    [!] Failed fallback too"
        else
            echo "$code" > "$script_path"
        fi

        # Get image
        image=$(echo "$script" | jq -r '.image')
        if [[ "$image" == http* ]]; then
            # Full URL
            img_id=$(basename "$image" | cut -d'/' -f1)
            ext="${image##*.}"
            out_image="${images_dir}/${img_id}.${ext}"
            safe_download "$image" "$out_image"
        elif [[ "$image" == /images/* ]]; then
            # ScriptBlox path
            full_url="https://scriptblox.com$image"
            image_name=$(basename "$image")
            image_slug=$(clean_name "$slug")
            out_image="${images_dir}/${image_slug}/${image_name}"
            mkdir -p "$(dirname "$out_image")"
            safe_download "$full_url" "$out_image"
        else
            echo "    [!] Unknown image format: $image"
        fi
    done
done

echo "[✓] Done! Files saved under: $account_dir"
