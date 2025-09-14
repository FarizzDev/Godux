#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Logging Functions ---
log_info() { echo -e "\e[1;34m[INFO]\e[0m $*"; }
log_warn() { echo -e "\e[1;33m[WARNING]\e[0m $*"; }
log_error() { echo -e "\e[1;31m[ERROR]\e[0m $*" >&2; }
log_success() { echo -e "\e[1;32m[SUCCESS]\e[0m $*"; }

# --- Determine Install Paths ---
if [ -n "$TERMUX_VERSION" ]; then
  # Termux environment
  INSTALL_DIR="$PREFIX/bin"
  DOC_DIR="$PREFIX/share/gdx"
elif [ "$(id -u)" -eq 0 ]; then
  # Linux/macOS root
  INSTALL_DIR="/usr/bin"
  DOC_DIR="/usr/share/gdx"
else
  # Linux/macOS user-local
  INSTALL_DIR="$HOME/.local/bin"
  DOC_DIR="$HOME/.local/share/gdx"
fi

mkdir -p "$INSTALL_DIR" "$DOC_DIR"

# --- Functions ---

install_dependencies() {
  log_info "Checking for required packages..."
  PACKAGES="git gh fzf bc jq"
  local missing_deps=()
  for cmd in $PACKAGES; do
    if ! command -v "$cmd" &>/dev/null; then
      missing_deps+=("$cmd")
    fi
  done

  if [ ${#missing_deps[@]} -eq 0 ]; then
    log_info "All dependencies are already installed."
    return
  fi

  if [ -n "$TERMUX_VERSION" ]; then
    log_info "Detected Termux. Installing packages with pkg."
    pkg update -y
    pkg install -y ${missing_deps[*]}
  elif command -v apt-get >/dev/null 2>&1; then
    log_info "Detected Debian/Ubuntu. Installing packages with apt-get."
    sudo apt-get update
    sudo apt-get install -y ${missing_deps[*]}
  elif command -v pacman >/dev/null 2>&1; then
    log_info "Detected Arch Linux. Installing packages with pacman."
    sudo pacman -Syu --noconfirm ${missing_deps[*]}
  elif command -v brew >/dev/null 2>&1; then
    log_info "Detected macOS. Installing packages with Homebrew."
    brew install ${missing_deps[*]}
  else
    log_error "Unsupported package manager. Please install manually: ${missing_deps[*]}"
    exit 1
  fi
  log_success "Dependencies installed successfully."
}

install_script() {
  log_info "Installing gdx script..."

  if [ ! -f "gdx.sh" ]; then
    log_error "gdx.sh not found in the current directory."
    exit 1
  fi

  # Copy LICENSE and README
  if [ -f "LICENSE" ]; then
    cp LICENSE "$DOC_DIR/LICENSE"
  fi
  if [ -f "README.md" ]; then
    cp README.md "$DOC_DIR/README.md"
  fi
  log_success "LICENSE and README installed to $DOC_DIR"

  # Copy the script and make it executable
  cp "gdx.sh" "$INSTALL_DIR/gdx"
  chmod +x "$INSTALL_DIR/gdx"
  log_success "gdx installed to $INSTALL_DIR/gdx"

  # Check if user-local bin is in PATH
  if [[ "$INSTALL_DIR" == "$HOME/.local/bin" ]]; then
    if ! echo "$PATH" | grep -q "$HOME/.local/bin"; then
      echo "WARNING: $HOME/.local/bin is not in your PATH."
      echo "Add this line to your shell rc file (e.g., ~/.bashrc):"
      echo 'export PATH="$HOME/.local/bin:$PATH"'
    fi
  fi

  log_info "You can now run the script from anywhere by typing: gdx"
}

# --- Main Execution ---
main() {
  install_dependencies
  install_script
}

main
