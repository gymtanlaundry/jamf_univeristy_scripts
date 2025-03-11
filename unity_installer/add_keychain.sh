=#!/bin/bash

# Log file location
LOGFILE="/var/log/keychain_setup.log"

# Variables
KEYCHAIN_USER="jamf_admin_user"
ACCOUNT_NAME="if_you_buy_software_with_a_email"
ACCOUNT_PASSWORD="password_for_vendor"
KEYCHAIN_ENTRY_NAME="name_for_your_keychain"

# Logging function
log() {
    echo "$(date) - $1" | sudo tee -a "$LOGFILE"
}

# Ensure log file exists & has correct permissions
sudo touch "$LOGFILE"
sudo chmod 666 "$LOGFILE"

log "Starting Keychain setup for $KEYCHAIN_USER."

# Get the user's home directory
USER_HOME=$(eval echo ~$KEYCHAIN_USER)
LOGIN_KEYCHAIN="$USER_HOME/Library/Keychains/login.keychain-db"

# Ensure the login keychain exists
if [ ! -f "$LOGIN_KEYCHAIN" ]; then
    log "Login keychain not found for $KEYCHAIN_USER, creating it..."
    sudo -u "$KEYCHAIN_USER" security create-keychain -p '' login.keychain-db 2>&1 | sudo tee -a "$LOGFILE"
else
    log "Login keychain already exists for $KEYCHAIN_USER."
fi

# Unlock Keychain to prevent permission issues
log "Unlocking the Keychain for $KEYCHAIN_USER..."
sudo -u "$KEYCHAIN_USER" security unlock-keychain -p "" "$LOGIN_KEYCHAIN"

# Add the credentials to the Keychain
log "Adding credentials to the Keychain..."
sudo -u "$KEYCHAIN_USER" security add-generic-password -s "$KEYCHAIN_ENTRY_NAME" -a "$ACCOUNT_NAME" -w "$ACCOUNT_PASSWORD" "$LOGIN_KEYCHAIN" 2>&1 | sudo tee -a "$LOGFILE"

# Verify it was added
log "Verifying Keychain entry..."
if sudo -u "$KEYCHAIN_USER" security find-generic-password -s "$KEYCHAIN_ENTRY_NAME" "$LOGIN_KEYCHAIN" &>/dev/null; then
    log "✅ Keychain entry successfully added."
else
    log "❌ Failed to add Keychain entry!"
    exit 1
fi

log "Keychain setup completed."
exit 0
