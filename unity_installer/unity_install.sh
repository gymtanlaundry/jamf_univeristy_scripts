#!/bin/bash

LOGFILE="/var/log/unity_setup.log"

echo "$(date) - Starting Unity Hub, Editor installation, and serialization..." | tee -a "$LOGFILE"

# Define Unity Hub download URL & DMG location
UNITY_HUB_URL="https://public-cdn.cloud.unity3d.com/hub/prod/UnityHubSetup.dmg"
UNITY_HUB_DMG="/Users/Macadmin/Downloads/UnityHubSetup.dmg"

# Unity Credentials
UNITY_EMAIL="software@quinnipiac.edu"
UNITY_PASSWORD="Un1ty3D!"
SERIAL="E4-DBWE-2CB8-2N8S-ENAB-7XM4"
MACADMIN_USER="Macadmin"
MACADMIN_PASS="lab-d@1qu1r1"

# Ensure logging directory exists
mkdir -p "$(dirname "$LOGFILE")"
touch "$LOGFILE"
chmod 666 "$LOGFILE"

# Get Unity Hub Team ID dynamically
UNITY_TEAM_ID=$(codesign -dv --verbose=4 /Applications/Unity\ Hub.app 2>&1 | awk '/TeamIdentifier/ {print $NF}')

# Function to set up Keychain entries for a user (even if never logged in)
setup_keychain_entry() {
    local USERNAME=$1
    local USER_HOME="/Users/$USERNAME"
    local LOGIN_KEYCHAIN="$USER_HOME/Library/Keychains/login.keychain-db"

    echo "$(date) - Setting up Keychain entry for user: $USERNAME" | tee -a "$LOGFILE"

    # Ensure user's Keychain directory exists
    if [[ ! -d "$USER_HOME/Library/Keychains" ]]; then
        echo "$(date) - Creating Keychain directory for $USERNAME..." | tee -a "$LOGFILE"
        mkdir -p "$USER_HOME/Library/Keychains"
        chown -R "$USERNAME":staff "$USER_HOME/Library/Keychains"
    fi

    # If Keychain doesn't exist, create it (even for non-logged-in users)
    if [[ ! -f "$LOGIN_KEYCHAIN" ]]; then
        echo "$(date) - Keychain not found for $USERNAME. Creating one..." | tee -a "$LOGFILE"
        sudo -u "$USERNAME" security create-keychain -p "" "$LOGIN_KEYCHAIN"
        sudo -u "$USERNAME" security list-keychains -s "$LOGIN_KEYCHAIN"
    fi

    # Add Unity Hub credentials to the Keychain
    echo "$MACADMIN_PASS" | sudo -S -u "$USERNAME" security add-generic-password -s "com.unity3d.unityhub" -a "$UNITY_EMAIL" -w "$UNITY_PASSWORD" -U "$LOGIN_KEYCHAIN"

    # Grant Unity Hub access to the Keychain entry
    echo "$MACADMIN_PASS" | sudo -S -u "$USERNAME" security set-generic-password-partition-list -S "apple-tool:,apple:,teamid:$UNITY_TEAM_ID" -s "com.unity3d.unityhub" -a "$UNITY_EMAIL" -U "$LOGIN_KEYCHAIN"

    # Verify Keychain entry
    if ! sudo -u "$USERNAME" security find-generic-password -s "com.unity3d.unityhub" -a "$UNITY_EMAIL" "$LOGIN_KEYCHAIN" >/dev/null 2>&1; then
        echo "$(date) - ERROR: Keychain entry creation failed for $USERNAME!" | tee -a "$LOGFILE"
        return 1
    else
        echo "$(date) - Keychain entry successfully created for $USERNAME." | tee -a "$LOGFILE"
        return 0
    fi
}

# Set up Keychain for Macadmin first (even if not logged in)
setup_keychain_entry "$MACADMIN_USER"

