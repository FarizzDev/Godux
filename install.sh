#!/bin/bash
set -e

# --- Logging ---
log_info() { echo -e "\e[1;34m[INFO]\e[0m $*"; }
log_warn() { echo -e "\e[1;33m[WARNING]\e[0m $*"; }
log_error() { echo -e "\e[1;31m[ERROR]\e[0m $*" >&2; }
log_success() { echo -e "\e[1;32m[SUCCESS]\e[0m $*"; }

UPSTREAM_REPO="FarizzDev/godux"

# --- Determine Install Path ---
if [ -n "$TERMUX_VERSION" ]; then
  INSTALL_DIR="$PREFIX/bin"
elif [ "$(id -u)" -eq 0 ]; then
  INSTALL_DIR="/usr/bin"
else
  INSTALL_DIR="$HOME/.local/bin"
fi

mkdir -p "$INSTALL_DIR"

# --- Download helper ---
download() {
  local url="$1"
  local output="$2"
  if command -v curl &>/dev/null; then
    curl -fsSL "$url" -o "$output"
  elif command -v wget &>/dev/null; then
    wget -q "$url" -O "$output"
  else
    log_error "Neither curl nor wget found. Please install one and try again."
    exit 1
  fi
}

install_dependencies() {
  local missing_deps=()
  for cmd in git gh fzf bc jq perl; do
    if ! command -v "$cmd" &>/dev/null; then
      missing_deps+=("$cmd")
    fi
  done

  if [ ${#missing_deps[@]} -eq 0 ]; then
    return
  fi

  local SUDO=""
  if [[ $EUID -ne 0 ]] && command -v sudo &>/dev/null; then
    SUDO="sudo"
  fi

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
    log_warn "Could not detect a supported package manager (apt, brew, pacman, dnf, pkg)."
    log_info "Please install the missing dependencies manually: ${missing_deps[*]}"
    exit 1
  fi

  case "$PKG_MANAGER" in
  apt-get)
    $SUDO apt-get update
    $SUDO apt-get install -y git gh fzf bc jq perl
    ;;
  brew)
    brew install git gh fzf bc jq perl
    ;;
  pacman)
    $SUDO pacman -S --noconfirm git github-cli fzf bc jq perl
    ;;
  dnf)
    $SUDO dnf install -y git gh fzf bc jq perl
    ;;
  pkg)
    pkg install -y git gh fzf bc jq perl
    ;;
  esac

  # Verify installation
  for cmd in git gh fzf bc jq perl; do
    if ! command -v "$cmd" &>/dev/null; then
      log_error "Failed to install '$cmd'. Please install it manually."
      exit 1
    fi
  done
}

main() {
  log_info "Fetching latest release..."
  LATEST_VERSION=$(curl -fsSL "https://api.github.com/repos/$UPSTREAM_REPO/releases/latest" | grep '"tag_name"' | cut -d'"' -f4)

  if [ -z "$LATEST_VERSION" ]; then
    log_error "Could not fetch latest version. Please check your internet connection"
    exit 1
  fi

  log_info "Installing gdx $LATEST_VERSION..."

  BASE_URL="https://github.com/$UPSTREAM_REPO/releases/download/$LATEST_VERSION"
  TEMP_FILE=$(mktemp)
  TEMP_HASH=$(mktemp)

  log_info "Downloading gdx..."
  download "$BASE_URL/gdx.sh" "$TEMP_FILE"

  log_info "Verifying checksum..."
  download "$BASE_URL/gdx.sh.sha256" "$TEMP_HASH"

  REMOTE_HASH=$(awk '{print $1}' "$TEMP_HASH")
  LOCAL_HASH=$(sha256sum "$TEMP_FILE" | awk '{print $1}')
  rm -f "$TEMP_HASH"

  if [ "$REMOTE_HASH" != "$LOCAL_HASH" ]; then
    log_error "Checksum FAILED! The downloaded file may be corrupt. Aborting."
    rm -f "$TEMP_FILE"
    exit 1
  fi

  log_success "Checksum passed."
  mv "$TEMP_FILE" "$INSTALL_DIR/gdx"
  chmod +x "$INSTALL_DIR/gdx"

  log_info "Installing dependencies..."
  install_dependencies

  # PATH check
  if [[ "$INSTALL_DIR" == "$HOME/.local/bin" ]]; then
    if ! echo "$PATH" | grep -q "$HOME/.local/bin"; then
      log_warn "$HOME/.local/bin is not in your PATH."
      echo "Add this to your ~/.bashrc:"
      echo 'export PATH="$HOME/.local/bin:$PATH"'
    fi
  fi

  log_success "gdx installed! Run 'gdx' to get started."
}

main
