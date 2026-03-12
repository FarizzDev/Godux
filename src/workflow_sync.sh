syncWorkflow() {
  echo "Syncing workflow files to script version ($VERSION)..."
  WORKFLOW_FILE=".github/workflows/export.yml"

  TEMP_REMOTE_HASH_FILE=$(mktemp)
  if ! gh release download "$VERSION" --repo "$UPSTREAM_REPO" --pattern 'export.yml.sha256' --clobber --output "$TEMP_REMOTE_HASH_FILE" >/dev/null 2>&1; then
    echo -e "\e[1;33m[WARNING]\e[0m Could not find 'export.yml.sha256' for version $VERSION. Cannot guarantee workflow integrity."
    if [[ ! -f "$WORKFLOW_FILE" ]]; then
      echo -e "\e[1;31m[ERROR]\e[0m And no local workflow file exists. Aborting."
      exit 1
    fi
    return
  fi
  REMOTE_HASH=$(cat "$TEMP_REMOTE_HASH_FILE" | awk '{print $1}')
  rm -f "$TEMP_REMOTE_HASH_FILE"

  LOCAL_HASH=""
  if [[ -f "$WORKFLOW_FILE" ]]; then
    LOCAL_HASH=$(sha256sum "$WORKFLOW_FILE" | awk '{print $1}')
  fi

  if [ "$LOCAL_HASH" = "$REMOTE_HASH" ]; then
    return
  fi

  echo "Local workflow is out of sync or missing. Downloading version for $VERSION..."
  TEMP_WORKFLOW_FILE=$(mktemp)
  if ! gh release download "$VERSION" --repo "$UPSTREAM_REPO" --pattern 'export.yml' --clobber --output "$TEMP_WORKFLOW_FILE"; then
    echo -e "\e[1;31m[ERROR]\e[0m Failed to download workflow file for version $VERSION. Aborting."
    exit 1
  fi

  DOWNLOAD_HASH=$(sha256sum "$TEMP_WORKFLOW_FILE" | awk '{print $1}')
  if [ "$DOWNLOAD_HASH" != "$REMOTE_HASH" ]; then
    echo -e "\e[1;31m[ERROR] CHECKSUM FAILED!\e[0m The downloaded workflow file is corrupt. Aborting."
    rm -f "$TEMP_WORKFLOW_FILE"
    exit 1
  fi

  echo -e "\e[38;2;61;220;132mWorkflow synced successfully to version $VERSION.\e[0m"
  mkdir -p .github/workflows
  mv "$TEMP_WORKFLOW_FILE" "$WORKFLOW_FILE"
}
