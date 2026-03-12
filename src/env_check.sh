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

  if ! command -v python3 &>/dev/null && ! command -v python &>/dev/null; then
    missing_deps+=("python3")
  fi

  if [ ${#missing_deps[@]} -eq 0 ]; then
    echo -e "${INFO} All dependencies are already installed."
    return
  fi

  echo -e "${WARN} The following dependencies are missing: ${missing_deps[*]}"
  echo -ne "${PROMPT} Do you want to try and install them? (Y/n): "
  read confirm_install
  confirm_install=${confirm_install,,}
  confirm_install=${confirm_install:-"y"}
  if [[ ! "$confirm_install" =~ ^y(e?s)?$ ]]; then
    echo -e "${INFO} Please install the missing dependencies manually and rerun the script."
    exit 1
  fi

  # Determine package manager
  local SUDO=""
  if [[ $EUID -ne 0 ]] && command -v sudo &>/dev/null; then
    SUDO="sudo"
  fi

  # Detect package manager
  if command -v apt-get &>/dev/null; then
    PKG_MANAGER="apt-get"
  elif command -v brew &>/dev/null; then
    PKG_MANAGER="brew"
  elif command -v pacman &>/dev/null; then
    PKG_MANAGER="pacman"
  elif command -v dnf &>/dev/null; then
    PKG_MANAGER="dnf"
  elif command -v pkg &>/dev/null; then
    PKG_MANAGER="pkg"
  else
    echo -e "${ERROR} Could not detect a supported package manager (apt, brew, pacman, dnf, pkg)."
    echo -e "${INFO} Please install the missing dependencies manually: ${missing_deps[*]}"
    exit 1
  fi

  echo -e "${INFO} Attempting to install using '$PKG_MANAGER'..."

  # Package names per PM
  case "$PKG_MANAGER" in
  apt-get)
    $SUDO apt-get update
    $SUDO apt-get install -y git gh fzf bc jq python3
    ;;
  brew)
    brew install git gh fzf bc jq python3
    ;;
  pacman)
    $SUDO pacman -S --noconfirm git github-cli fzf bc jq python
    ;;
  dnf)
    $SUDO dnf install -y git gh fzf bc jq python3
    ;;
  pkg)
    pkg install -y git gh fzf bc jq python
    ;;
  esac

  # Verify installation
  for cmd in git gh fzf bc jq; do
    if ! command -v "$cmd" &>/dev/null; then
      echo -e "${ERROR} Failed to install '$cmd'. Please install it manually and rerun the script."
      exit 1
    fi
  done
  if ! command -v python3 &>/dev/null && ! command -v python &>/dev/null; then
    echo -e "${ERROR} Failed to install python. Please install it manually."
    exit 1
  fi

  echo -e "\e[38;2;61;220;132m# Dependencies installed successfully.\e[0m"
}

printf "\n"
install_dependencies
