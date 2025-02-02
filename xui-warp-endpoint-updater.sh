#!/bin/bash

LOG_FILE="/var/log/x-ui-update.log"
IP_FINDER="./find-best-ip-endpoint.sh"
DB_PATH="/etc/x-ui/x-ui.db"
INSTALL_DIR="/root/x-ui-warp-endpoint-updater"
CONFIG_FILE="$INSTALL_DIR/config.conf"

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

chmod +x "$IP_FINDER"
"$IP_FINDER"

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
IFS=',' read -r -a WARP_OUTBOUNDS_ARRAY <<< "$WARP_OUTBOUNDS"

# Extract IPs from result.csv
IP_LIST=()
while IFS=',' read -r ip _; do
  IP_LIST+=("$ip")
done < <(tail -n +2 "$INSTALL_DIR/result.csv")

log "Extracted IPs: ${IP_LIST[*]}"

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
  .outbounds |= map(
    if (.tag | IN($warp_outbounds[])) then
      .settings.peers[0].endpoint = $ip_list[.tag | index($warp_outbounds[])]
    else
      .
    end
  )')

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
