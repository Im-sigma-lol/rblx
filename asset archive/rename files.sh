#!/bin/bash

BASE_DIR="/storage/emulated/0/Apps/Roblox"

rename_file_based_on_type() {
    local filepath="$1"
    local mime
    mime=$(file -b --mime-type "$filepath")

    case "$mime" in
        image/jpeg) ext="jpg" ;;
        image/png) ext="png" ;;
        image/webp) ext="webp" ;;
        image/*) ext="img" ;;  # fallback
        audio/ogg) ext="ogg" ;;
        audio/mpeg) ext="mp3" ;;
        audio/*) ext="audio" ;;  # fallback
        video/mp4) ext="mp4" ;;
        video/webm) ext="webm" ;;
        video/*) ext="video" ;;  # fallback
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
                # binary but not image/audio/video
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

    newpath="${filepath%.*}.$ext"
    if [[ "$filepath" != "$newpath" ]]; then
        echo "Renaming: $filepath → $newpath"
        mv "$filepath" "$newpath"
    fi
}

export -f rename_file_based_on_type

find "$BASE_DIR" -type f ! -name "*.*" -exec bash -c 'rename_file_based_on_type "$0"' {} \;
