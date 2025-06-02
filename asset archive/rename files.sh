#!/data/data/com.termux/files/usr/bin/bash

root="/storage/emulated/0/apps/roblox"

fix_file() {
    file="$1"
    if [[ ! -f "$file" ]]; then return; fi

    mimetype=$(file -b --mime-type "$file")
    encoding=$(file -b --mime-encoding "$file")
    newext=""

    # Handle text/json
    if [[ "$mimetype" == "application/json" || "$mimetype" == "text/plain" ]]; then
        if jq empty "$file" &>/dev/null; then
            newext="json"
        elif grep -q '<?xml' "$file"; then
            newext="rbxmx"
        else
            newext="txt"
        fi

    # Binary XML (non-UTF-8)
    elif grep -q -a '<?xml' "$file"; then
        newext="rbxmx"

    # Binary but not readable
    elif [[ "$encoding" != "utf-8" && "$mimetype" == "application/octet-stream" ]]; then
        newext="rbxm"

    # Images
    elif [[ "$mimetype" == image/* ]]; then
        newext="${mimetype#image/}"

    # Audio
    elif [[ "$mimetype" == audio/* ]]; then
        newext="${mimetype#audio/}"

    # Video and stream
    elif [[ "$mimetype" == video/* ]]; then
        newext="${mimetype#video/}"
    elif [[ "$mimetype" == "application/vnd.apple.mpegurl" || "$mimetype" == "application/x-mpegURL" ]]; then
        newext="m3u8"
    elif [[ "$mimetype" == "video/MP2T" ]]; then
        newext="ts"

    else
        newext="bin"
    fi

    currentext="${file##*.}"
    filename="${file%.*}"
    if [[ "$file" == "$filename" ]]; then
        filename="$file"
        currentext=""
    fi

    # Only rename if different
    if [[ "$currentext" != "$newext" ]]; then
        newpath="${filename}.${newext}"
        echo "Renaming: $file → $newpath"
        mv -f "$file" "$newpath"
    fi
}

export -f fix_file

# ✅ This handles ALL files, even those with no extension
find "$root" -type f -exec bash -c 'fix_file "$0"' {} \;
