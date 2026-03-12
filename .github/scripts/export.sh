#!/bin/bash
set -e
mkdir -p export

if [[ "$DEBUG" == "true" ]]; then
  EXPORT_FLAG="--export-debug"
else
  EXPORT_FLAG="--export"
fi

get_output_path() {
  local p_name="$1"
  local p_type="$2"
  local s_folder

  s_folder=$(echo "$p_type" | tr '[:upper:]' '[:lower:]' | cut -d'/' -f1 | tr -d '[:space:]')
  mkdir -p "export/$s_folder"

  case "$p_type" in
  "Android") echo "export/$s_folder/$FILE_BASENAME.$(python3 .github/scripts/lib/parse_presets.py export_format "$p_name")" ;;
  "Windows Desktop") echo "export/$s_folder/$FILE_BASENAME.exe" ;;
  "Linux/X11") echo "export/$s_folder/$FILE_BASENAME" ;;
  "Mac OSX") echo "export/$s_folder/$FILE_BASENAME.zip" ;;
  "HTML5") echo "export/$s_folder/index.html" ;;
  *) echo "export/$s_folder/$FILE_BASENAME.bin" ;;
  esac
}

if [ "$PRESET_NAME" = $'[ Export All Preset ]\u2063' ]; then
  # name|platform
  presets=$(python3 .github/scripts/lib/parse_presets.py list)

  while IFS='|' read -r p_name p_type; do
    echo ">>> Exporting $p_name ($p_type)..."
    OUT=$(get_output_path "$p_name" "$p_type")
    godot $EXPORT_FLAG "$p_name" "$OUT" 2>&1 | grep -v "VisualServer attempted to free a NULL RID\|at: free (servers/visual"
    GODOT_EXIT=${PIPESTATUS[0]}
    if [ $GODOT_EXIT -ne 0 ]; then
      echo "Export failed with exit code $GODOT_EXIT"
      exit $GODOT_EXIT
    fi
  done <<<"$presets"
else
  # Export Single Preset
  echo ">>> Exporting $PRESET_NAME..."

  PLATFORM=$(python3 .github/scripts/lib/parse_presets.py platform "$PRESET_NAME")

  OUT=$(get_output_path "$PRESET_NAME" "$PLATFORM")

  godot $EXPORT_FLAG "$PRESET_NAME" "$OUT" 2>&1 | grep -v "VisualServer attempted to free a NULL RID\|at: free (servers/visual"
  GODOT_EXIT=${PIPESTATUS[0]}
  if [ $GODOT_EXIT -ne 0 ]; then
    echo "Export failed with exit code $GODOT_EXIT"
    exit $GODOT_EXIT
  fi
fi

# Android Keystore
if [[ "$ISANDROID" == "true" && "$DEBUG" == "false" ]]; then
  cp "$RELEASE_KEYSTORE_PATH" export/android/ 2>/dev/null || true
fi

zip -r -7 "$FILE_BASENAME-build.zip" export/
