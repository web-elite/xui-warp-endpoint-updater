#!/bin/bash

# Constants
SCRIPT_URL="https://raw.githubusercontent.com/web-elite/xui-warp-endpoint-updater/main/find-best-ip-endpoint.sh"
MAIN_SCRIPT_URL="https://raw.githubusercontent.com/web-elite/xui-warp-endpoint-updater/main/xui-warp-endpoint-updater.sh"
INSTALL_DIR="/root/x-ui-warp-endpoint-updater"
CONFIG_FILE="$INSTALL_DIR/config.conf"
SCRIPT_PATH="$INSTALL_DIR/find-best-ip-endpoint.sh"
MAIN_SCRIPT_PATH="$INSTALL_DIR/xui-warp-endpoint-updater.sh"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'

log() {
    echo -e "${2}${1}${NC}"
}

# Detect and install required packages based on the system
install_dependencies() {
    local packages=("curl" "cron" "sqlite3" "jq")
    log "Checking system and installing required packages..." "$YELLOW"

    if command -v apt >/dev/null; then
        apt-get update -y
        apt-get install -y "${packages[@]}"
    elif command -v dnf >/dev/null; then
        dnf install -y "${packages[@]}"
    elif command -v yum >/dev/null; then
        yum install -y "${packages[@]}"
    elif command -v pacman >/dev/null; then
        pacman -Sy --noconfirm "${packages[@]}"
    else
        log "Unsupported package manager. Please install these manually: ${packages[*]}" "$RED"
        exit 1
    fi
}

# Remove existing cron job (if any)
remove_cron_job() {
    crontab -l 2>/dev/null | grep -v "$MAIN_SCRIPT_PATH" | crontab -
}

# Add cron job
add_cron_job() {
    (crontab -l 2>/dev/null | grep -v "$MAIN_SCRIPT_PATH"; echo "$1 $MAIN_SCRIPT_PATH") | crontab -
}

install_script() {
    install_dependencies
    mkdir -p "$INSTALL_DIR"

    read -p "Enter the outbound names for Warp (comma-separated, e.g., warp1,warp2): " warp_outbounds
    warp_outbounds=$(echo "$warp_outbounds" | sed 's/ //g')
    echo "WARP_OUTBOUNDS=$warp_outbounds" >"$CONFIG_FILE"
    log "Saved outbound names: $warp_outbounds" "$GREEN"

    log "Choose how often the script should run:" "$YELLOW"
    echo -e "${YELLOW}1) Every 6 hours\n2) Every 12 hours\n3) Every 24 hours\n4) Custom (cron format)${NC}"
    read -p "Choice: " choice

    case $choice in
    1) cron_interval="0 */6 * * *" ;;
    2) cron_interval="0 */12 * * *" ;;
    3) cron_interval="0 0 * * *" ;; # Every 24 hours at midnight
    4) read -p "Enter custom cron interval: " cron_interval ;;
    *) cron_interval="0 */6 * * *"; log "Invalid choice, using default 6h." "$RED" ;;
    esac

    remove_cron_job
    add_cron_job "$cron_interval"

    curl -fsSL "$SCRIPT_URL" -o "$SCRIPT_PATH" || { log "Failed to download helper script." "$RED"; exit 1; }
    curl -fsSL "$MAIN_SCRIPT_URL" -o "$MAIN_SCRIPT_PATH" || { log "Failed to download main script." "$RED"; exit 1; }

    chmod +x "$SCRIPT_PATH" "$MAIN_SCRIPT_PATH"
    log "Installation complete." "$GREEN"
}

uninstall_script() {
    remove_cron_job
    rm -rf "$INSTALL_DIR"
    log "Uninstalled successfully." "$GREEN"
}

update_script() {
    curl -fsSL "$SCRIPT_URL" -o "$SCRIPT_PATH" || { log "Failed to update helper script." "$RED"; exit 1; }
    curl -fsSL "$MAIN_SCRIPT_URL" -o "$MAIN_SCRIPT_PATH" || { log "Failed to update main script." "$RED"; exit 1; }
    chmod +x "$SCRIPT_PATH" "$MAIN_SCRIPT_PATH"
    log "Update complete." "$GREEN"
}

log "This script will automatically find the best Warp endpoint IP and place it in your x-ui panel and finally restart the xray core."
log "After the script has been run, you can choose how many hours it will automatically run and update the Warp endpoint IP."
log "This script will not interfere with your existing Warp settings."
log "Please make sure you have a backup of your Warp settings before running this script."
log ""
log "Thanks Ptech From https://github.com/Ptechgithub/warp"
log "Script By Me https://github.com/Web-Elite"
log "========================================="
log "This Script needs sqlite3, jq, curl, and cron ... so let's get started with installation."

# Menu
echo -e "${YELLOW}Select an option:\n1) Install\n2) Uninstall\n3) Update Script${NC}"
read -p "Enter choice: " action

case "$action" in
1) install_script ;;
2) uninstall_script ;;
3) update_script ;;
*) log "Invalid option." "$RED" ;;
esac
