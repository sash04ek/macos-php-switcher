#!/usr/bin/env bash
set -e

# ---------- colors ----------

RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
BLUE="\033[0;34m"
NC="\033[0m"

# ---------- logging ----------

info()    { echo -e "${BLUE}$1${NC}"; }
success() { echo -e "${GREEN}$1${NC}"; }
warn()    { echo -e "${YELLOW}$1${NC}"; }
error()   { echo -e "${RED}$1${NC}"; }

# ---------- helpers ----------

ask_yes_no() {
  local prompt="$1"
  local answer
  while true; do
    read -rp "$prompt [y/N]: " answer
    case "$answer" in
      [yY]|[yY][eE][sS]) return 0 ;;
      ""|[nN]|[nN][oO])  return 1 ;;
      *) echo "Please answer yes or no." ;;
    esac
  done
}

# ---------- Homebrew ----------

install_brew() {
  warn "Homebrew is not installed."
  echo
  if ask_yes_no "Do you want to install Homebrew now?"; then
    info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    echo
    info "Please restart your terminal after Homebrew installation."
    exit 0
  else
    error "Homebrew is required. Aborting."
    exit 1
  fi
}

check_brew() {
  if ! command -v brew >/dev/null 2>&1; then
    install_brew
  fi
}

# ---------- PHP utils ----------

show_installed_php_versions() {
  info "Installed PHP versions:"
  brew list --formula \
    | grep -E '^php(@[0-9]+\.[0-9]+)?$' \
    | while read -r f; do
        ver=$(brew list --versions "$f" | cut -d' ' -f2-)
        echo "  - $f ($ver)"
      done
  echo
}

stop_all_php_services() {
  local running
  running=$(brew services list | awk '/php/ && $2=="started" {print $1}')

  if [ -z "$running" ]; then
    warn "No running PHP services found."
    return
  fi

  echo "$running" | while read -r s; do
    warn "Stopping service: $s"
    brew services stop "$s" >/dev/null
  done
}

unlink_all_php() {
  brew list --formula \
    | grep -E '^php(@[0-9]+\.[0-9]+)?$' \
    | while read -r f; do
        warn "Unlinking: $f"
        brew unlink "$f" >/dev/null 2>&1 || true
      done
}

is_php_version_active() {
  php -v 2>/dev/null | head -n1 | grep -q "PHP $1"
}

is_php_service_running() {
  brew services list | awk -v f="php@$1" '$1==f && $2=="started" {found=1} END{exit !found}'
}

# ---------- main ----------

check_brew

# ---------- STOP MODE ----------

if [ "$1" = "stop" ]; then
  info "Stopping all PHP services..."
  stop_all_php_services
  success "All PHP services have been stopped."
  exit 0
fi

# ---------- HELP ----------

if [ -z "$1" ]; then
  CURRENT=$(php -v 2>/dev/null | head -n1 | awk '{print $2}')
  if [ -n "$CURRENT" ]; then
    info "Current PHP version: $CURRENT"
  else
    warn "PHP not found"
  fi
  echo
  show_installed_php_versions
  echo "Usage:"
  echo "  $0 <version>   Switch PHP version (e.g. 8.2)"
  echo "  $0 stop        Stop all PHP services"
  exit 0
fi

PHP_VERSION="$1"
FORMULA="php@$PHP_VERSION"

# ---------- already active ----------

if is_php_version_active "$PHP_VERSION" && is_php_service_running "$PHP_VERSION"; then
  warn "PHP $PHP_VERSION is already active and running."

  if ask_yes_no "Do you want to restart PHP $PHP_VERSION service?"; then
    info "Restarting service $FORMULA..."
    brew services restart "$FORMULA" >/dev/null
    success "PHP $PHP_VERSION restarted."
    php -v | head -n1
    exit 0
  else
    warn "Nothing to do. Exiting."
    exit 0
  fi
fi

# ---------- install if missing ----------

if ! brew list --versions "$FORMULA" >/dev/null 2>&1; then
  warn "PHP $PHP_VERSION is not installed."
  echo
  show_installed_php_versions

  if ask_yes_no "Do you want to install $FORMULA now?"; then
    info "Installing $FORMULA..."
    brew install "$FORMULA"
    success "$FORMULA installed successfully."
  else
    error "Aborted. PHP $PHP_VERSION is required."
    exit 1
  fi
fi

# ---------- switch ----------

info "Stopping all PHP services..."
stop_all_php_services

info "Unlinking all PHP versions..."
unlink_all_php

info "Activating PHP $PHP_VERSION..."
brew link --force --overwrite "$FORMULA" >/dev/null

info "Starting service $FORMULA..."
brew services start "$FORMULA" >/dev/null

echo
php -v | head -n1
success "✅ PHP $PHP_VERSION activated"
