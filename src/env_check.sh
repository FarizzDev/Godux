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
