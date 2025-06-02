#!/data/data/com.termux/files/usr/bin/bash

root="/storage/emulated/0/apps/roblox"

detect_type() {
  file="$1"

  # Detect JSON
  if python3 -c "import json,sys; json.load(open(sys.argv[1]))" "$file" 2>/dev/null; then
    echo "json"
    return
  fi

  # Detect XML (RBXMX)
  if grep -q '<roblox' "$file" 2>/dev/null; then
    echo "rbxmx"
    return
  fi

  # Detect M3U8
  if grep -qE '^#EXTM3U' "$file" 2>/dev/null; then
    echo "m3u8"
    return
  fi

  # Detect TS (TypeScript)
  if grep -qE '^(//|import )' "$file" 2>/dev/null; then
    echo "ts"
    return
  fi

  # Detect image/audio/video using magic number
  mimetype=$(file -b --mime-type "$file")
  case "$mimetype" in
    image/png) echo "png" ;;
    image/jpeg) echo "jpg" ;;
    image/webp) echo "webp" ;;
    audio/mpeg) echo "mp3" ;;
    audio/x-wav) echo "wav" ;;
    audio/ogg) echo "ogg" ;;
    video/mp4) echo "mp4" ;;
    video/webm) echo "webm" ;;
    *) ;;
  esac && return

  # Fallback: non-UTF-8? Likely binary
  if ! iconv -f UTF-8 -t UTF-8 "$file" >/dev/null 2>&1; then
    echo "rbxm"
    return
  fi

  echo "unknown"
}

fix_file() {
  file="$1"
  ext=$(detect_type "$file")

  if [ "$ext" = "unknown" ]; then
    echo "❓ Unknown: $file"
    return
  fi

  new="${file%.*}.$ext"
  if [ "$file" != "$new" ]; then
    mv "$file" "$new"
    echo "✅ Renamed: $file → $new"
  fi
}

export -f detect_type
export -f fix_file

find "$root" -type f -name "*.txt" -o -name "*.bin" -o -name "*.dat" -o -name "*.*" -exec bash -c 'fix_file "$0"' {} \;
