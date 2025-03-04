#!/bin/bash

LOGFILE="/var/log/jamf_time_sync.log"

# Function to log messages
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOGFILE"
}

log "Starting time zone and NTP configuration..."

# Check for internet connectivity using reliable IP ping
if ! ping -c 3 -q 8.8.8.8 >/dev/null 2>&1; then
    log "No internet connection detected (ping failed)."
    exit 1
fi

# Check if DNS resolution works
if ! nslookup time.apple.com >/dev/null 2>&1; then
    log "Internet connection detected, but DNS resolution failed."
    exit 1
fi

log "Internet connection confirmed. Proceeding with NTP setup..."

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

# Restart the time synchronization service
if launchctl stop com.apple.timed && launchctl start com.apple.timed; then
    log "Restarted the time synchronization service."
else
    log "Failed to restart the time synchronization service!"
fi

log "Time zone and NTP configuration completed successfully."

exit 0
