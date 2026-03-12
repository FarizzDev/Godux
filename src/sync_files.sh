syncFiles() {
  echo -e "${INFO} Syncing workflow files to script version ($VERSION)..."

  TEMP_HASH_FILE=$(mktemp)
  TEMP_ZIP=$(mktemp)

  # Download checksum
  if ! gh release download "$VERSION" --repo "$UPSTREAM_REPO" --pattern 'godux-scripts.zip.sha256' --clobber --output "$TEMP_HASH_FILE" >/dev/null 2>&1; then
    echo -e "${WARN} Could not find 'godux-scripts.zip.sha256' for version $VERSION. Cannot guarantee workflow integrity."
    if [[ ! -f ".github/workflows/export.yml" ]]; then
      echo -e "${ERROR} And no local workflow file exists. Aborting."
      rm -f "$TEMP_HASH_FILE"
      exit 1
    fi
    rm -f "$TEMP_HASH_FILE"
    return
  fi

  REMOTE_HASH=$(awk '{print $1}' "$TEMP_HASH_FILE")
  rm -f "$TEMP_HASH_FILE"

  LOCAL_HASH=""
  if [[ -f ".github/godux-scripts.zip.sha256" ]]; then
    LOCAL_HASH=$(awk '{print $1}' ".github/godux-scripts.zip.sha256")
  fi

  if [ "$LOCAL_HASH" = "$REMOTE_HASH" ]; then
    return
  fi

  echo -e "${INFO} Local files are out of sync or missing. Downloading..."

  # Download zip
  if ! gh release download "$VERSION" --repo "$UPSTREAM_REPO" --pattern 'godux-scripts.zip' --clobber --output "$TEMP_ZIP" >/dev/null 2>&1; then
    echo -e "${ERROR} Failed to download scripts for version $VERSION. Aborting."
    rm -f "$TEMP_ZIP"
    exit 1
  fi

  # Verify checksum
  DOWNLOAD_HASH=$(sha256sum "$TEMP_ZIP" | awk '{print $1}')
  if [ "$DOWNLOAD_HASH" != "$REMOTE_HASH" ]; then
    echo -e "${ERROR} CHECKSUM FAILED! The downloaded file may be corrupt. Aborting."
    rm -f "$TEMP_ZIP"
    exit 1
  fi

  mkdir -p .github/workflows .github/scripts/lib
  unzip -q "$TEMP_ZIP" -d .github/
  rm -f "$TEMP_ZIP"

  echo "$REMOTE_HASH" >.github/godux-scripts.zip.sha256

  echo -e "${SUCCESS} \e[38;2;61;220;132mFiles synced successfully to version $VERSION.\e[0m"
}
