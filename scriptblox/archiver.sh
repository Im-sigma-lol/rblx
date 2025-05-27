#!/bin/bash

# Username input
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

# Folder structure
account_dir="${username}"
scripts_dir="${account_dir}/scripts"
images_dir="${account_dir}/images"
json_file="${account_dir}/user.json"
mkdir -p "$scripts_dir" "$images_dir"

# Clean titles for filesystem
clean_name() {
    echo "$1" | sed 's#[<>:"/\\|?*]#_#g'
}

# Scrape raw script from HTML page
get_raw_script_from_page() {
    slug="$1"
    html=$(curl -s "https://scriptblox.com/script/$slug")
    echo "$html" | grep -oP '"code":"\K(.*?)(?=")' | sed 's#\\n#\n#g; s#\\t#\t#g; s#\\"#"#g'
}

# Get total pages
echo "[*] Getting pages..."
initial=$(curl -s "https://scriptblox.com/api/user/scripts/$username?page=1")
echo "$initial" > "$json_file"
total_pages=$(echo "$initial" | jq -r '.result.totalPages')

if [[ "$total_pages" == "null" || -z "$total_pages" ]]; then
    echo "[!] No scripts found or username invalid."
    exit 1
fi

# Process all pages
for ((page=1; page<=total_pages; page++)); do
    echo "[*] Page $page"
    data=$(curl -s "https://scriptblox.com/api/user/scripts/$username?page=$page")
    echo "$data" | jq -c '.result.scripts[]' | while read -r script; do
        slug=$(echo "$script" | jq -r '.slug')
        title=$(echo "$script" | jq -r '.title')
        image=$(echo "$script" | jq -r '.image')
        clean_title=$(clean_name "$title")
        script_folder="${scripts_dir}/${slug}"
        mkdir -p "$script_folder"

        # Extract script from webpage
        echo "  - Archiving: $title"
        raw_code=$(get_raw_script_from_page "$slug")

        if [[ -z "$raw_code" ]]; then
            echo "    [!] Script code not found, skipping."
        else
            echo "$raw_code" > "$script_folder/$clean_title.lua"
        fi

        # Skip image download due to 403s
        # Placeholder: Save image URL in case future proxy solution found
        if [[ "$image" != "null" ]]; then
            echo "$image" > "$script_folder/image.txt"
        fi
    done
done

echo "[✓] Done! Files saved under: $account_dir"
