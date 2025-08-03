#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Functions ---

# Function to detect the package manager and install dependencies
install_dependencies() {
    echo "[INFO]: Checking for required packages..."
    PACKAGES="git gh fzf bc jq"

    # Check for required commands
    local missing_deps=()
    for cmd in git gh fzf bc jq; do
      if ! command -v "$cmd" &>/dev/null; then
        missing_deps+=("$cmd")
      fi
    done

    if [ ${#missing_deps[@]} -eq 0 ]; then
      echo "[INFO]: All dependencies are already installed."
      return
    fi

    # Check for Termux environment specifically
    if [ -n "$PREFIX" ] && (echo "$PREFIX" | grep -q "com.termux"); then
        echo "[INFO]: Detected Termux. Using pkg."
        pkg update -y
        pkg install -y $PACKAGES
    elif command -v apt-get >/dev/null 2>&1; then
        echo "[INFO]: Detected Debian/Ubuntu. Using apt-get."
        sudo apt-get update
        sudo apt-get install -y $PACKAGES
    elif command -v pacman >/dev/null 2>&1; then
        echo "[INFO]: Detected Arch Linux. Using pacman."
        sudo pacman -Syu --noconfirm $PACKAGES
    elif command -v brew >/dev/null 2>&1; then
        echo "[INFO]: Detected macOS. Using Homebrew."
        brew install $PACKAGES
    else
        echo "[ERROR]: Unsupported package manager. Please install the following packages manually: $PACKAGES" >&2
        exit 1
    fi
    echo "[INFO]: Dependencies installed successfully."
}

# Function to install the gdx script
install_script() {
    echo "[INFO]: Installing gdx script..."

    if [ ! -f "gdx.sh" ]; then
        echo "[ERROR]: gdx.sh not found in the current directory." >&2
        exit 1
    fi

    # Ensure the destination directory exists
    INSTALL_DIR="$PREFIX/bin"
    mkdir -p "$INSTALL_DIR"

    # Copy the script and make it executable
    cp "gdx.sh" "$INSTALL_DIR/gdx"
    chmod +x "$INSTALL_DIR/gdx"

    echo "[SUCCESS]: gdx has been installed to $INSTALL_DIR/gdx"
    echo "You can now run the script from anywhere by typing: gdx"
}

# --- Main Execution ---

main() {
    install_dependencies
    install_script
}

main

