#!/data/data/com.termux/files/usr/bin/bash

# Root directory to scan
root="/storage/emulated/0/apps/roblox"

fix_file() {
    file="$1"

    # Only process regular files
    [[ -f "$file" ]] || return

    # Grab MIME type and encoding
    mimetype=$(file -b --mime-type "$file")
    encoding=$(file -b --mime-encoding "$file")
    newext=""

    # Try identifying by content
    if [[ "$mimetype" == "application/json" || "$mimetype" == "text/plain" ]]; then
        # Try validating JSON
        if jq -e . "$file" &>/dev/null; then
            newext="json"
        elif grep -q "<?xml" "$file"; then
            newext="rbxmx"
        else
            newext="txt"
        fi

    elif grep -q -a "<?xml" "$file"; then
        newext="rbxmx"

    elif [[ "$encoding" != "utf-8" && "$mimetype" == "application/octet-stream" ]]; then
        newext="rbxm"

    elif [[ "$mimetype" == image/* ]]; then
        newext="${mimetype#image/}"

    elif [[ "$mimetype" == audio/* ]]; then
        newext="${mimetype#audio/}"

    elif [[ "$mimetype" == video/* ]]; then
        newext="${mimetype#video/}"

    elif [[ "$mimetype" == "application/vnd.apple.mpegurl" || "$mimetype" == "application/x-mpegURL" ]]; then
        newext="m3u8"

    elif [[ "$mimetype" == "video/MP2T" || "$mimetype" == "application/octet-stream" ]]; then
        # Could be .ts or .rbxm — fallback to ts if it's binary video
        if grep -q -a "<?xml" "$file"; then
            newext="rbxmx"
        else
            newext="ts"
        fi

    else
        newext="bin"
    fi

    # Handle current extension
    base="${file##*/}"
    dir="${file%/*}"
    ext="${base##*.}"

    if [[ "$base" == "$ext" ]]; then
        ext=""
    fi

    # Only rename if extension is different
    if [[ "$ext" != "$newext" ]]; then
        newname="${dir}/${base%.*}.${newext}"
        if [[ "$ext" == "" ]]; then
            newname="${file}.${newext}"
        fi

        echo "Renaming: $file -> $newname"
        mv -f "$file" "$newname"
    fi
}

export -f fix_file

# Scan all regular files, including extensionless
find "$root" -type f -exec bash -c 'fix_file "$0"' {} \;
