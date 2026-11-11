#!/usr/bin/env bash
# cpurr setup: fetch the Waycat pose font from upstream.
# The font is not shipped in the repo (same as the Noctalia original);
# this downloads it into the plugin's fonts/ directory.
set -euo pipefail

FONT_URL="https://raw.githubusercontent.com/CarloCattano/waycat/main/fonts/Waycat.ttf"
script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
plugin_dir="$(dirname -- "$script_dir")"
font_dir="$plugin_dir/fonts"

mkdir -p "$font_dir"
if [[ -s "$font_dir/Waycat.ttf" ]]; then
  echo "Waycat.ttf already present, keeping it."
else
  echo "Fetching Waycat.ttf from CarloCattano/waycat ..."
  curl -fsSL --retry 2 -o "$font_dir/Waycat.ttf" "$FONT_URL"
fi

echo "Done. Restart the shell, then add the cpurr widget to the bar."
