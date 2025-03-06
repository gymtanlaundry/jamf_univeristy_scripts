#!/bin/bash

LOGFILE="/var/log/unity_setup.log"

echo "$(date) - Starting Unity Hub, Editor installation, and serialization..." | tee -a "$LOGFILE"

# Define Unity Hub download URL & DMG location
UNITY_HUB_URL="https://public-cdn.cloud.unity3d.com/hub/prod/UnityHubSetup.dmg"
UNITY_HUB_DMG="/Users/Macadmin/Downloads/UnityHubSetup.dmg"

# Unity Credentials
UNITY_EMAIL=""
UNITY_PASSWORD=""
SERIAL=""
MACADMIN_USER=""
MACADMIN_PASS=""

# Ensure logging directory exists
mkdir -p "$(dirname "$LOGFILE")"
touch "$LOGFILE"
chmod 666 "$LOGFILE"

# Get Unity Hub Team ID dynamically
UNITY_TEAM_ID=$(codesign -dv --verbose=4 /Applications/Unity\ Hub.app 2>&1 | awk '/TeamIdentifier/ {print $NF}')

# Function to ensure Keychain exists before adding credentials
ensure_keychain_exists() {
    local USERNAME=$1
    local USER_HOME=$(eval echo ~$USERNAME)
    local LOGIN_KEYCHAIN="$USER_HOME/Library/Keychains/login.keychain-db"

    if [[ ! -f "$LOGIN_KEYCHAIN" ]]; then
        echo "$(date) - Keychain does not exist for $USERNAME. Creating..." | tee -a "$LOGFILE"
        echo "$MACADMIN_PASS" | sudo -S -u "$USERNAME" security create-keychain -p "" "$LOGIN_KEYCHAIN"
        sudo -u "$USERNAME" security list-keychains -s "$LOGIN_KEYCHAIN"
    fi
}

# Function to add Unity credentials to the Keychain silently using Macadmin password
setup_keychain_entry() {
    local USERNAME=$1
    local USER_HOME=$(eval echo ~$USERNAME)
    local LOGIN_KEYCHAIN="$USER_HOME/Library/Keychains/login.keychain-db"

    echo "$(date) - Setting up Keychain entry for user: $USERNAME" | tee -a "$LOGFILE"

    ensure_keychain_exists "$USERNAME"

    # Delete old Unity Hub Keychain entry
    echo "$MACADMIN_PASS" | sudo -S -u "$USERNAME" security delete-generic-password -s "com.unity3d.unityhub" -a "$UNITY_EMAIL" "$LOGIN_KEYCHAIN" 2>/dev/null

    # Add new Keychain entry silently
    echo "$MACADMIN_PASS" | sudo -S -u "$USERNAME" security add-generic-password -s "com.unity3d.unityhub" -a "$UNITY_EMAIL" -w "$UNITY_PASSWORD" -U "$LOGIN_KEYCHAIN"

    # Grant Unity Hub access without prompting
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

# Set up Keychain for Macadmin first (before Unity Hub opens)
setup_keychain_entry "$MACADMIN_USER"

# Loop through all users and set up their Keychain entries
for USER in $(ls /Users); do
    if [[ "$USER" != "Shared" && "$USER" != ".localized" && "$USER" != "Guest" ]]; then
        setup_keychain_entry "$USER"
    fi
done

# Ensure Unity Hub is installed as Macadmin
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
    echo "$(date) - Waiting for Unity Hub to initialize..." | tee -a "$LOGFILE"
    sleep 20
    echo "$(date) - Unity Hub installed successfully." | tee -a "$LOGFILE"
else
    echo "$(date) - Unity Hub is already installed." | tee -a "$LOGFILE"
fi

# Log into Unity Hub (Silent login)
echo "$(date) - Forcing Unity Hub login as Macadmin..." | tee -a "$LOGFILE"
echo "$MACADMIN_PASS" | sudo -S -u "$MACADMIN_USER" /Applications/Unity\ Hub.app/Contents/MacOS/Unity\ Hub --headless login -u "$UNITY_EMAIL" -p "$UNITY_PASSWORD" --remember-me
sleep 10  # Ensure login is processed

# Install Unity Editor with proper logging
LATEST_VERSION=$(ls /Applications/Unity/Hub/Editor/ | sort -V | tail -n 1)
if [[ -z "$LATEST_VERSION" ]]; then
    echo "$(date) - No Unity Editor installed. Installing latest version..." | tee -a "$LOGFILE"
    echo "$MACADMIN_PASS" | sudo -S -u "$MACADMIN_USER" /Applications/Unity\ Hub.app/Contents/MacOS/Unity\ Hub --headless install --version latest &
    
    INSTALL_PID=$!
    while kill -0 $INSTALL_PID 2>/dev/null; do
        echo "$(date) - Unity Editor installation in progress..." | tee -a "$LOGFILE"
        sleep 30
    done

    LATEST_VERSION=$(ls /Applications/Unity/Hub/Editor/ | sort -V | tail -n 1)
fi

UNITY_PATH="/Applications/Unity/Hub/Editor/$LATEST_VERSION/Unity.app/Contents/MacOS/Unity"
if [[ ! -f "$UNITY_PATH" ]]; then
    echo "$(date) - Error: Unity executable not found at $UNITY_PATH" | tee -a "$LOGFILE"
    exit 1
fi

# Serialize Unity as Macadmin
echo "$(date) - Serializing Unity..." | tee -a "$LOGFILE"
echo "$MACADMIN_PASS" | sudo -S -u "$MACADMIN_USER" "$UNITY_PATH" -quit -batchmode -serial "$SERIAL" -username "$UNITY_EMAIL" -password "$UNITY_PASSWORD" 2>&1 | tee -a "$LOGFILE"

EXIT_CODE=${PIPESTATUS[0]}
if [[ $EXIT_CODE -ne 0 ]]; then
    echo "$(date) - Error: Unity serialization failed with exit code $EXIT_CODE" | tee -a "$LOGFILE"
    exit $EXIT_CODE
fi

echo "$(date) - Unity Hub, latest Editor installed, and serialized successfully!" | tee -a "$LOGFILE"
exit 0
