#!/bin/bash

BASE_DIR="/storage/emulated/0/Apps/Roblox"

rename_file_based_on_type() {
    local filepath="$1"

    # Get MIME type
    local mime
    mime=$(file -b --mime-type "$filepath")

    # Decide new extension
    local ext=""
    case "$mime" in
        image/jpeg) ext="jpg" ;;
        image/png) ext="png" ;;
        image/webp) ext="webp" ;;
        image/*) ext="img" ;;
        audio/ogg) ext="ogg" ;;
        audio/mpeg) ext="mp3" ;;
        audio/*) ext="audio" ;;
        video/mp4) ext="mp4" ;;
        video/webm) ext="webm" ;;
        video/*) ext="video" ;;
        application/xml|text/xml)
            if file -b --mime-encoding "$filepath" | grep -qi utf-8; then
                ext="rbxmx"
            else
                ext="xml"
            fi
            ;;
        application/octet-stream)
            if file "$filepath" | grep -qi 'utf-8'; then
                ext="txt"
            else
                ext="rbxm"
            fi
            ;;
        text/*)
            ext="txt"
            ;;
        *)
            ext="bin"
            ;;
    esac

    # Strip original extension
    local base="${filepath%.*}"
    local dir=$(dirname "$filepath")
    local name=$(basename "$base")
    local newpath="$dir/$name.$ext"

    # Only rename if new path differs
    if [[ "$filepath" != "$newpath" ]]; then
        echo "Renaming: $filepath → $newpath"
        mv "$filepath" "$newpath"
    fi
}

export -f rename_file_based_on_type

# Recursively find all files
find "$BASE_DIR" -type f -exec bash -c 'rename_file_based_on_type "$0"' {} \;
