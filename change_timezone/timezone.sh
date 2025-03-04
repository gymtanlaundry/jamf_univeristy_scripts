#!/bin/bash

LOGFILE="/var/log/jamf_time_sync.log"

# Function to log messages
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOGFILE"
}

log "Starting time zone and NTP configuration..."

# Check if internet is available before attempting time sync
if ! nc -zw1 time.apple.com 123; then
    log "No internet connection or NTP server unreachable. Skipping time sync."
    exit 1
fi

# Set the time zone to Eastern Standard Time (EST)
if systemsetup -settimezone "America/New_York"; then
    log "Time zone set to America/New_York."
else
    log "Failed to set time zone!"
fi

# Enable network time synchronization
if systemsetup -setusingnetworktime on; then
    log "Network time synchronization enabled."
else
    log "Failed to enable network time synchronization!"
fi

# Set the network time server
if systemsetup -setnetworktimeserver "time.apple.com"; then
    log "Network time server set to time.apple.com."
else
    log "Failed to set network time server!"
fi

# Force an immediate time sync
if sntp -sS time.apple.com; then
    log "Time successfully synchronized."
else
    log "Time synchronization failed!"
fi

# Restart the time synchronization service to ensure changes take effect
if launchctl stop com.apple.timed && launchctl start com.apple.timed; then
    log "Restarted the time synchronization service."
else
    log "Failed to restart the time synchronization service!"
fi

log "Time zone and NTP configuration completed successfully."

exit 0
