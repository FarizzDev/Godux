#!/usr/bin/env bash
# MIT License (see LICENSE)
# Copyright (c) 2025 FarizzDev

# Auto-Update
VERSION="v0.7.0"
UPSTREAM_REPO="FarizzDev/Godux"
CHECK_INTERVAL=86400 # 24 hours in seconds
LAST_CHECK_FILE=~/.godux_last_check

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

syncWorkflow() {
  echo "Syncing workflow file to script version ($VERSION)..."
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

# Dependency installation
install_dependencies() {
  echo -e "\e[38;2;61;220;132m# Checking for dependencies...\e[0m"

  # Check for required commands
  local missing_deps=()
  for cmd in git gh fzf bc jq; do
    if ! command -v "$cmd" &>/dev/null; then
      missing_deps+=("$cmd")
    fi
  done

  if [ ${#missing_deps[@]} -eq 0 ]; then
    echo "All dependencies are already installed."
    return
  fi

  echo -e "\e[1;33m[WARNING]\e[0m The following dependencies are missing: ${missing_deps[*]}"
  read -p "Do you want to try and install them? (Y/n): " confirm_install
  confirm_install=${confirm_install,,}
  confirm_install=${confirm_install:-"y"}
  if [[ ! "$confirm_install" =~ ^y(e?s)?$ ]]; then
    echo -e "\e[1;34m[INFO]\e[0m Please install the missing dependencies manually and rerun the script."
    exit 1
  fi

  # Determine package manager
  local SUDO=""
  if [[ $EUID -ne 0 ]] && command -v sudo &>/dev/null; then
    SUDO="sudo"
  fi

  if command -v apt-get &>/dev/null; then
    echo -e "\e[1;34m[INFO]\e[0m Attempting to install using 'apt'..."
    $SUDO apt-get update
    $SUDO apt-get install -y git gh fzf bc jq
  elif command -v brew &>/dev/null; then
    echo -e "\e[1;34m[INFO]\e[0m Attempting to install using 'brew'..."
    brew install git gh fzf bc jq
  elif command -v pacman &>/dev/null; then
    echo -e "\e[1;34m[INFO]\e[0m Attempting to install using 'pacman'..."
    $SUDO pacman -S --noconfirm git github-cli fzf bc jq
  elif command -v dnf &>/dev/null; then
    echo -e "\e[1;34m[INFO]\e[0m Attempting to install using 'dnf'..."
    $SUDO dnf install -y git gh fzf bc jq
  elif command -v pkg &>/dev/null; then
    echo -e "\e[1;34m[INFO]\e[0m Attempting to install using 'pkg'..."
    pkg install -y git gh fzf bc jq
  else
    echo -e "\e[1;31m[ERROR]\e[0m Could not detect a supported package manager (apt, brew, pacman, dnf, pkg)."
    echo "Please install the missing dependencies manually: ${missing_deps[*]}"
    exit 1
  fi

  # Verify installation
  for cmd in git gh fzf bc jq; do
    if ! command -v "$cmd" &>/dev/null; then
      echo -e "\e[1;31m[ERROR]\e[0m Failed to install '$cmd'. Please install it manually and rerun the script."
      exit 1
    fi
  done

  echo -e "\e[38;2;61;220;132m# Dependencies installed successfully.\e[0m"
}

printf "\n"
install_dependencies

set -euo pipefail

# Cleanup function to remove secrets
endProgram() {
  exitcode=$?
  trap - INT TERM EXIT
  printf "\nCleaning up...\n"
  if [[ -n "${user:-}" ]]; then
    echo "Removing repository secrets..."
    gh secret delete KEYSTORE_USER &>/dev/null
    gh secret delete KEYSTORE_PASS &>/dev/null
  fi
  unset GITHUB_TOKEN
  unset keypass

  echo -e "\e[38;2;61;220;132mThank you for using this tool!"

  # Footer and Credits
  echo -e "\n\e[38;2;255;165;0m=========================================\e[0m"
  echo -e "\e[38;2;255;255;0m Author:\e[0m"
  echo -e "  GitHub: https://github.com/FarizzDev"
  echo -e "  YouTube: https://youtube.com/ziraFCode"
  echo -e "\e[38;2;255;165;0m=========================================\e[0m"

  exit $exitcode
}

# Trap interrupts and exits
trap endProgram INT TERM EXIT

checkForUpdates
syncWorkflow

# Platform colors
ANDROID="\e[38;2;61;220;132m"
IOS="\e[38;2;163;170;174m"
HTML5="\e[38;2;228;77;38m"
MAC_OSX="\e[38;2;176;179;184m"
UWP="\e[38;2;0;188;242m"
WINDOWS="\e[38;2;0;120;215m"
LINUX="\e[38;2;233;84;32m"
ALL=$'\e[38;2;255;255;255m[ Export All Preset ]\u2063'

# Header
echo -e "\e[38;2;72;118;255m"
cat <<"EOF"
           ____  ___  ____  _   ___  __
          / ___|/ _ \|  _ \| | | \ \/ /
         | |  _| | | | | | | | | |\  /
         | |_| | |_| | |_| | |_| |/  \
          \____|\___/|____/ \___//_/\_\
EOF
echo -e "\e[0m"
echo -e "             \e[38;2;255;255;255mGodot Universal eXport\e[0m"
echo ""
echo -e "\e[38;2;255;255;0m Export Godot Projects From Anywhere, To Anywhere.\e[0m"
echo -e "\e[38;2;72;118;255m====================================================\e[0m"

if [[ ! -e "export_presets.cfg" ]]; then
  printf "\n\e[1;31m[ERROR]\e[0m Can't find export_presets.cfg. Exiting.\n"
  exit 1
fi

printf "\n"
if [ -z "$(git config --get-all user.name)" ]; then
  read -p "Git username: " name
  git config --global user.name "$name"
fi
if [ -z "$(git config --get-all user.email)" ]; then
  read -p "Git email: " email
  git config --global user.email "$email"
fi
# Authenticate with GitHub
if ! gh auth status &>/dev/null; then
  echo -e "\e[1;34m[INFO]\e[0m GitHub CLI not authenticated."
  gh auth login
fi

GITHUB_USERNAME="$(gh api user --jq .login)"
if [[ -z "$GITHUB_USERNAME" ]]; then
  echo -e "\e[1;31m[ERROR]\e[0m Failed to get GitHub username. Please check your authentication."
  exit 1
else
  echo -e "\e[1;34m[INFO]\e[0m Authenticated as $GITHUB_USERNAME"
fi

CWD=$(readlink -f .)
if ! git config --get-all safe.directory | grep -q "^$CWD"; then
  git config --global --add safe.directory "$CWD"
fi
if [ ! -d "$CWD/.git" ]; then
  read -p "Enter the name for the new repository: " REPO_NAME
  printf "\n"
  echo "Creating new repository..."
  gh repo create "$REPO_NAME" --private
  git init
  git branch -M main
  git remote add origin "https://github.com/$GITHUB_USERNAME/$REPO_NAME.git"
else
  REPO_NAME=$(basename -s .git "$(git remote get-url origin)")
fi

# Check for changes before committing and pushing
printf "\n"
echo -e "\e[38;2;61;220;132m# Checking for code changes...\e[0m"

# First, check for uncommitted local changes
if [ -n "$(git status --porcelain)" ]; then
  echo -e "\e[1;34m[INFO]\e[0m Local changes detected. Committing and pushing..."
  git add .
  git commit -m "Export Project"
  git push -u origin main
else
  # If no local changes, check if remote is in sync
  echo -e "\e[1;33m[WARNING]\e[0m No local changes found. Checking remote repository..."
  git fetch

  LOCAL=$(git rev-parse HEAD)
  REMOTE=$(git rev-parse @{u})

  if [ "$LOCAL" == "$REMOTE" ]; then
    echo "Repository is already up to date. No changes to push."
    read -p "Do you want to re-run the workflow on the existing code? (y/N): " confirm_rerun
    confirm_rerun=${confirm_rerun,,}
    confirm_rerun=${confirm_rerun:-n}
    if [[ ! "$confirm_rerun" =~ ^y(e?s)?$ ]]; then
      echo "Aborting."
      exit 0
    fi
  else
    # This case happens if the local branch is ahead/behind but the working dir is clean.
    echo -e "\e[1;33m[WARNING]\e[0m Local repository is not in sync with remote. Pushing..."
    git push -u origin main
  fi
fi

# Run export.yml workflow

# Get all preset names and their platforms
presets_with_platforms=$(awk '
  BEGIN { FS = "[[:space:]]*=[[:space:]]*" }
  /^\[preset\./ { if (n&&p) print n"|"p; n=""; p="" }
  /^name/ { n=$2; gsub(/"/,"",n) }
  /^platform/ { p=$2; gsub(/"/,"",p) }
  END { if (n&&p) print n"|"p }
' export_presets.cfg)

options=()
options+=("$ALL")

while IFS='|' read -r name platform_type; do
  if [ -z "$name" ] || [ -z "$platform_type" ]; then
    continue
  fi

  case "$platform_type" in
  Android) color_prefix=$ANDROID ;;
  iOS) color_prefix=$IOS ;;
  HTML5) color_prefix=$HTML5 ;;
  "Mac OSX") color_prefix=$MAC_OSX ;;
  UWP) color_prefix=$UWP ;;
  "Windows Desktop") color_prefix=$WINDOWS ;;
  "Linux/X11") color_prefix=$LINUX ;;
  *) color_prefix="" ;;
  esac
  color_suffix="\e[0m"

  if [ -n "$color_prefix" ]; then
    options+=("$(echo -e "${color_prefix}${name}${color_suffix}")")
  else
    options+=("$name")
  fi
done <<<"$presets_with_platforms"

presetname_raw=$(printf "%b\n" "${options[@]}" | fzf --ansi --no-sort --prompt="Select a platform: ")
preset_name=$(echo "$presetname_raw" | sed -r 's/\x1B\[[0-9;:]*[mK]//g')
platform=$(awk -v ref="$preset_name" '
  /^\[preset\./ { n=""; p="" }
  /^name=/      { n=$0; gsub(/.*="/,"",n); gsub(/".*/,"",n) }
  /^platform=/  { p=$0; gsub(/.*="/,"",p); gsub(/".*/,"",p) }
  n==ref && p { print p; exit }
' export_presets.cfg)

if [ -z "$preset_name" ]; then
  echo -e "\e[1;31m[ERROR]\e[0m No platform selected. Exiting."
  exit 1
fi

# Function to validate URL
validate_url() {
  if [[ -n "$1" && ! "$1" =~ ^https?:// ]]; then
    echo -e "\e[1;31m[ERROR]\e[0m Invalid URL format for $2. It must start with http:// or https://"
    exit 1
  fi
}

printf "\n"
# Input links
read -p "Enter Godot link (default Godot v3.6-stable): " godot_link
validate_url "$godot_link" "Godot link"

read -p "Enter Templates link (default Godot v3.6-stable): " templates_link
validate_url "$templates_link" "Templates link"

# Debug and Cache input
read -p "Enter a base name for output files (e.g., MyGame): " file_basename
read -p "Enable debug? (y/N): " debug
debug=${debug,,} # Convert to lowercase
debug=${debug:-"n"}
debug=$([[ "$debug" =~ ^y(e?s)?$ ]] && echo true || echo false)

read -p "Enable cache? (Y/n): " cache
cache=${cache,,}
cache=${cache:-"y"}
cache=$([[ "$cache" =~ ^y(e?s)?$ ]] && echo true || echo false)

# Android requirements
if [[ "$platform" == "Android" || "$preset_name" == $'[ Export All Preset ]\u2063' ]]; then
  ISANDROID=$(awk -F= '
    BEGIN { IGNORECASE=1 }
    /^\[preset\.[0-9]+\]$/ { in_preset=1; next }
    /^\[/ && $0 !~ /^\[preset\.[0-9]+\]$/ { in_preset=0 }
    in_preset && /platform/ && $2 ~ /Android/ { print "true"; exit }
  ' export_presets.cfg)

  if [[ "$ISANDROID" == "true" && ! "$debug" == "true" ]]; then
    read -p "Do you have an existing release.keystore file? (y/N): " has_keystore
    has_keystore=${has_keystore,,}
    has_keystore=${has_keystore:-\"n\"}

    if [[ "$has_keystore" =~ ^y(e?s)?$ ]]; then
      read -p "Enter the path to your release.keystore file: " keystore_path
      if [ ! -f "$keystore_path" ]; then
        echo "Error: Keystore file not found at '$keystore_path'"
        exit 1
      fi
      echo "Encoding and setting keystore secret..."
      keystore_base64=$(base64 -w 0 "$keystore_path")
      gh secret set RELEASE_KEYSTORE_BASE64 --body "$keystore_base64"
    else
      echo "No existing keystore. We will generate a new one."
      gh secret remove RELEASE_KEYSTORE_BASE64 &>/dev/null || true
      read -p "Enter Certificate CN (e.g., Your Name, Your Company): " cert_cn
      read -p "Enter Organization for Android (O, optional): " org
      read -p "Enter 2-letter Country Code for Android (C, optional): " country
    fi

    read -p "Enter 'user' alias for Android keystore: " user
    read -sp "Enter 'pass' for Android keystore: " keypass
    while [[ ${#keypass} -lt 6 ]]; do
      echo "Keypass must be at least 6 characters long."
      read -sp "Enter 'pass' for Android keystore: " keypass
    done
  else
    user="androiddebugkey"
    keypass="android"
    cert_cn="Android Debug"
  fi

  printf "\n"
  echo "Setting repository secrets..."
  gh secret set KEYSTORE_USER --body "$user"
  gh secret set KEYSTORE_PASS --body "$keypass"
fi

printf "\n"
# Run workflow
echo -e "\e[38;2;61;220;132m# Running workflow...\e[0m"
args=("export.yml")

# Add fields if inputs are present
for FIELD in godot_link templates_link preset_name debug cache file_basename cert_cn org country; do
  VALUE="${!FIELD-}"
  if [ -n "$VALUE" ]; then
    args+=("-f")
    args+=("$FIELD=$VALUE")
  fi
done

gh workflow run "${args[@]}"
sleep 3
WORKFLOW_ID=$(gh run list --limit 1 --json databaseId -q '.[0].databaseId')
printf "\n"

# Monitor the workflow until completion
DISPLAYED_STEPS=()
STEP_STATUSES=()
echo -e "\e[38;2;61;220;132m# Monitoring workflow steps...\e[0m"

while true; do
  # Fetch steps that are in progress or recently completed
  CURRENT_STEPS=$(gh api repos/$GITHUB_USERNAME/$REPO_NAME/actions/runs/$WORKFLOW_ID/jobs \
    --jq '.jobs[].steps[] | {name: .name, conclusion: .conclusion, status: .status}')

  if [[ -z "$CURRENT_STEPS" ]]; then
    sleep 1
    continue
  fi

  while IFS= read -r STEP; do
    NAME=$(echo "$STEP" | jq -r '.name // empty')
    STATUS=$(echo "$STEP" | jq -r '.status // empty')
    CONCLUS=$(echo "$STEP" | jq -r '.conclusion // empty')

    if [[ -n "$NAME" ]]; then
      # Update or add the step to DISPLAYED_STEPS
      FOUND=0
      for i in "${!DISPLAYED_STEPS[@]}"; do
        if [[ "${DISPLAYED_STEPS[i]}" == "$NAME" ]]; then
          FOUND=1
          if [[ "${STEP_STATUSES[i]}" != "$STATUS" ]]; then
            STEP_STATUSES[i]="$STATUS"
            if [[ "$STATUS" == "completed" && "$CONCLUS" != "skipped" ]]; then
              printf "\r\e[38;2;0;255;0m[COMPLETED]\e[0m %-30s\n" "$NAME"
            elif [[ "$CONCLUS" == "skipped" ]]; then
              printf "\r\e[38;2;255;165;0m[SKIPPED]\e[0m %-30s\n" "$NAME"
            fi
          fi
          break
        fi
      done
      if [[ "$FOUND" -eq 0 ]]; then
        DISPLAYED_STEPS+=("$NAME")
        STEP_STATUSES+=("$STATUS")
      fi
    fi
  done <<<"$CURRENT_STEPS"

  for i in "${!DISPLAYED_STEPS[@]}"; do
    NAME="${DISPLAYED_STEPS[i]}"
    STATUS="${STEP_STATUSES[i]}"

    if [[ "$STATUS" == "in_progress" ]]; then
      printf "\r\e[38;2;255;255;0m[RUNNING]\e[0m %-30s %s" "$NAME"
    fi
  done

  # Check workflow status to exit loop if completed
  WORKFLOW_STATUS=$(gh run view "$WORKFLOW_ID" --json status -q '.status')
  if [[ "$WORKFLOW_STATUS" == "completed" ]]; then
    echo -e "\n\e[38;2;61;220;132mWorkflow completed."
    break
  fi

  sleep 0.2
done

# Check if workflow was successful
CONCLUSION=$(gh run view "$WORKFLOW_ID" --json conclusion -q '.conclusion')
if [[ "$CONCLUSION" == "success" ]]; then
  echo -e "Workflow succeeded!\e[0m"
  printf "\n"

  RELEASE_TAG="build-$WORKFLOW_ID"
  echo "Build has been published as a release with tag: $RELEASE_TAG"

  # Get asset info from the release
  ASSET_INFO=$(gh release view "$RELEASE_TAG" --json assets --jq '.assets[] | {name: .name, size: .size}')
  ASSET_NAME=$(echo "$ASSET_INFO" | jq -r '.name')
  ASSET_SIZE=$(echo "$ASSET_INFO" | jq -r '.size')

  if [[ -n "$ASSET_NAME" ]]; then
    timestamp=$(date +"%Y%m%d_%H%M%S")
    export_dir="./export/$timestamp"
    mkdir -p "$export_dir"

    ASSET_SIZE_MB=$(echo "scale=2; $ASSET_SIZE / 1024 / 1024" | bc)
    echo "Release asset '$ASSET_NAME' is available with size: ${ASSET_SIZE_MB} MB"
    printf "\n"
    echo -e "run \033[36mgh release download $RELEASE_TAG --dir $export_dir\e[0m to download later"

    # Confirm download
    read -p "Do you want to download the result now? (Y/n): " CONFIRM_DOWNLOAD
    CONFIRM_DOWNLOAD=${CONFIRM_DOWNLOAD,,}
    CONFIRM_DOWNLOAD=${CONFIRM_DOWNLOAD:-"y"}
    if [[ "$CONFIRM_DOWNLOAD" =~ ^y(e?s)?$ ]]; then
      echo "Downloading release asset..."
      gh release download "$RELEASE_TAG" --dir "$export_dir"
      echo -e "Asset successfully downloaded to \033[36m$export_dir\e[0m."
    else
      echo -e "\e[31mDownload canceled.\e[0m"
    fi
    printf "\n"
  else
    echo "Could not find asset in release '$RELEASE_TAG'!"
  fi
else
  echo "Workflow failed with status: $CONCLUSION"
  printf "\n"
  if gh run view $WORKFLOW_ID --log-failed | grep -q "export"; then
    ERROR_MESSAGE=$(gh run view $WORKFLOW_ID --log-failed | grep -Ev 'at:|VisualServer' | sed '1,/##\[endgroup\]/d')
  else
    ERROR_MESSAGE=$(gh run view $WORKFLOW_ID --log-failed | sed '1,/##\[endgroup\]/d')
  fi
  echo $ERROR_MESSAGE
fi
