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
if systemsetup -settimezone "America/New_York" 2>/dev/null; then
    log "Time zone set to America/New_York."
else
    log "Failed to set time zone or already set."
fi

# Enable network time synchronization
if systemsetup -setusingnetworktime on 2>/dev/null; then
    log "Network time synchronization enabled."
else
    log "Network time synchronization was already enabled."
fi

# Set the network time server
if systemsetup -setnetworktimeserver "time.apple.com" 2>/dev/null; then
    log "Network time server set to time.apple.com."
else
    log "Failed to set network time server or already set."
fi

# Verify that the network time server was correctly set
actual_ntp_server=$(defaults read /Library/Preferences/com.apple.timed.plist TimeServer 2>/dev/null)
if [[ -n "$actual_ntp_server" ]]; then
    log "Verified network time server: $actual_ntp_server"
else
    log "Warning: Could not verify the time server setting."
fi

# Force an immediate time sync (without needing SIP-protected service restart)
log "Forcing immediate time synchronization..."
if sntp -sS time.apple.com; then
    log "Time successfully synchronized using sntp."
else
    log "Time synchronization failed!"
fi

log "Time zone and NTP configuration completed successfully."

exit 0
