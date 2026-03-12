checkForUpdates() {
  if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then return 0; fi

  if [ -f "$LAST_CHECK_FILE" ]; then
    last_check_time=$(cat "$LAST_CHECK_FILE")
    if [[ "$last_check_time" =~ ^[0-9]+$ ]]; then
      current_time=$(date +%s)
      time_diff=$((current_time - last_check_time))
      if [ "$time_diff" -lt "$CHECK_INTERVAL" ]; then
        return
      fi
    fi
  fi

  echo "Checking for updates..."
  date +%s >"$LAST_CHECK_FILE"

  if ! LATEST_VERSION=$(gh api repos/$UPSTREAM_REPO/releases/latest --jq .tag_name 2>/dev/null); then
    echo -e "\e[1;33m[WARNING]\e[0m Could not fetch releases. Are you offline?"
    return
  fi

  if [ -z "$LATEST_VERSION" ]; then
    echo -e "\e[1;33m[WARNING]\e[0m No releases found. Skipping update check."
    return
  fi

  highest_version=$(printf "%s\n%s" "$VERSION" "$LATEST_VERSION" | sort -V | tail -n1)

  if [ "$highest_version" = "$LATEST_VERSION" ] && [ "$LATEST_VERSION" != "$VERSION" ]; then
    echo -e "\e[1;32m[UPDATE]\e[0m A new version ($LATEST_VERSION) is available. You are on version $VERSION."
    read -p "Do you want to update now? (Y/n): " confirm_update
    confirm_update=${confirm_update,,}
    confirm_update=${confirm_update:-"y"}

    if [[ "$confirm_update" =~ ^y(e?s)?$ ]]; then
      echo "Updating..."
      SCRIPT_PATH=$(readlink -f "$0")
      TEMP_FILE=$(mktemp)
      TEMP_HASH_FILE=$(mktemp)

      echo "Downloading new version..."
      if ! gh release download "$LATEST_VERSION" --repo "$UPSTREAM_REPO" --pattern 'gdx.sh' --clobber --output "$TEMP_FILE"; then
        echo -e "\e[1;31m[ERROR]\e[0m Failed to download the script file."
        rm -f "$TEMP_FILE" "$TEMP_HASH_FILE"
        exit 1
      fi

      echo "Downloading checksum..."
      if ! gh release download "$LATEST_VERSION" --repo "$UPSTREAM_REPO" --pattern 'gdx.sh.sha256' --clobber --output "$TEMP_HASH_FILE"; then
        echo -e "\e[1;31m[ERROR]\e[0m Failed to download the checksum file. Cannot verify integrity."
        rm -f "$TEMP_FILE" "$TEMP_HASH_FILE"
        exit 1
      fi

      echo "Verifying file integrity..."
      REMOTE_HASH=$(cat "$TEMP_HASH_FILE" | awk '{print $1}')
      LOCAL_HASH=$(sha256sum "$TEMP_FILE" | awk '{print $1}')

      if [ "$REMOTE_HASH" = "$LOCAL_HASH" ]; then
        echo -e "\e[38;2;61;220;132mChecksum PASSED.\e[0m"
        mv "$TEMP_FILE" "$SCRIPT_PATH"
        chmod +x "$SCRIPT_PATH"
        rm -f "$TEMP_HASH_FILE"
        echo -e "\e[1;32mUpdate successful! Please run the script again.\e[0m"
        exit 0
      else
        echo -e "\e[1;31m[ERROR] CHECKSUM FAILED!\e[0m The downloaded file may be corrupt. Aborting update."
        rm -f "$TEMP_FILE" "$TEMP_HASH_FILE"
        exit 1
      fi
    else
      echo "Update skipped."
    fi
  fi
}
