#!/data/data/com.termux/files/usr/bin/bash

shopt -s globstar nullglob
dir="/storage/emulated/0/apps/roblox"

for file in "$dir"/**; do
  [ -f "$file" ] || continue

  encoding=$(file -b --mime "$file" 2>/dev/null | cut -d'=' -f2)
  name=$(basename "$file")
  ext="${name##*.}"

  if [[ "$encoding" == "utf-8" ]]; then
    headline=$(head -n 1 "$file" | tr -d '\r\n')

    if [[ "$headline" == \{* ]]; then
      newext="json"
    elif grep -q "<roblox" "$file"; then
      newext="rbxmx"
    elif [[ "$headline" =~ ^version\ [0-9]+\.[0-9]+$ ]]; then
      newext="mesh"
    else
      newext="txt"
    fi
  else
    headline=$(head -n 1 "$file" | tr -d '\r\n')
    if [[ "$headline" =~ ^version\ [0-9]+\.[0-9]+$ ]]; then
      newext="mesh"
    else
      sig4=$(dd if="$file" bs=1 count=4 2>/dev/null | hexdump -v -e '/1 "%02X"')
      case "$sig4" in
        4F676753) newext="ogg" ;;
        664C6143) newext="flac" ;;
        52494646)
          if head -c 512 "$file" | grep -q "WAVE"; then
            newext="wav"
          elif head -c 512 "$file" | grep -q "WEBP"; then
            newext="webp"
          else
            newext="bin"
          fi
          ;;
        89504E47) newext="png" ;;
        47494638) newext="gif" ;;
        25504446) newext="pdf" ;;
        494433*) newext="mp3" ;;
        *)
          if head -c 512 "$file" | grep -q '#EXTM3U'; then
            newext="m3u8"
          elif head -c 512 "$file" | grep -q -E '^TS[a-zA-Z]'; then
            newext="ts"
          else
            newext="bin"
          fi
          ;;
      esac
    fi
  fi

  base="${file%.*}"
  mv -n "$file" "${base}.${newext}"
done
