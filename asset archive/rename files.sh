#!/bin/bash

base="/storage/emulated/0/apps/roblox"
cd "$base" || exit 1

logfile="rename_log.json"
> "$logfile"

echo "[" >> "$logfile"

find . -type f | while read -r filepath; do
    relpath="${filepath#./}"

    # Skip already renamed log file
    [[ "$relpath" == "$logfile" ]] && continue

    mime=$(file -b --mime-encoding "$filepath")
    ext=""

    if [[ "$mime" == "utf-8" || "$mime" == "us-ascii" ]]; then
        first_bytes=$(head -c 256 "$filepath" | tr -d '\0')
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
            *)
                # fallback: check if it *contains* mesh signature
                if grep -a -m1 -q "^version [0-9]\+\.[0-9]\+" "$filepath"; then
                    ext="mesh"
                else
                    ext="bin"
                fi
                ;;
        esac
    fi

    newname="${filepath%.*}.$ext"

    if [[ "$filepath" != "$newname" ]]; then
        mv "$filepath" "$newname"
        echo "{\"old\": \"${relpath}\", \"new\": \"${newname#./}\"}," >> "$logfile"
    fi
done

# Finalize JSON
sed -i '$ s/,$//' "$logfile"
echo "]" >> "$logfile"
