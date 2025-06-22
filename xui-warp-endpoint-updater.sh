#!/bin/bash

# Define absolute paths
LOG_FILE="/var/log/xui-update.log"
INSTALL_DIR="/root/xui-warp-endpoint-updater"
IP_FINDER="$INSTALL_DIR/find-best-ip-endpoint.sh"  # Use absolute path
DB_PATH="/etc/x-ui/x-ui.db"
CONFIG_FILE="$INSTALL_DIR/config.conf"

# Log function
log() {
  local message="$1"
  local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  echo "$timestamp $message" | tee -a "$LOG_FILE"
}

# Validate IP function
validate_ip() {
  local ip_port=$1
  if [[ $ip_port =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:[0-9]{1,5}$ ]]; then
    local port=${ip_port##*:}
    if ((port >= 1 && port <= 65535)); then
      return 0
    fi
  fi
  return 1
}

# Ensure the IP finder script exists
if [ ! -f "$IP_FINDER" ]; then
  log "Error: $IP_FINDER script not found."
  exit 1
fi

# Change to the installation directory
cd "$INSTALL_DIR" || { log "Error: Failed to change to directory $INSTALL_DIR"; exit 1; }

# Make the IP finder script executable and run it
chmod +x "$IP_FINDER"
"$IP_FINDER"

# Check if required files exist
if [ ! -f "$DB_PATH" ]; then
  log "Database file not found: $DB_PATH"
  exit 1
fi

if [ ! -f "$INSTALL_DIR/result.csv" ]; then
  log "result.csv not found!"
  exit 1
fi

# Read the saved outbound names from config.conf
if [ ! -f "$CONFIG_FILE" ]; then
  log "Config file not found!"
  exit 1
fi

source "$CONFIG_FILE"
IFS=',' read -r -a WARP_OUTBOUNDS_ARRAY <<<"$WARP_OUTBOUNDS"

# Extract IPs from result.csv
IP_LIST=()
while IFS=',' read -r ip _; do
  IP_LIST+=("$ip")
done < <(tail -n +2 "$INSTALL_DIR/result.csv")

# Ensure extracted IP count matches WARP_OUTBOUNDS_ARRAY count
if [[ ${#IP_LIST[@]} -lt ${#WARP_OUTBOUNDS_ARRAY[@]} ]]; then
  log "Error: Not enough IPs extracted (${#IP_LIST[@]}) for WARP Outbounds (${#WARP_OUTBOUNDS_ARRAY[@]})."
  exit 1
elif [[ ${#IP_LIST[@]} -gt ${#WARP_OUTBOUNDS_ARRAY[@]} ]]; then
  log "Warning: More IPs extracted than required. Truncating..."
  IP_LIST=("${IP_LIST[@]:0:${#WARP_OUTBOUNDS_ARRAY[@]}}")
fi

log "Warp Outbound Tag Names: ${WARP_OUTBOUNDS_ARRAY[*]}"
log "Final IPs Assigned: ${IP_LIST[*]} (Count: ${#IP_LIST[@]})"

# Validate IPs
for ip in "${IP_LIST[@]}"; do
  if ! validate_ip "$ip"; then
    log "Invalid IP address in result.csv: $ip"
    exit 1
  fi
done

# Get xrayTemplateConfig from the database
config=$(sqlite3 "$DB_PATH" "SELECT value FROM settings WHERE key='xrayTemplateConfig';")
if [ $? -ne 0 ]; then
  log "Error: Failed to retrieve xrayTemplateConfig from the database."
  exit 1
fi

if [ -z "$config" ]; then
  log "xrayTemplateConfig not found in database!"
  exit 1
fi

# Update the configuration with new endpoints
updated_config=$(echo "$config" | jq --argjson ip_list "$(printf '%s\n' "${IP_LIST[@]}" | jq -R . | jq -s .)" --argjson warp_outbounds "$(printf '%s\n' "${WARP_OUTBOUNDS_ARRAY[@]}" | jq -R . | jq -s .)" '
  . as $config |
  $warp_outbounds as $warp_outbounds |
  $ip_list as $ip_list |
  reduce range(0; $warp_outbounds | length) as $i (
    $config;
    .outbounds |= map(
      if .tag == $warp_outbounds[$i] then
        .settings.peers[0].endpoint = $ip_list[$i]
      else
        .
      end
    )
  )
')

# Escape SQL special characters
escape_sql() {
  echo "$1" | sed "s/'/''/g; s/\n/\\n/g; s/\r/\\r/g"
}

escaped_config=$(escape_sql "$updated_config")

# Update the database with new config
sqlite3 "$DB_PATH" <<EOF
BEGIN TRANSACTION;
UPDATE settings SET value = '$escaped_config' WHERE key = 'xrayTemplateConfig';
COMMIT;
EOF

if [ $? -ne 0 ]; then
  log "Error: Failed to update the database."
  exit 1
fi

log "Database updated successfully with new IPs."

# Restart x-ui service
log "Restarting x-ui service..."
x-ui restart

if [ $? -eq 0 ]; then
  log "x-ui service restarted successfully."
else
  log "Failed to restart x-ui service."
  exit 1
fi