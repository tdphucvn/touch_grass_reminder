#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEFAULT_OUTPUT="$ROOT_DIR/assets/AppIcon.icns"

usage() {
  cat <<EOF
Usage: scripts/make-icon.sh <input.(png|jpg|jpeg|... )> [output.icns]

Examples:
  scripts/make-icon.sh assets/icon-source.png
  scripts/make-icon.sh ~/Desktop/logo.jpg assets/AppIcon.icns
EOF
}

require_tool() {
  local tool="$1"
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "Missing required tool: $tool" >&2
    exit 1
  fi
}

if [[ $# -lt 1 || $# -gt 2 ]]; then
  usage
  exit 1
fi

INPUT_PATH="$1"
OUTPUT_PATH="${2:-$DEFAULT_OUTPUT}"

if [[ ! -f "$INPUT_PATH" ]]; then
  echo "Input file not found: $INPUT_PATH" >&2
  exit 1
fi

require_tool sips
require_tool iconutil

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

source_png="$tmp_dir/source.png"
square_png="$tmp_dir/square.png"
master_png="$tmp_dir/master-1024.png"
iconset_dir="$tmp_dir/AppIcon.iconset"

mkdir -p "$(dirname "$OUTPUT_PATH")"
mkdir -p "$iconset_dir"

# Convert any source type to PNG first.
sips -s format png "$INPUT_PATH" --out "$source_png" >/dev/null

width="$(sips -g pixelWidth "$source_png" | awk '/pixelWidth/ {print $2}')"
height="$(sips -g pixelHeight "$source_png" | awk '/pixelHeight/ {print $2}')"

if [[ -z "$width" || -z "$height" ]]; then
  echo "Failed to read image size from: $INPUT_PATH" >&2
  exit 1
fi

# macOS app icons are square. Center-crop to avoid distortion.
if [[ "$width" -gt "$height" ]]; then
  sips -c "$height" "$height" "$source_png" --out "$square_png" >/dev/null
elif [[ "$height" -gt "$width" ]]; then
  sips -c "$width" "$width" "$source_png" --out "$square_png" >/dev/null
else
  cp "$source_png" "$square_png"
fi

sips -z 1024 1024 "$square_png" --out "$master_png" >/dev/null

for pt in 16 32 128 256 512; do
  sips -z "$pt" "$pt" "$master_png" --out "$iconset_dir/icon_${pt}x${pt}.png" >/dev/null
  px=$((pt * 2))
  sips -z "$px" "$px" "$master_png" --out "$iconset_dir/icon_${pt}x${pt}@2x.png" >/dev/null
done

iconutil -c icns "$iconset_dir" -o "$OUTPUT_PATH"
echo "Created: $OUTPUT_PATH"
