#!/bin/bash

# Constants
INSTALL_DIR="/root/xui-warp-endpoint-updater"
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

# Remove existing cron job (if any)
remove_cron_job() {
    crontab -l 2>/dev/null | grep -v "$MAIN_SCRIPT_PATH" | crontab -
}

# Add cron job
add_cron_job() {
    (
        crontab -l 2>/dev/null | grep -v "$MAIN_SCRIPT_PATH"
        echo "$1 $MAIN_SCRIPT_PATH"
    ) | crontab -
}

install_script() {
    mkdir -p "$INSTALL_DIR"

    if [[ ! -f "$SCRIPT_PATH" || ! -f "$MAIN_SCRIPT_PATH" ]]; then
        log "Required scripts not found in $INSTALL_DIR" "$RED"
        log "Please make sure both find-best-ip-endpoint.sh and xui-warp-endpoint-updater.sh exist." "$RED"
        exit 1
    fi

    read -p "Enter the outbound names for Warp (comma-separated, e.g., warp1,warp2): " warp_outbounds
    warp_outbounds=$(echo "$warp_outbounds" | sed 's/ //g')
    echo "WARP_OUTBOUNDS=$warp_outbounds" >"$CONFIG_FILE"
    log "Saved outbound names: $warp_outbounds" "$GREEN"

    log "Choose how often the script should run:" "$YELLOW"
    echo -e "${YELLOW}1) Every 1 hour\n2) Every 2 hours\n3) Every 3 hours\n4) Every 6 hours\n5) Every 12 hours\n6) Every 24 hours\n7) Custom (enter number of hours)${NC}"
    read -p "Choice: " choice

    case $choice in
    1) cron_interval="0 */1 * * *" ;;
    2) cron_interval="0 */2 * * *" ;;
    3) cron_interval="0 */3 * * *" ;;
    4) cron_interval="0 */6 * * *" ;;
    5) cron_interval="0 */12 * * *" ;;
    6) cron_interval="0 */24 * * *" ;;
    7)
        read -p "Enter interval in hours (e.g., 1, 3, 5): " custom_hours
        if [[ "$custom_hours" =~ ^[0-9]+$ ]] && [ "$custom_hours" -ge 1 ] && [ "$custom_hours" -le 23 ]; then
            cron_interval="0 */$custom_hours * * *"
        else
            log "Invalid input. Using default: every 1 hour." "$RED"
            cron_interval="0 */1 * * *"
        fi
        ;;
    *)
        cron_interval="0 */6 * * *"
        log "Invalid choice, using default 6h." "$RED"
        ;;
    esac
    log "Cron job will run with interval: $cron_interval" "$GREEN"

    remove_cron_job
    add_cron_job "$cron_interval"

    chmod +x "$SCRIPT_PATH" "$MAIN_SCRIPT_PATH"
    log "Offline installation complete." "$GREEN"
}

uninstall_script() {
    remove_cron_job
    rm -rf "$INSTALL_DIR"
    log "Uninstalled successfully." "$GREEN"
}

update_script() {
    log "Offline mode: Manual update only." "$YELLOW"
}

log "Offline XUI Warp Endpoint Updater"
log "========================================="

# Menu
echo -e "${YELLOW}Select an option:\n1) Install\n2) Uninstall\n3) Update Script${NC}"
read -p "Enter choice: " action

case "$action" in
1) install_script ;;
2) uninstall_script ;;
3) update_script ;;
*) log "Invalid option." "$RED" ;;
esac
