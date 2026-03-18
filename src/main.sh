#!/usr/bin/env bash
# MIT License (see LICENSE)
# Copyright (c) 2025 FarizzDev
set -euo pipefail

# Auto-Update
readonly VERSION="v1.0.0"
readonly UPSTREAM_REPO="FarizzDev/Godux"
readonly CHECK_INTERVAL=86400 # 24 hours in seconds
readonly LAST_CHECK_FILE=~/.godux_last_check

CONFIG_FILE=".godux/config"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[94m'
CYAN='\033[0;36m'
RESET='\033[0m'

# Prefix symbols
INFO="${BLUE}[INFO]${RESET}"
WARN="${YELLOW}[!]${RESET}"
ERROR="${RED}[✗]${RESET}"
SUCCESS="${GREEN}[✓]${RESET}"
PROMPT="${CYAN}[?]${RESET}"

catch_error() {
  local exit_code=$?
  local line_no=$1
  local command_failed=$2

  echo -e "${ERROR} Script failed at line ${line_no}: '${command_failed}' (Exit code: ${exit_code})"
}

endProgram() {
  exitcode=$?
  trap - INT TERM EXIT
  printf "\nCleaning up...\n"
  echo "Removing repository secrets..."
  gh secret delete KEYSTORE_USER &>/dev/null || true
  gh secret delete KEYSTORE_PASS &>/dev/null || true
  gh secret delete RELEASE_KEYSTORE_BASE64 &>/dev/null || true
  gh secret delete EXPORT_CREDENTIALS &>/dev/null || true
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

trap 'catch_error $LINENO "$BASH_COMMAND"' ERR
trap endProgram INT TERM EXIT

source ./update_check.sh
source ./sync_files.sh
source ./env_check.sh

checkForUpdates
syncFiles

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
  echo -e "${INFO} Local changes detected. Uploading changes..."
  git add .
  git commit -m "Export Project"
  git push -u origin main -q
else
  # If no local changes, check if remote is in sync
  echo -e "${WARN} No local changes found. Checking remote repository..."
  git fetch -q

  LOCAL=$(git rev-parse HEAD)
  REMOTE=$(git rev-parse @{u})

  if [ "$LOCAL" == "$REMOTE" ]; then
    echo -ne "${PROMPT} No changes detected. Force rebuild? (Y/n): "
    read confirm_rerun
    confirm_rerun=${confirm_rerun,,}
    confirm_rerun=${confirm_rerun:-y}
    if [[ ! "$confirm_rerun" =~ ^y(e?s)?$ ]]; then
      echo "Aborting."
      exit 0
    fi
  else
    # This case happens if the local branch is ahead/behind but the working dir is clean.
    echo -e "${WARN} Local repository is not in sync with remote. Pushing..."
    git push -u origin main -q
  fi
fi

## Run export.yml workflow
source ./select_platform.sh

# Function to validate URL
validate_url() {
  if [[ -n "$1" && ! "$1" =~ ^https?:// ]]; then
    echo -e "${ERROR} Invalid URL format for $2. It must start with http:// or https://"
    exit 1
  fi
}

if [ -f "$CONFIG_FILE" ]; then
  source "$CONFIG_FILE"
fi

printf "\n"
# Input links
DEFAULT_GODOT=${GODOT_LINK:-"https://github.com/godotengine/godot/releases/download/3.6-stable/Godot_v3.6-stable_linux_headless.64.zip"}
DEFAULT_TEMPLATES=${TEMPLATES_LINK:-"https://github.com/godotengine/godot/releases/download/3.6-stable/Godot_v3.6-stable_export_templates.tpz"}

DEFAULT_GODOT_VERSION=$(echo "$DEFAULT_GODOT" | grep -oP '\d+[\d.]*-\w+' | head -1)
DEFAULT_TEMPLATES_VERSION=$(echo "$DEFAULT_TEMPLATES" | grep -oP '\d+[\d.]*-\w+' | head -1)

echo -ne "${PROMPT} Enter Godot link (default: $DEFAULT_GODOT_VERSION): "
read godot_link
godot_link=${godot_link:-$DEFAULT_GODOT}
validate_url "$godot_link" "Godot link"

echo -ne "${PROMPT} Enter Templates link (default: $DEFAULT_TEMPLATES_VERSION): "
read templates_link
templates_link=${templates_link:-$DEFAULT_TEMPLATES}
validate_url "$templates_link" "Templates link"

# Save config
mkdir -p .godux
cat >"$CONFIG_FILE" <<EOF
GODOT_LINK="$godot_link"
TEMPLATES_LINK="$templates_link"
EOF

DEFAULT_BASENAME=$(grep -oP '(?<=config/name=")[^"]+' project.godot 2>/dev/null | tr ' ' '_')

echo -ne "${PROMPT} Enter a file name for output files (default: ${DEFAULT_BASENAME:-MyGame}): "
read file_basename
file_basename=${file_basename:-${DEFAULT_BASENAME:-MyGame}}

# Debug and Cache input
echo -ne "${PROMPT} Enable debug? (y/N): "
read debug
debug=${debug,,}
debug=${debug:-"n"}
debug=$([[ "$debug" =~ ^y(e?s)?$ ]] && echo true || echo false)

echo -ne "${PROMPT} Enable cache? (Y/n): "
read cache
cache=${cache,,}
cache=${cache:-"y"}
cache=$([[ "$cache" =~ ^y(e?s)?$ ]] && echo true || echo false)

# Android requirements
if [[ "$platform" == "Android" || "$preset_name" == $'[ Export All Preset ]\u2063' ]]; then
  if [ "$preset_name" = $'[ Export All Preset ]\u2063' ]; then
    if perl .github/scripts/lib/parse_presets.pl has_android; then
      ISANDROID=true
    else
      ISANDROID=false
    fi
  else
    if perl .github/scripts/lib/parse_presets.pl is_android "$preset_name"; then
      ISANDROID=true
    else
      ISANDROID=false
    fi
  fi

  if [[ "$ISANDROID" == "true" && "$debug" == "false" ]]; then

    if [ "$preset_name" = $'[ Export All Preset ]\u2063' ]; then
      FIRST_ANDROID=$(perl .github/scripts/lib/parse_presets.pl all_android | head -1)
      if [ -n "$FIRST_ANDROID" ]; then
        user=$(perl .github/scripts/lib/parse_presets.pl keystore "$FIRST_ANDROID" release_user)
        keypass=$(perl .github/scripts/lib/parse_presets.pl keystore "$FIRST_ANDROID" release_password)
      fi
    else
      user=$(perl .github/scripts/lib/parse_presets.pl keystore "$preset_name" release_user)
      keypass=$(perl .github/scripts/lib/parse_presets.pl keystore "$preset_name" release_password)
    fi

    if [ -z "$user" ] || [ -z "$keypass" ]; then
      printf "\n"
      echo -e "${ERROR} Release keystore credentials not found in preset."
      echo -e "${INFO} Please set keystore/release_user and keystore/release_password in your export preset."
      exit 1
    fi

    echo -ne "${PROMPT} Do you have a keystore file? (y/N): "
    read has_keystore
    has_keystore=${has_keystore,,}
    has_keystore=${has_keystore:-n}

    if [[ "$has_keystore" =~ ^y(e?s)?$ ]]; then
      while true; do
        echo -ne "${PROMPT} Enter the path to your keystore file: "
        read -e keystore_path

        if [ -f "$keystore_path" ]; then
          break
        fi

        echo -e "${ERROR} Keystore file not found at '$keystore_path'"
      done

      echo -e "${INFO} Encoding and setting keystore secret..."
      keystore_base64=$(base64 -w 0 "$keystore_path")
      gh secret set RELEASE_KEYSTORE_BASE64 --body "$keystore_base64"
    else
      echo -e "${INFO} No existing keystore. We will generate a new one.\n"
      echo -ne "${PROMPT} Enter Certificate CN (e.g., Your Name, Your Company): "
      read cert_cn
      echo -ne "${PROMPT} Enter Organization (O) (optional): "
      read org
      echo -ne "${PROMPT} Enter Organizational Unit (OU) (optional): "
      read org_unit
      echo -ne "${PROMPT} Enter City/Locality (L) (optional): "
      read city
      echo -ne "${PROMPT} Enter State/Province (ST) (optional): "
      read state
      echo -ne "${PROMPT} Enter 2-letter Country Code (C) (optional): "
      read country
    fi
  elif [[ "$ISANDROID" == "true" ]]; then
    user="androiddebugkey"
    keypass="android"
    cert_cn="Android Debug"
  fi

  user=${user:-""}
  keypass=${keypass:-""}
  if [ -n "$user" ] && [ -n "$keypass" ]; then
    printf "\n"
    echo "Setting repository secrets..."
    gh secret set KEYSTORE_USER --body "$user"
    gh secret set KEYSTORE_PASS --body "$keypass"
  fi
fi

if [ -f ".godot/export_credentials.cfg" ]; then
  gh secret set EXPORT_CREDENTIALS --body "$(base64 -w 0 .godot/export_credentials.cfg)"
fi

printf "\n"
# Run workflow
echo -e "\e[38;2;61;220;132m# Running workflow...\e[0m"
args=("export.yml")

# Add fields if inputs are present
for FIELD in godot_link templates_link preset_name debug cache file_basename cert_cn org org_unit city state country; do
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
  MAX_RETRY=5
  RETRY=0
  CURRENT_STEPS=""

  while [ $RETRY -lt $MAX_RETRY ]; do
    CURRENT_STEPS=$(gh api repos/$GITHUB_USERNAME/$REPO_NAME/actions/runs/$WORKFLOW_ID/jobs \
      --jq '.jobs[].steps[] | {name: .name, conclusion: .conclusion, status: .status}' 2>/dev/null)
    if [ $? -eq 0 ]; then
      break
    fi
    RETRY=$((RETRY + 1))
    echo -e "${WARN} Connection error. Retrying ($RETRY/$MAX_RETRY)..."
    sleep 3
  done

  if [ $RETRY -eq $MAX_RETRY ] && [ -z "$CURRENT_STEPS" ]; then
    echo -e "${ERROR} Failed to connect to GitHub after $MAX_RETRY attempts."
    exit 1
  fi

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
    echo -e "\n${INFO} \e[38;2;61;220;132mWorkflow completed."
    break
  fi

  sleep 0.2
done

# Check if workflow was successful
CONCLUSION=$(gh run view "$WORKFLOW_ID" --json conclusion -q '.conclusion')
if [[ "$CONCLUSION" == "success" ]]; then
  echo -e "${SUCCESS} Workflow succeeded!\e[0m"
  printf "\n"

  if [[ "$preset_name" == $'[ Export All Preset ]\u2063' ]]; then
    gh run view "$WORKFLOW_ID" | grep -E "\[!\] Export failed" | sed 's/.*\[!\]/[!]/' || true
    printf "\n"
  fi

  RELEASE_TAG="build-$WORKFLOW_ID"
  echo -e "${SUCCESS} Build has been published as a release with tag: $RELEASE_TAG"

  # Get asset info from the release
  ASSET_INFO=$(gh release view "$RELEASE_TAG" --json assets --jq '.assets[] | {name: .name, size: .size}')
  ASSET_NAME=$(echo "$ASSET_INFO" | jq -r '.name')
  ASSET_SIZE=$(echo "$ASSET_INFO" | jq -r '.size')

  if [[ -n "$ASSET_NAME" ]]; then
    export_dir="./export"
    mkdir -p "$export_dir"

    ASSET_SIZE_MB=$(echo "scale=2; $ASSET_SIZE / 1024 / 1024" | bc)
    echo -e "${INFO} Release asset '$ASSET_NAME' is available with size: ${ASSET_SIZE_MB} MB"
    printf "\n"
    echo -e "${INFO} run \033[36mgh release download $RELEASE_TAG --dir $export_dir\e[0m to download later"

    # Confirm download
    echo -ne "${PROMPT} Do you want to download the result now? (Y/n): "
    read CONFIRM_DOWNLOAD
    CONFIRM_DOWNLOAD=${CONFIRM_DOWNLOAD,,}
    CONFIRM_DOWNLOAD=${CONFIRM_DOWNLOAD:-"y"}
    if [[ "$CONFIRM_DOWNLOAD" =~ ^y(e?s)?$ ]]; then
      echo -e "${INFO} Downloading release asset..."
      gh release download "$RELEASE_TAG" --dir "$export_dir"
      echo -e "${SUCCESS} Asset successfully downloaded to \033[36m$export_dir\e[0m."
    else
      echo -e "\e[31mDownload canceled.\e[0m"
    fi
    printf "\n"
  else
    echo -e "${ERROR} Could not find asset in release '$RELEASE_TAG'!"
  fi
else
  echo -e "${ERROR} ${RED}Workflow failed with status: $CONCLUSION${RESET}"
  printf "\n"

  gh run view $WORKFLOW_ID --log-failed |
    tr -d '\r' |
    grep -Ev 'at:|VisualServer' |
    sed '1,/##\[endgroup\]/d' |
    sed 's/[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}T[0-9:.]\+Z //'
fi
