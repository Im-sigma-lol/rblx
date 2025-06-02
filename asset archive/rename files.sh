#!/data/data/com.termux/files/usr/bin/bash

root="/storage/emulated/0/apps/roblox"

fix_file() {
    file="$1"
    [[ -f "$file" ]] || return

    base="${file##*/}"
    dir="${file%/*}"
    ext="${base##*.}"

    [[ "$ext" == "$base" ]] && ext=""

    newext=""

    # Avoid null-byte warnings by grepping directly from file
    if head -c 4 "$file" | grep -q "OggS"; then
        newext="ogg"

    elif head -c 512 "$file" | grep -q '<!-- Saved by UniversalSynSaveInstance' && head -c 512 "$file" | grep -q '<roblox version="4">'; then
        newext="rbxmx"

    elif grep -q -a "#EXTM3U" "$file"; then
        newext="m3u8"

    elif grep -q -a "<?xml" "$file"; then
        newext="rbxmx"

    elif grep -q -a "{.*}" "$file"; then
        if jq -e . "$file" &>/dev/null; then
            newext="json"
        else
            newext="txt"
        fi

    else
        info=$(file -b "$file")

        if echo "$info" | grep -qi "json"; then
            if jq -e . "$file" &>/dev/null; then
                newext="json"
            else
                newext="txt"
            fi

        elif echo "$info" | grep -qi "XML"; then
            newext="rbxmx"

        elif echo "$info" | grep -qi "UTF-8 Unicode text"; then
            newext="txt"

        elif echo "$info" | grep -qi "image data"; then
            case "$info" in
                *PNG*) newext="png" ;;
                *JPEG*) newext="jpg" ;;
                *GIF*) newext="gif" ;;
                *BMP*) newext="bmp" ;;
                *) newext="img" ;;
            esac

        elif echo "$info" | grep -qi "audio data"; then
            # Roblox only uses .ogg, fallback
            newext="ogg"

        elif echo "$info" | grep -qi "video"; then
            case "$info" in
                *MPEG*) newext="mp4" ;;
                *MPEG-TS*) newext="ts" ;;
                *) newext="video" ;;
            esac

        elif echo "$info" | grep -qi "data"; then
            newext="rbxm"

        else
            newext="bin"
        fi
    fi

    [[ "$ext" == "$newext" ]] && return

    if [[ -n "$ext" ]]; then
        newname="${dir}/${base%.*}.${newext}"
    else
        newname="${file}.${newext}"
    fi

    echo "Renaming: $file -> $newname"
    mv -f "$file" "$newname"
}

export -f fix_file

find "$root" -type f -exec bash -c 'fix_file "$0"' {} \;
