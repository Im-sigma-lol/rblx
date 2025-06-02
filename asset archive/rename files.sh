#!/data/data/com.termux/files/usr/bin/bash

shopt -s globstar nullglob
dir="/storage/emulated/0/apps/roblox"

for file in "$dir"/**; do
  [ -f "$file" ] || continue

  encoding=$(file -b --mime "$file" 2>/dev/null | cut -d'=' -f2)
  name=$(basename "$file")
  ext="${name##*.}"

  if [[ "$encoding" == "utf-8" ]]; then
    headline=$(head -n 1 "$file")

    if [[ "$headline" == \{* ]]; then
      newext="json"
    elif grep -q "<roblox" "$file"; then
      newext="rbxmx"
    elif grep -q "<roblox" "$file" && grep -q "Saved by" "$file"; then
      newext="rbxmx"
    elif [[ "$headline" == version\ * ]]; then
      newext="mesh"
    else
      newext="txt"
    fi
  else
    headbytes=$(head -c 512 "$file")
    sig4=$(echo "$headbytes" | cut -c1-4)

    case "$sig4" in
      OggS)
        newext="ogg"
        ;;
      fLaC)
        newext="flac"
        ;;
      RIFF)
        if echo "$headbytes" | grep -q "WAVE"; then
          newext="wav"
        elif echo "$headbytes" | grep -q "WEBP"; then
          newext="webp"
        else
          newext="bin"
        fi
        ;;
      PNG*)
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

  base="${file%.*}"
  mv -n "$file" "${base}.${newext}"
done
