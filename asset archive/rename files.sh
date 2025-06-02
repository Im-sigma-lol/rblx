# Read first few bytes for analysis
headbytes=$(head -c 512 "$file")

# Check UTF-8 encoding using `iconv` (non-destructive test)
if iconv -f utf-8 -t utf-8 "$file" -o /dev/null 2>/dev/null; then
    # ==== TEXT FILE DETECTION ====
    if grep -q '"locations":' "$file" && grep -q '"assetFormat":' "$file"; then
        newext="json"
    elif grep -q '<roblox version=' "$file"; then
        newext="rbxmx"
    elif grep -q '<roblox' "$file"; then
        newext="rbxm"
    elif head -n 1 "$file" | grep -Eq '^version[[:space:]]+[0-9]+(\.[0-9]+)?$'; then
        newext="mesh"
    else
        newext="txt"
    fi
else
    # ==== BINARY FILE DETECTION ====
    sig4=$(printf "%.4s" "$headbytes")
    sig8=$(printf "%.8s" "$headbytes")

    case "$sig4" in
        OggS)
            newext="ogg"
            ;;
        fLaC)
            newext="flac"
            ;;
        RIFF)
            # Could be WAV or WEBP
            if echo "$headbytes" | grep -q "WAVE"; then
                newext="wav"
            elif echo "$headbytes" | grep -q "WEBP"; then
                newext="webp"
            fi
            ;;
        PNG|)
            newext="png"
            ;;
        GIF8)
            newext="gif"
            ;;
        %PDF)
            newext="pdf"
            ;;
        ID3*)
            newext="mp3"
            ;;
        \xFF\xFB)
            newext="mp3"
            ;;
        *)
            if echo "$headbytes" | grep -q '#EXTM3U'; then
                newext="m3u8"
            elif echo "$headbytes" | grep -q -E '^TS[a-zA-Z]'; then
                newext="ts"
            else
                newext="bin"
            fi
            ;;
    esac
fi
