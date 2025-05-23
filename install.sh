#!/bin/bash

# Define the URLs for your main scripts and the target installation directory
SCRIPT_URL="https://raw.githubusercontent.com/web-elite/xui-warp-endpoint-updater/main/find-best-ip-endpoint.sh"
MAIN_SCRIPT_URL="https://raw.githubusercontent.com/web-elite/xui-warp-endpoint-updater/main/xui-warp-endpoint-updater.sh"
INSTALL_DIR="/root/x-ui-warp-endpoint-updater"
CONFIG_FILE="$INSTALL_DIR/config.conf"
SCRIPT_PATH="$INSTALL_DIR/find-best-ip-endpoint.sh"
MAIN_SCRIPT_PATH="$INSTALL_DIR/xui-warp-endpoint-updater.sh"

# Colors for logging
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to log messages with color
log() {
    local message="$1"
    local color="$2"
    echo -e "${color}$message${NC}"
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

# Prompt user for multiple Warp outbound names (comma-separated)
read -p "Enter the outbound names for Warp (comma-separated, e.g., warp1,warp2,warp3): " warp_outbounds
warp_outbounds=$(echo "$warp_outbounds" | sed 's/ //g') # Remove spaces

# Save the outbound names in the config file
mkdir -p "$INSTALL_DIR"
echo "WARP_OUTBOUNDS=$warp_outbounds" >"$CONFIG_FILE"

log "Saved outbound names: $warp_outbounds" "$GREEN"

# Function to prompt user for the cron job interval
log "Please choose how often you want to run the script:" "$RED"
log "1) Every 6 hours" "$YELLOW"
log "2) Every 12 hours" "$YELLOW"
log "3) Every 24 hours" "$YELLOW"
log "4) Custom (Enter custom interval)" "$YELLOW"

read -p "Enter the number corresponding to your choice: " choice

case $choice in
1)
    cron_interval="0 */6 * * *"
    log "You selected to run the script every 6 hours." "$GREEN"
    ;;
2)
    cron_interval="0 */12 * * *"
    log "You selected to run the script every 12 hours." "$GREEN"
    ;;
3)
    cron_interval="0 */24 * * *"
    log "You selected to run the script every 24 hours." "$GREEN"
    ;;
4)
    read -p "Enter the custom cron interval (e.g., 0 */4 * * * for every 4 hours): " cron_interval
    log "You selected a custom cron interval: $cron_interval" "$GREEN"
    ;;
*)
    log "Invalid choice. Defaulting to every 6 hours." "$RED"
    cron_interval="0 */6 * * *"
    ;;
esac

#add crontab
(crontab -l 2>/dev/null; echo "$cron_interval $MAIN_SCRIPT_PATH") | crontab -

# Proceed with installation (same as before)
log "Updating system and installing required packages..." "$YELLOW"
if ! apt-get update -y || ! apt-get install -y curl cron sqlite3 jq; then
    log "Error: Failed to install required packages." "$RED"
    exit 1
fi

# Create the installation directory
log "Creating installation directory $INSTALL_DIR..." "$YELLOW"
mkdir -p "$INSTALL_DIR" || {
    log "Error: Failed to create directory $INSTALL_DIR." "$RED"
    exit 1
}

# Download the scripts
log "Downloading the find-best-ip-endpoint.sh script..." "$YELLOW"
if ! curl -fsSL "$SCRIPT_URL" -o "$SCRIPT_PATH"; then
    log "Error: Failed to download the find-best-ip-endpoint.sh script." "$RED"
    exit 1
fi

log "Downloading the xui-warp-endpoint-updater.sh script..." "$YELLOW"
if ! curl -fsSL "$MAIN_SCRIPT_URL" -o "$MAIN_SCRIPT_PATH"; then
    log "Error: Failed to download the xui-warp-endpoint-updater.sh script." "$RED"
    exit 1
fi

# Make the scripts executable
log "Making the scripts executable..." "$YELLOW"
chmod +x "$SCRIPT_PATH" "$MAIN_SCRIPT_PATH" || {
    log "Error: Failed to make the scripts executable." "$RED"
    exit 1
}

log "Installation complete." "$GREEN"
