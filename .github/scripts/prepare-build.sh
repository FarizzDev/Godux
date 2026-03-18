#!/bin/bash
set -e

if [ ! -f export_presets.cfg ]; then
  echo "Error: File export_presets.cfg not found."
  exit 1
fi

if [[ -n "$EXPORT_CREDENTIALS" ]]; then
  mkdir .godot
  echo "$EXPORT_CREDENTIALS" | base64 -d >.godot/export_credentials.cfg
fi

# Determine if any Android build is happening
if [ "$PRESET_NAME" = $'[ Export All Preset ]\u2063' ]; then
  if grep -q 'platform="Android"' export_presets.cfg; then
    ISANDROID="true"
  else
    ISANDROID="false"
  fi
else
  if perl .github/scripts/lib/parse_presets.pl is_android "$PRESET_NAME"; then
    ISANDROID="true"
  else
    ISANDROID="false"
  fi
fi

echo "ISANDROID=${ISANDROID:-false}" >>"$GITHUB_ENV"

VERSION=$(echo "$GODOT_LINK" | sed -E 's|.*\/([0-9.]+)-([a-z0-9]+).*|\1.\2|')
GODOT_MAJOR=$(echo "$VERSION" | cut -d'.' -f1)

echo "VERSION=$VERSION" >>"$GITHUB_ENV"
echo "GODOT_MAJOR=$GODOT_MAJOR" >>"$GITHUB_ENV"