# Loop through all real users (skip system accounts)
for USER in $(ls /Users); do
    if [[ "$USER" != "Shared" && "$USER" != ".localized" && "$USER" != "Guest" ]]; then
        setup_keychain_entry "$USER"
    fi
done

# Ensure previous Unity Hub DMG is not mounted
MOUNTED_DMG=$(hdiutil info | awk '/Unity Hub/ {print $3}')
if [[ -n "$MOUNTED_DMG" ]]; then
    hdiutil detach "$MOUNTED_DMG" -force
    sleep 2
fi

# Install Unity Hub as Macadmin
if [[ ! -d "/Applications/Unity Hub.app" ]]; then
    echo "$(date) - Unity Hub not found. Downloading..." | tee -a "$LOGFILE"
    sudo -u "$MACADMIN_USER" curl -L "$UNITY_HUB_URL" -o "$UNITY_HUB_DMG"

    sudo -u "$MACADMIN_USER" hdiutil attach "$UNITY_HUB_DMG" > /dev/null 2>&1 &
    TIMER=0
    while [[ ! -d /Volumes/Unity* ]] && [[ $TIMER -lt 30 ]]; do
        sleep 2
        ((TIMER+=2))
    done

    HUB_VOLUME=$(ls /Volumes | grep -i "Unity" | head -n 1)
    HUB_PATH="/Volumes/$HUB_VOLUME/Unity Hub.app"

    if [[ -z "$HUB_VOLUME" || ! -d "$HUB_PATH" ]]; then
        echo "$(date) - Error: Unity Hub app did not mount correctly!" | tee -a "$LOGFILE"
        exit 1
    fi

    echo "$(date) - Unity Hub DMG mounted at: /Volumes/$HUB_VOLUME" | tee -a "$LOGFILE"
    sudo cp -R "$HUB_PATH" /Applications/
    hdiutil detach "/Volumes/$HUB_VOLUME"
    sudo xattr -dr com.apple.quarantine "/Applications/Unity Hub.app"
    open -a "Unity Hub"
    sleep 10
    echo "$(date) - Unity Hub installed successfully." | tee -a "$LOGFILE"
else
    echo "$(date) - Unity Hub is already installed." | tee -a "$LOGFILE"
fi

# Install Unity Editor
LATEST_VERSION=$(ls /Applications/Unity/Hub/Editor/ | sort -V | tail -n 1)
if [[ -z "$LATEST_VERSION" ]]; then
    echo "$(date) - No Unity Editor installed. Installing latest version..." | tee -a "$LOGFILE"
    sudo -u "$MACADMIN_USER" /Applications/Unity\ Hub.app/Contents/MacOS/Unity\ Hub --headless install --version latest
    sleep 600
    LATEST_VERSION=$(ls /Applications/Unity/Hub/Editor/ | sort -V | tail -n 1)
fi

UNITY_PATH="/Applications/Unity/Hub/Editor/$LATEST_VERSION/Unity.app/Contents/MacOS/Unity"
if [[ ! -f "$UNITY_PATH" ]]; then
    echo "$(date) - Error: Unity executable not found at $UNITY_PATH" | tee -a "$LOGFILE"
    exit 1
fi

# Serialize Unity as Macadmin
echo "$(date) - Serializing Unity..." | tee -a "$LOGFILE"
echo "$UNITY_PASSWORD" | sudo -u "$MACADMIN_USER" "$UNITY_PATH" -quit -batchmode -serial "$SERIAL" -username "$UNITY_EMAIL" -password "$(cat)" 2>&1 | tee -a "$LOGFILE"

EXIT_CODE=${PIPESTATUS[0]}
if [[ $EXIT_CODE -ne 0 ]]; then
    echo "$(date) - Error: Unity serialization failed with exit code $EXIT_CODE" | tee -a "$LOGFILE"
    exit $EXIT_CODE
fi

echo "$(date) - Unity Hub, latest Editor installed, and serialized successfully!" | tee -a "$LOGFILE"
exit 0
