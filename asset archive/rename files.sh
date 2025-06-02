#!/bin/bash

BASE="/storage/emulated/0/apps/roblox"
LOG_DIR="$BASE/__log__"
mkdir -p "$LOG_DIR"

CLASSIFY_LOG="$LOG_DIR/classify-log.jsonl"
ERROR_LOG="$LOG_DIR/error-log.jsonl"
REVERT_LOG="$LOG_DIR/revert-log.jsonl"

> "$CLASSIFY_LOG"
> "$ERROR_LOG"
> "$REVERT_LOG"

log_json() {
    echo "$1" >> "$2"
}

relative_path() {
    echo "${1#"$BASE"/}"
}

classify_file() {
    filepath="$1"
    filename="$(basename "$filepath")"
    relpath="$(relative_path "$filepath")"

    [[ "$filepath" == *"__log__"* ]] && return
    [[ -d "$filepath" ]] && return

    ext="bin"
    first_line=$(head -n 1 "$filepath" 2>/dev/null | tr -d '\0')

    if file "$filepath" | grep -q 'ASCII\|UTF-8'; then
        if [[ "$first_line" == *"<roblox version="* ]]; then
            ext="rbxmx"
        elif [[ "$first_line" == '{'* ]]; then
            ext="json"
        elif [[ "$first_line" =~ ^version[[:space:]]+[0-9]+(\.[0-9]+)? ]]; then
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
                if echo "$first_line" | grep -qE '^version[[:space:]]+[0-9]+(\.[0-9]+)?'; then
                    ext="mesh"
                fi
                ;;
        esac
    fi

    newname="${filepath%.*}.$ext"
    [[ "$filepath" == "$newname" ]] && return

    if mv -n "$filepath" "$newname"; then
        log_json "{\"from\": \"$(relative_path "$filepath")\", \"to\": \"$(relative_path "$newname")\", \"type\": \"$ext\"}" "$CLASSIFY_LOG"
        log_json "{\"old\": \"$(relative_path "$filepath")\", \"new\": \"$(relative_path "$newname")\"}" "$REVERT_LOG"
    else
        log_json "{\"error\": \"rename failed\", \"file\": \"$relpath\"}" "$ERROR_LOG"
    fi
}

find "$BASE" -type f | while read -r file; do
    classify_file "$file"
done
