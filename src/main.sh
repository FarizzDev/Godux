#!/usr/bin/env bash
# MIT License (see LICENSE)
# Copyright (c) 2025 FarizzDev
set -euo pipefail

# Auto-Update
VERSION="v0.7.0"
UPSTREAM_REPO="FarizzDev/Godux"
CHECK_INTERVAL=86400 # 24 hours in seconds
LAST_CHECK_FILE=~/.godux_last_check

source ./update_check.sh
source ./workflow_sync.sh
source ./env_check.sh

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

source ./header.sh
source ./git_init.sh

# Check for changes before committing and pushing
printf "\n"
echo -e "\e[38;2;61;220;132m# Checking for code changes...\e[0m"

# First, check for uncommitted local changes
if [ -n "$(git status --porcelain)" ]; then
  echo -e "\e[1;34m[INFO]\e[0m Local changes detected. Uploading changes..."
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
    read -p "No changes detected. Force rebuild? (y/N): " confirm_rerun
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

## Run export.yml workflow
source ./select_platform.sh

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
debug=${debug,,}
debug=${debug:-"n"}
debug=$([[ "$debug" =~ ^y(e?s)?$ ]] && echo true || echo false)

read -p "Enable cache? (Y/n): " cache
cache=${cache,,}
cache=${cache:-"y"}
cache=$([[ "$cache" =~ ^y(e?s)?$ ]] && echo true || echo false)

# Android requirements
if [[ "$platform" == "Android" || "$preset_name" == $'[ Export All Preset ]\u2063' ]]; then
  python3 .github/scripts/lib/parse_presets.py is_android "$preset_name" && ISANDROID=true || ISANDROID=false

  if [[ "$ISANDROID" == "true" && ! "$debug" == "true" ]]; then
    read -p "Do you have an existing release.keystore file? (y/N): " has_keystore
    has_keystore=${has_keystore,,}
    has_keystore=${has_keystore:-n}

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
