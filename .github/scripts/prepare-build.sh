#!/bin/bash
set -e

if [ ! -f export_presets.cfg ]; then
  echo "Error: File export_presets.cfg not found."
  exit 1
fi

# Determine if any Android build is happening
if [ "$PRESET_NAME" = $'[ Export All Preset ]\u2063' ]; then
  ISANDROID=$(grep -q 'platform="Android"' export_presets.cfg && echo "true")
else
  python3 .github/scripts/lib/parse_presets.py is_android "$PRESET_NAME" && ISANDROID=true || ISANDROID=false
fi

echo "ISANDROID=${ISANDROID:-false}" >>"$GITHUB_ENV"

VERSION=$(echo "$GODOT_LINK" | sed -E 's|.*\/([0-9.]+)-([a-z0-9]+).*|\1.\2|')
echo "VERSION=$VERSION" >>"$GITHUB_ENV"
