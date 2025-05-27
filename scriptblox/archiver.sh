#!/data/data/com.termux/files/usr/bin/bash

# Ensure required tools
command -v jq >/dev/null || { echo "jq is required"; exit 1; }

# Prompt for username if not provided
if [[ "$1" =~ ^-username=.+$ ]]; then
    username="${1#*=}"
else
    read -p "Enter ScriptBlox username: " username
fi

account_dir="roblox/$username"
mkdir -p "$account_dir/scripts" "$account_dir/images"

# Fetch user data
user_json="$account_dir/user.json"
echo "[*] Fetching user data..."
wget -q --show-progress "https://scriptblox.com/api/user/scripts/$username" -O "$user_json"

# Parse and process each script
jq -c '.data[]' "$user_json" | while read -r entry; do
    slug=$(echo "$entry" | jq -r '.slug')
    title=$(echo "$entry" | jq -r '.title' | sed 's#[\\/:"*?<>|]# #g')
    image_url=$(echo "$entry" | jq -r '.image')

    echo "- Archiving: $title"

    # Create slug folder
    mkdir -p "$account_dir/scripts/$slug" "$account_dir/images/$slug"

    # Download script code from slug
    script_api="https://scriptblox.com/api/script/$slug"
    script_json=$(wget -qO- "$script_api")
    script_code=$(echo "$script_json" | jq -r '.data.script')

    if [[ "$script_code" == "null" || -z "$script_code" ]]; then
        echo "    [!] Script code not found, skipping."
    else
        echo "$script_code" > "$account_dir/scripts/$slug/$title.lua"
        echo "    [+] Script saved."
    fi

    # Process image
    if [[ "$image_url" == "null" || -z "$image_url" ]]; then
        continue
    fi

    if [[ "$image_url" == *"rbxcdn.com"* ]]; then
        hash=$(echo "$image_url" | cut -d/ -f4)
        image_path="$account_dir/images/$slug/$hash.jpg"
    else
        filename=$(basename "$image_url")
        image_path="$account_dir/images/$slug/$filename"
    fi

    wget -q --show-progress --timeout=10 "$image_url" -O "$image_path" || {
        echo "    [!] Failed to download: $image_url"
        rm -f "$image_path"
    }
done

echo "[✓] Done! Files saved under: $account_dir"
