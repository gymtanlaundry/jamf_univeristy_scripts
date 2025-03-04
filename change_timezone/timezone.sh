#!/bin/bash

LOGFILE="/var/log/jamf_time_sync.log"

# Function to log messages
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOGFILE"
}

log "Starting time zone and NTP configuration..."

# Function to check if internet is accessible
check_internet() {
    # Try reaching Apple's captive portal test page
    if curl -s --max-time 5 "http://captive.apple.com" | grep -q "Success"; then
        log "Internet connection confirmed via HTTP test."
        return 0
    fi

    # Try connecting to NTP port (123) on Apple's time server
    if nc -zw1 time.apple.com 123; then
        log "Internet connection confirmed via NTP port test."
        return 0
    fi

    log "No internet connection detected (both HTTP and NTP checks failed)."
    return 1
}

# Run the internet check before continuing
if ! check_internet; then
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
    log "Failed to set network time server! Verifying current setting..."
fi

# Verify that the network time server was set correctly
current_ntp_server=$(systemsetup -getnetworktimeserver | awk '{print $3}')
log "Current network time server: $current_ntp_server"

# Force an immediate time sync
if sntp -sS time.apple.com; then
    log "Time successfully synchronized."
else
    log "Time synchronization failed!"
fi

# Force an update using ntpdate instead of restarting the service (to bypass SIP restrictions)
log "Forcing time update with ntpdate..."
if ntpdate -u time.apple.com; then
    log "Time successfully updated using ntpdate."
else
    log "Failed to update time with ntpdate!"
fi

log "Time zone and NTP configuration completed successfully."

exit 0
