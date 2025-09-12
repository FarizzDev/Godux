#!/bin/bash

# Cleanup function to remove secrets
endProgram() {
    trap - INT TERM EXIT
    printf "\nCleaning up...\n"
    if [[ -n "$user" ]]; then
        echo "Removing repository secrets..."
        gh secret delete USER &>/dev/null
        gh secret delete KEYPASS &>/dev/null
    fi
    unset GITHUB_TOKEN
    unset keypass

    echo -e "\e[38;2;61;220;132mThank you for using this tool!"

    # Footer and Credits
    echo -e "\n\e[38;2;255;165;0m=========================================\e[0m"
    echo -e "\e[38;2;255;255;0m Author:\e[0m"
    echo -e "  GitHub: https://github.com/FarizzDev"
    echo -e "  YouTube: https://youtube.com/ziraFCode"
    echo -e "  WhatsApp Channel: https://whatsapp.com/channel/0029Vb6PKq6JkK7Bv8lYwK2I"
    echo -e "\e[38;2;255;165;0m=========================================\e[0m"

    exit
}

# Trap interrupts and exits
trap endProgram INT TERM EXIT

# Platform colors
ANDROID="\e[38;2;61;220;132mAndroid\e[0m"
IOS="\e[38;2;163;170;174miOS\e[0m"
HTML5="\e[38;2;228;77;38mHTML5\e[0m"
MAC_OSX="\e[38;2;176;179;184mMac OSX\e[0m"
UWP="\e[38;2;0;188;242mUWP\e[0m"
WINDOWS="\e[38;2;0;120;215mWindows Desktop\e[0m"
LINUX="\e[38;2;233;84;32mLinux/X11\e[0m"
ALL="\e[38;2;255;255;255mAll\e[0m"

# Header
echo -e "\e[38;2;72;118;255m"
cat << "EOF"
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


# Check for workflow file, download if it doesn't exist
if [[ ! -e ".github/workflows/export.yml" ]]; then
  echo -e "\e[1;33m[WARNING]\e[0m Workflow file not found. Downloading from Gist..."
  mkdir -p .github/workflows
  if curl -L "https://gist.githubusercontent.com/FarizzDev/0b4f5464adc00d3db3651960541dd647/raw/" -o .github/workflows/export.yml; then
    echo "Workflow downloaded successfully."
  else
    echo -e "\e[1;31m[ERROR]\e[0m Failed to download workflow file. Please check your internet connection."
    exit 1
  fi
fi
if [[ ! -e "export_presets.cfg" ]]; then
  printf "\n\e[1;31m[ERROR]\e[0m Can't find export_presets.cfg. Exiting.\n"
  exit 1
fi

printf "\n"
if [ -z $(git config --get-all user.name) ]; then
  read -p "Git username: " name
  git config --global user.name $name
fi
if [ -z $(git config --get-all user.email) ]; then
  read -p "Git email: " email
  git config --global user.email $email
fi
# Authenticate with GitHub
if ! gh auth status &>/dev/null; then
  echo -e "\e[1;34m[INFO]\e[0m GitHub CLI not authenticated."
  gh auth login
fi

GITHUB_USERNAME=$(gh api user --jq .login)
if [[ -z "$GITHUB_USERNAME" ]]; then
  echo -e "\e[1;31m[ERROR]\e[0m Failed to get GitHub username. Please check your authentication."
  exit 1
else
  echo -e "\e[1;34m[INFO]\e[0m Authenticated as $GITHUB_USERNAME"
fi

CWD=$(readlink -f .)
if ! git config --get-all safe.directory | grep -q "^$CWD"; then
  git config --global --add safe.directory $CWD
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
  REPO_NAME=$(basename -s .git $(git remote get-url origin))
fi

# Initialize git and push the first commit
printf "\n"
echo -e "\e[38;2;61;220;132m# Initializing local repository...\e[0m"

git add .
git commit -m "Export Project"
git push -u origin main

