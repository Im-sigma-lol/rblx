#!/bin/bash

BASE_DIR="/storage/emulated/0/Apps/Roblox"

rename_file_based_on_type() {
    local filepath="$1"

    # Use basic 'file' command
    local info
    info=$(file -b "$filepath" | tr '[:upper:]' '[:lower:]')

    # Determine extension
    local ext=""
    if echo "$info" | grep -q 'jpeg'; then
        ext="jpg"
    elif echo "$info" | grep -q 'png'; then
        ext="png"
    elif echo "$info" | grep -q 'webp'; then
        ext="webp"
    elif echo "$info" | grep -q 'image'; then
        ext="img"
    elif echo "$info" | grep -q 'ogg'; then
        ext="ogg"
    elif echo "$info" | grep -q 'mpeg'; then
        ext="mp3"
    elif echo "$info" | grep -q 'audio'; then
        ext="audio"
    elif echo "$info" | grep -q 'video'; then
        ext="mp4"
    elif echo "$info" | grep -q 'json'; then
        ext="json"
    elif echo "$info" | grep -q 'xml'; then
        # Check for UTF-8 to decide .rbxmx or just .xml
        if file -b "$filepath" | grep -qi 'utf-8'; then
            ext="rbxmx"
        else
            ext="xml"
        fi
    elif echo "$info" | grep -q 'ascii'; then
        ext="txt"
    elif echo "$info" | grep -q 'utf-8'; then
        ext="txt"
    elif echo "$info" | grep -q 'data'; then
        ext="rbxm"
    else
        ext="bin"
    fi

    # Strip extension from filename even if it already exists
    local dir=$(dirname "$filepath")
    local base=$(basename "$filepath")
    local name="${base%.*}"
    local newpath="$dir/$name.$ext"

    # Only rename if needed
    if [[ "$filepath" != "$newpath" ]]; then
        echo "Renaming: $filepath → $newpath"
        mv "$filepath" "$newpath"
    fi
}

export -f rename_file_based_on_type

# Recursively find all files and rename based on type
find "$BASE_DIR" -type f -exec bash -c 'rename_file_based_on_type "$0"' {} \;
