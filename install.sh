#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Logging Functions ---

log_info()    { echo -e "\e[1;34m[INFO]\e[0m $*"; }
log_warn()    { echo -e "\e[1;33m[WARNING]\e[0m $*"; }
log_error()   { echo -e "\e[1;31m[ERROR]\e[0m $*" >&2; }
log_success() { echo -e "\e[1;32m[SUCCESS]\e[0m $*"; }

# --- Functions ---

# Function to detect the package manager and install dependencies
install_dependencies() {
    log_info "Checking for required packages..."
    PACKAGES="git gh fzf bc jq"

    # Check for required commands
    local missing_deps=()
    for cmd in git gh fzf bc jq; do
      if ! command -v "$cmd" &>/dev/null; then
        missing_deps+=("$cmd")
      fi
    done

    if [ ${#missing_deps[@]} -eq 0 ]; then
      log_info "All dependencies are already installed."
      return
    fi

    # Check for Termux environment specifically
    if [ -n "$PREFIX" ] && (echo "$PREFIX" | grep -q "com.termux"); then
        log_info "Detected Termux. Using pkg."
        pkg update -y
        pkg install -y $PACKAGES
    elif command -v apt-get >/dev/null 2>&1; then
        log_info "Detected Debian/Ubuntu. Using apt-get."
        sudo apt-get update
        sudo apt-get install -y $PACKAGES
    elif command -v pacman >/dev/null 2>&1; then
        log_info "Detected Arch Linux. Using pacman."
        sudo pacman -Syu --noconfirm $PACKAGES
    elif command -v brew >/dev/null 2>&1; then
        log_info "Detected macOS. Using Homebrew."
        brew install $PACKAGES
    else
        log_error "Unsupported package manager. Please install the following packages manually: $PACKAGES"
        exit 1
    fi
    log_success "Dependencies installed successfully."
}

# Function to install the gdx script
install_script() {
    log_info "Installing gdx script..."

    if [ ! -f "gdx.sh" ]; then
        log_error "gdx.sh not found in the current directory."
        exit 1
    fi

    # Ensure the destination directory exists
    INSTALL_DIR="$PREFIX/bin"
    mkdir -p "$INSTALL_DIR"

    # Copy the script and make it executable
    cp "gdx.sh" "$INSTALL_DIR/gdx"
    chmod +x "$INSTALL_DIR/gdx"

    log_success "gdx has been installed to $INSTALL_DIR/gdx"
    echo "You can now run the script from anywhere by typing: gdx"
}

# --- Main Execution ---

main() {
    install_dependencies
    install_script
}

main
