#!/bin/bash
set -e
mkdir -p export

if [[ "$DEBUG" == "true" ]]; then
  EXPORT_FLAG="--export-debug"
elif [[ "$GODOT_MAJOR" == "4" ]]; then
  EXPORT_FLAG="--export-release"
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
  "Android") echo "export/$s_folder/$FILE_BASENAME.$(perl .github/scripts/lib/parse_presets.pl export_format "$p_name")" ;;
  "Windows Desktop") echo "export/$s_folder/$FILE_BASENAME.exe" ;;
  "Linux") echo "export/$s_folder/$FILE_BASENAME" ;;
  "Linux/X11") echo "export/$s_folder/$FILE_BASENAME" ;;
  "macOS") echo "export/$s_folder/$FILE_BASENAME.zip" ;;
  "Mac OSX") echo "export/$s_folder/$FILE_BASENAME.zip" ;;
  "Web") echo "export/$s_folder/index.html" ;;
  "HTML5") echo "export/$s_folder/index.html" ;;
  "UWP") echo "export/$s_folder/$FILE_BASENAME.appx" ;;
  *) echo "export/$s_folder/$FILE_BASENAME.bin" ;;
  esac
}

if [ "$PRESET_NAME" = $'[ Export All Preset ]\u2063' ]; then
  # name|platform
  presets=$(perl .github/scripts/lib/parse_presets.pl list)

  SUCCEEDED=()
  FAILED=()

  while IFS='|' read -r p_name p_type; do
    echo "::group::>>> Exporting $p_name ($p_type)..."
    OUT=$(get_output_path "$p_name" "$p_type")
    godot --headless $EXPORT_FLAG "$p_name" "$OUT" 2>&1 | grep -v "VisualServer attempted to free a NULL RID\|at: free (servers/visual"
    GODOT_EXIT=${PIPESTATUS[0]}
    if [ $GODOT_EXIT -ne 0 ]; then
      echo "::notice::[!] Export failed for $p_name"
      FAILED+=("$p_name")
    else
      SUCCEEDED+=("$p_name")
    fi
    echo "::endgroup::"
  done <<<"$presets"

  if [ ${#SUCCEEDED[@]} -eq 0 ]; then
    echo "::error title=All exports failed!::[ERROR] All exports failed!"
    exit 1
  fi

  if [ ${#FAILED[@]} -gt 0 ]; then
    echo "::warning title=${#FAILED[@]} export(s) failed::${#FAILED[@]} export(s) failed - Failed: ${FAILED[*]}"
  fi
else
  # Export Single Preset
  echo "::group::>>> Exporting $PRESET_NAME..."

  PLATFORM=$(perl .github/scripts/lib/parse_presets.pl platform "$PRESET_NAME")

  OUT=$(get_output_path "$PRESET_NAME" "$PLATFORM")

  godot --headless $EXPORT_FLAG "$PRESET_NAME" "$OUT" 2>&1 | grep -v "VisualServer attempted to free a NULL RID\|at: free (servers/visual"
  GODOT_EXIT=${PIPESTATUS[0]}
  if [ $GODOT_EXIT -ne 0 ]; then
    echo "Export failed with exit code $GODOT_EXIT"
    echo "::endgroup::"
    exit $GODOT_EXIT
  fi
  echo "::endgroup::"
fi

# Android Keystore
if [[ "$ISANDROID" == "true" && "$DEBUG" == "false" ]]; then
  cp "$RELEASE_KEYSTORE_PATH" export/android/ 2>/dev/null || true
fi

echo "::group::>>> Packing results..."
cd export/

RESULT_FILE_NAME=""
if [ "$PRESET_NAME" = $'[ Export All Preset ]\u2063' ]; then
  RESULT_FILE_NAME="${FILE_BASENAME}-all_presets_$(date +"%Y%m%d-%H%M%S").zip"
else
  PRESET_SLUG=$(echo "$PRESET_NAME" | tr ' /' '_' | tr '[:upper:]' '[:lower:]')
  RESULT_FILE_NAME="${FILE_BASENAME}-${PRESET_SLUG}_$(date +"%Y%m%d-%H%M%S").zip"
fi

echo "RESULT_FILE_NAME=$RESULT_FILE_NAME" >>"$GITHUB_ENV"
zip -r -7 "../${RESULT_FILE_NAME}" ./*
cd ..
echo "::endgroup::"
