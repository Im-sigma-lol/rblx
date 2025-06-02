#!/bin/bash

base="/storage/emulated/0/apps/roblox"
cd "$base" || exit 1

logfile="rename_log.json"
> "$logfile"

find . -type f | while read -r filepath; do
    relpath="${filepath#./}"
    mime=$(file -b --mime-encoding "$filepath")

    first_bytes=$(head -c 128 "$filepath" | tr -d '\0')

    if file "$filepath" | grep -q 'ASCII\|UTF-8'; then
        if [[ "$first_bytes" == *"<roblox version="* ]]; then
            ext="rbxmx"
        elif [[ "$first_bytes" =~ ^\{ ]]; then
            ext="json"
        elif [[ "$first_bytes" =~ ^version[[:space:]]+[0-9]+\.[0-9]+ ]]; then
            ext="mesh"
        else
            ext="txt"
        fi
    else
        magic=$(xxd -l 4 -p "$filepath" 2>/dev/null | tr '[:lower:]' '[:upper:]')
        case "$magic" in
            4F676753) ext="ogg" ;;
            89504E47) ext="png" ;;
            FFD8FFE0|FFD8FFE1|FFD8FFE2) ext="jpg" ;;
            *) ext="bin" ;;
        esac
    fi

    newname="${filepath%.*}.$ext"

    if [[ "$filepath" != "$newname" ]]; then
        mv "$filepath" "$newname"
        echo "{\"old\": \"${relpath}\", \"new\": \"${newname#./}\"}," >> "$logfile"
    fi
done

# Remove trailing comma and wrap in brackets to make valid JSON
sed -i '$ s/,$//' "$logfile"
sed -i '1s/^/[/' "$logfile"
echo "]" >> "$logfile"
