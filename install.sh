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

# Prompt user for multiple Warp outbound names (comma-separated)
read -p "Enter the outbound names for Warp (comma-separated, e.g., warp1,warp2,warp3): " warp_outbounds
warp_outbounds=$(echo "$warp_outbounds" | sed 's/ //g')  # Remove spaces

# Save the outbound names in the config file
mkdir -p "$INSTALL_DIR"
echo "WARP_OUTBOUNDS=$warp_outbounds" > "$CONFIG_FILE"

log "Saved outbound names: $warp_outbounds" "$GREEN"

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