# Run export.yml workflow

# Get platforms from export_presets.cfg
# A simple, robust method to parse names and platforms
platforms=$(grep -oP '(?<=^platform=")[^"]*' export_presets.cfg)
names=$(grep -oP '(?<=^name=")[^"]*' export_presets.cfg)

# Combine the platforms and names, separated by a pipe
# Note: Using process substitution <() requires bash
parsed_platforms=$(paste -d'|' <(echo "$platforms") <(echo "$names"))

options=()
# Use a simple while loop with a pipe delimiter to read the pairs
while IFS='|' read -r key name; do
  # Skip any empty lines that might result from parsing
  if [ -z "$key" ] || [ -z "$name" ]; then
    continue
  fi

  case "$key" in
    Android)          color_var="$ANDROID" ;;
    iOS)              color_var="$IOS" ;;
    HTML5)            color_var="$HTML5" ;;
    "Mac OSX" | Mac)  color_var="$MAC_OSX" ;;
    UWP)              color_var="$UWP" ;;
    "Windows Desktop" | Windows) color_var="$WINDOWS" ;;
    "Linux/X11")      color_var="$LINUX" ;;
    *)                color_var="" ;; # No color for unknown platforms
  esac

  if [ -n "$color_var" ]; then
    # Apply color to the display name by replacing the placeholder text in the color variable
    options+=("$(echo -e "$color_var" | sed "s/m.*m/m$name/g")")
  else
    # Fallback for unknown platforms, no color
    options+=("$name")
  fi
done <<< "$parsed_platforms"

options+=("$ALL")

platform_raw=$(printf "%b\n" "${options[@]}" | fzf --ansi --prompt="Select a platform: ")
platform=$(echo "$platform_raw" | sed 's/\x1b\\[[0-9;]*m//g')

if [ -z "$platform" ]; then
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
read -p "Enable debug? (y/N): " debug
debug=${debug,,}  # Convert to lowercase
debug=${debug:-"n"}
debug=$( [[ "$debug" =~ ^y(e?s)?$ ]] && echo true || echo false)

read -p "Enable cache? (Y/n): " cache
cache=${cache,,}
cache=${cache:-"y"}
cache=$( [[ "$cache" =~ ^y(e?s)?$ ]] && echo true || echo false)

if [[ "$platform" == "Android" || "$platform" == "All" ]]; then
  ISANDROID=$(awk -F= '
    BEGIN { IGNORECASE=1 }
    /^\[preset\.[0-9]+\]$/ { in_preset=1; next }
    /^\[/ && $0 !~ /^\[preset\.[0-9]+\]$/ { in_preset=0 }
    in_preset && /platform/ && $2 ~ /Android/ { print "true"; exit }
  ' export_presets.cfg)

  if [[ "$ISANDROID" == "true" && ! "$debug" == "true" ]]; then
    read -p "Enter 'user' for Android keystore: " user
    read -sp "Enter 'pass' for Android keystore: " keypass
    while [[ ${#keypass} -lt 6 ]]; do
      echo "Keypass must be at least 6 characters long."
      read -sp "Enter 'pass' for Android keystore: " keypass
    done
  else
    user="androiddebugkey"
    keypass="android"
  fi

  printf "\n"
  echo "Setting repository secrets..."
  gh secret set USER --body "$user"
  gh secret set KEYPASS --body "$keypass"
fi

printf "\n"
# Run workflow
echo -e "\e[38;2;61;220;132m# Running workflow...\e[0m"
args=("export.yml")

# Add fields if inputs are present
for FIELD in godot_link templates_link platform debug cache
do
  VALUE="${!FIELD}"
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

  # Handle cases where no steps are returned
  if [[ -z "$CURRENT_STEPS" ]]; then
    sleep 1
    continue
  fi

  # Process steps without a pipeline to avoid subshell issues
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
  done <<< "$CURRENT_STEPS"

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

unset GITHUB_TOKEN
unset keypass
