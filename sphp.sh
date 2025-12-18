#!/bin/bash

################################################################################
# macOS PHP Switcher
# A utility script to easily switch between different PHP versions on macOS
# 
# Features:
#   - Error handling with meaningful error messages
#   - Input validation for PHP version numbers
#   - Code deduplication through helper functions
#   - Comprehensive logging and status reporting
################################################################################

set -euo pipefail

# Script constants
readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
readonly BREW_PREFIX="${BREW_PREFIX:-$(brew --prefix 2>/dev/null || echo "/usr/local")}"
readonly PHP_CONF_DIR="${BREW_PREFIX}/etc/php"

# Color codes for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

################################################################################
# Logging and Error Handling Functions
################################################################################

log_info() {
    echo -e "${BLUE}ℹ${NC} $*"
}

log_success() {
    echo -e "${GREEN}✓${NC} $*"
}

log_warning() {
    echo -e "${YELLOW}⚠${NC} $*"
}

log_error() {
    echo -e "${RED}✗${NC} $*" >&2
}

die() {
    log_error "$@"
    exit 1
}

################################################################################
# Utility Functions
################################################################################

# Check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if running with sudo
is_root() {
    [[ $EUID -eq 0 ]]
}

# Validate PHP version format
validate_php_version() {
    local version="$1"
    if [[ ! "$version" =~ ^[0-9]+\.[0-9]+$ ]]; then
        log_error "Invalid PHP version format: $version"
        log_info "Expected format: X.Y (e.g., 7.4, 8.0, 8.1)"
        return 1
    fi
    return 0
}

# Get the PHP binary path for a specific version
get_php_bin_path() {
    local version="$1"
    local php_bin="${BREW_PREFIX}/bin/php@${version}"
    
    if [[ ! -x "$php_bin" ]]; then
        log_error "PHP $version is not installed or not found at $php_bin"
        return 1
    fi
    echo "$php_bin"
}

# Unlink current PHP version
unlink_current_php() {
    local current_link="${BREW_PREFIX}/bin/php"
    
    if [[ -L "$current_link" ]]; then
        log_info "Unlinking current PHP version..."
        rm -f "$current_link" || die "Failed to unlink current PHP"
    elif [[ -e "$current_link" ]]; then
        log_warning "PHP binary exists but is not a symlink. Skipping unlink."
    fi
}

# Link new PHP version
link_new_php() {
    local version="$1"
    local php_bin
    php_bin=$(get_php_bin_path "$version") || return 1
    
    log_info "Linking PHP $version..."
    ln -sf "$php_bin" "${BREW_PREFIX}/bin/php" || die "Failed to create symlink for PHP $version"
}

# Update PHP-FPM symlink
update_php_fpm() {
    local version="$1"
    local php_fpm_versioned="${BREW_PREFIX}/sbin/php-fpm@${version}"
    local php_fpm_link="${BREW_PREFIX}/sbin/php-fpm"
    
    if [[ ! -f "$php_fpm_versioned" ]]; then
        log_warning "PHP-FPM $version not found at $php_fpm_versioned, skipping PHP-FPM update"
        return 0
    fi
    
    log_info "Updating PHP-FPM symlink..."
    rm -f "$php_fpm_link" || log_warning "Failed to remove existing PHP-FPM symlink"
    ln -sf "$php_fpm_versioned" "$php_fpm_link" || log_warning "Failed to create PHP-FPM symlink"
}

# Update shell configuration files
update_shell_config() {
    local version="$1"
    local php_bin_dir="${BREW_PREFIX}/bin"
    local shell_rc=""
    
    # Determine which shell config files to update
    if [[ -f "$HOME/.zshrc" ]]; then
        shell_rc="$HOME/.zshrc"
    elif [[ -f "$HOME/.bash_profile" ]]; then
        shell_rc="$HOME/.bash_profile"
    elif [[ -f "$HOME/.bashrc" ]]; then
        shell_rc="$HOME/.bashrc"
    else
        log_warning "No shell configuration file found. You may need to update PATH manually."
        return 0
    fi
    
    log_info "Updating PATH in $shell_rc..."
    
    # Remove existing PHP path entries if present
    if grep -q "php@" "$shell_rc" 2>/dev/null; then
        sed -i '' '/.*php@.*/d' "$shell_rc" || log_warning "Failed to clean existing PHP entries"
    fi
    
    # Add new PHP path if not already present
    if ! grep -q "$php_bin_dir" "$shell_rc" 2>/dev/null; then
        echo "export PATH=\"${php_bin_dir}:\$PATH\"" >> "$shell_rc"
        log_success "Updated PATH in $shell_rc"
    fi
}

# Verify the switch was successful
verify_switch() {
    local version="$1"
    local current_version
    
    current_version=$("${BREW_PREFIX}/bin/php" --version 2>/dev/null | head -n1 || echo "")
    
    if [[ "$current_version" == *"$version"* ]]; then
        log_success "Successfully switched to PHP $version"
        log_info "Current version: $current_version"
        return 0
    else
        log_error "Verification failed. Current PHP version does not match expected version $version"
        return 1
    fi
}

################################################################################
# Main Functions
################################################################################

# List installed PHP versions
list_php_versions() {
    log_info "Installed PHP versions:"
    
    if ! command_exists brew; then
        die "Homebrew not found. Please install Homebrew first."
    fi
    
    local found_any=0
    for bin in "${BREW_PREFIX}"/bin/php@*; do
        if [[ -e "$bin" ]]; then
            local version=$(basename "$bin" | sed 's/php@//')
            echo "  - PHP $version"
            found_any=1
        fi
    done
    
    if [[ $found_any -eq 0 ]]; then
        log_warning "No PHP versions found. Install PHP versions using: brew install php@VERSION"
    fi
}

# Show help message
show_help() {
    cat << EOF
${BLUE}macOS PHP Switcher${NC}

${BLUE}USAGE:${NC}
    $SCRIPT_NAME [COMMAND] [VERSION]

${BLUE}COMMANDS:${NC}
    list                    List all installed PHP versions
    switch VERSION          Switch to specified PHP version (e.g., 8.1)
    help                    Show this help message

${BLUE}EXAMPLES:${NC}
    $SCRIPT_NAME list               # Show installed PHP versions
    $SCRIPT_NAME switch 8.1         # Switch to PHP 8.1
    $SCRIPT_NAME switch 7.4         # Switch to PHP 7.4

${BLUE}REQUIREMENTS:${NC}
    - Homebrew
    - At least one PHP version installed via Homebrew (brew install php@VERSION)

EOF
}

# Main switch function
switch_php_version() {
    local version="$1"
    
    # Validate input
    validate_php_version "$version" || die "Invalid version format"
    
    # Check if Homebrew is available
    if ! command_exists brew; then
        die "Homebrew not found. Please install Homebrew first."
    fi
    
    # Verify PHP version is installed
    if ! get_php_bin_path "$version" >/dev/null; then
        return 1
    fi
    
    log_info "Switching to PHP $version..."
    
    # Perform the switch
    unlink_current_php
    link_new_php "$version" || die "Failed to link PHP $version"
    update_php_fpm "$version"
    update_shell_config "$version"
    
    # Verify the switch
    verify_switch "$version" || die "PHP version switch verification failed"
    
    log_success "PHP version switched successfully!"
}

# Main entry point
main() {
    local command="${1:-help}"
    
    case "$command" in
        list)
            list_php_versions
            ;;
        switch)
            if [[ -z "${2:-}" ]]; then
                die "Please specify a PHP version (e.g., 8.1)"
            fi
            switch_php_version "$2"
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            log_error "Unknown command: $command"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

# Execute main function if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
