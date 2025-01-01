#!/bin/bash

# Define the URLs for your main scripts and the target installation directory
SCRIPT_URL="https://raw.githubusercontent.com/web-elite/xui-warp-endpoint-updater/main/find-best-ip-endpoint.sh"
MAIN_SCRIPT_URL="https://raw.githubusercontent.com/web-elite/xui-warp-endpoint-updater/main/xui-warp-endpoint-updater.sh"
INSTALL_DIR="/root/x-ui-warp-endpoint-updater"
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

# Function to prompt user for the cron job interval
get_cron_interval() {
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
}

# Update system and install required packages
log "Updating system and installing required packages..." "$YELLOW"
if ! apt-get update -y || ! apt-get install -y curl cron; then
  log "Error: Failed to install required packages." "$RED"
  exit 1
fi

# Create the installation directory
log "Creating installation directory $INSTALL_DIR..." "$YELLOW"
mkdir -p "$INSTALL_DIR" || { log "Error: Failed to create directory $INSTALL_DIR." "$RED"; exit 1; }

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
chmod +x "$SCRIPT_PATH" "$MAIN_SCRIPT_PATH" || { log "Error: Failed to make the scripts executable." "$RED"; exit 1; }

# Get the cron interval from the user
clear
get_cron_interval

# Add cron job to run the script at the user-defined interval
log "Setting up cron job to run the script at your selected interval..." "$YELLOW"
(crontab -l 2>/dev/null; echo "$cron_interval $MAIN_SCRIPT_PATH") | crontab - || { log "Error: Failed to set up the cron job." "$RED"; exit 1; }

# Verify the cron job is added
log "Verifying cron job..." "$YELLOW"
if crontab -l | grep -q "$MAIN_SCRIPT_PATH"; then
  log "Cron job successfully added to run the script at the selected interval." "$GREEN"
else
  log "Error: Cron job not added successfully." "$RED"
  exit 1
fi

log "Installation complete. The script will now run at the selected interval." "$GREEN"
