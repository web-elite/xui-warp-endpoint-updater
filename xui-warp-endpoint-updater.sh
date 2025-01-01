#!/bin/bash

LOG_FILE="/var/log/x-ui-update.log"
IP_FINDER="./find-best-ip-endpoint.sh"
DB_PATH="/etc/x-ui/x-ui.db"

log() {
  local message="$1"
  local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

  # Check if the log file exists and is writable
  if [ ! -w "$LOG_FILE" ]; then
    # Try to create the log file if it doesn't exist
    if [ ! -e "$LOG_FILE" ]; then
      touch "$LOG_FILE" 2>/dev/null || {
        echo "$timestamp Error: Unable to create log file at $LOG_FILE" >&2
        exit 1
      }
    fi

    # Ensure the script can write to the log file
    chmod 644 "$LOG_FILE" 2>/dev/null || {
      echo "$timestamp Error: Unable to set permissions for log file at $LOG_FILE" >&2
      exit 1
    }
  fi

  # Write the message to the log file and optionally to the console
  echo "$timestamp $message" | tee -a "$LOG_FILE"
}

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

# Check if the IP finder script exists
if [ ! -f "$IP_FINDER" ]; then
  log "Error: $IP_FINDER script not found."
  exit 1
fi

# Check if the current directory is writable
if [ ! -w "$(pwd)" ]; then
  log "Error: Current directory is not writable."
  exit 1
fi

chmod +x "$IP_FINDER"
"$IP_FINDER"

if [ ! -f "$DB_PATH" ]; then
  log "Database file not found: $DB_PATH"
  exit 1
fi

if [ ! -f "./result.csv" ]; then
  log "result.csv not found!"
  exit 1
fi

ip1=$(awk -F, 'NR==2 {print $1}' ./result.csv)
ip2=$(awk -F, 'NR==3 {print $1}' ./result.csv)
log "Extracted IP1: $ip1"
log "Extracted IP2: $ip2"

if ! validate_ip "$ip1" || ! validate_ip "$ip2"; then
  log "Invalid IP addresses in result.csv!"
  exit 1
fi

config=$(sqlite3 "$DB_PATH" "SELECT value FROM settings WHERE key='xrayTemplateConfig';")
if [ $? -ne 0 ]; then
  log "Error: Failed to retrieve xrayTemplateConfig from the database."
  exit 1
fi

if [ -z "$config" ]; then
  log "xrayTemplateConfig not found in database!"
  exit 1
fi

updated_config=$(echo "$config" | jq --arg ip1 "$ip1" --arg ip2 "$ip2" '
  .outbounds |= map(
    if .tag == "warp" then
      .settings.peers[0].endpoint = $ip1
    elif .tag == "warp-2" then
      .settings.peers[0].endpoint = $ip2
    else
      .
    end
  )
')

# Function to escape special characters in the input
escape_sql() {
  echo "$1" | sed "s/'/''/g; s/\n/\\n/g; s/\r/\\r/g"
}

escaped_config=$(escape_sql "$updated_config")

# Update the database with the escaped config
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

# Restart the x-ui service
log "Restarting x-ui service..."
x-ui restart

if [ $? -eq 0 ]; then
  log "x-ui service restarted successfully."
else
  log "Failed to restart x-ui service."
  exit 1
fi