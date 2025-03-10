#!/bin/bash

LOGFILE="/var/log/unity_setup.log"
echo "$(date) - Starting Unity Hub & Unity Editor 6+ installation..." | tee -a "$LOGFILE"

# URLs for the latest Unity Hub
UNITY_HUB_URL="https://public-cdn.cloud.unity3d.com/hub/prod/UnityHubSetup.dmg"
UNITY_HUB_DMG="/tmp/UnityHubSetup.dmg"

# Admin Account
MACADMIN_USER="Macadmin"
MACADMIN_PASS="YourMacadminPassword"

# Ensure logging directory exists
mkdir -p "$(dirname "$LOGFILE")"
touch "$LOGFILE"
chmod 666 "$LOGFILE"

### **STEP 1: Install Unity Hub**
if [[ ! -d "/Applications/Unity Hub.app" ]]; then
    echo "$(date) - Unity Hub not found. Downloading latest version..." | tee -a "$LOGFILE"
    curl -L "$UNITY_HUB_URL" -o "$UNITY_HUB_DMG"

    if [[ ! -f "$UNITY_HUB_DMG" ]]; then
        echo "$(date) - ERROR: Unity Hub DMG failed to download!" | tee -a "$LOGFILE"
        exit 1
    fi

    echo "$MACADMIN_PASS" | sudo -S hdiutil attach "$UNITY_HUB_DMG" -nobrowse -quiet
    sleep 5  

    HUB_VOLUME=$(ls /Volumes | grep -i "Unity Hub" | head -n 1)
    HUB_PATH="/Volumes/$HUB_VOLUME/Unity Hub.app"

    if [[ -z "$HUB_VOLUME" || ! -d "$HUB_PATH" ]]; then
        echo "$(date) - ERROR: Unity Hub app did not mount correctly!" | tee -a "$LOGFILE"
        echo "$MACADMIN_PASS" | sudo -S hdiutil detach "/Volumes/$HUB_VOLUME" -force
        exit 1
    fi

    echo "$MACADMIN_PASS" | sudo -S cp -R "$HUB_PATH" /Applications/
    echo "$MACADMIN_PASS" | sudo -S hdiutil detach "/Volumes/$HUB_VOLUME" -force
    echo "$MACADMIN_PASS" | sudo -S xattr -dr com.apple.quarantine "/Applications/Unity Hub.app"
    echo "$(date) - Unity Hub installed successfully." | tee -a "$LOGFILE"
else
    echo "$(date) - Unity Hub is already installed." | tee -a "$LOGFILE"
fi

### **STEP 2: Install Unity 6+ via Unity Hub**
echo "$(date) - Checking Unity CLI access..." | tee -a "$LOGFILE"

if ! /Applications/Unity\ Hub.app/Contents/MacOS/Unity\ Hub --help > /dev/null 2>&1; then
    echo "$(date) - ERROR: Unity Hub CLI not accessible!" | tee -a "$LOGFILE"
    exit 1
fi

echo "$(date) - Downloading and installing latest Unity Editor 6+..." | tee -a "$LOGFILE"
/Applications/Unity\ Hub.app/Contents/MacOS/Unity\ Hub --headless install --version latest

# Wait for installation to complete
sleep 30

# Verify Unity installation
if [[ -d "/Applications/Unity" ]]; then
    echo "$(date) - Unity Editor 6+ installed successfully." | tee -a "$LOGFILE"
else
    echo "$(date) - ERROR: Unity Editor installation failed!" | tee -a "$LOGFILE"
    exit 1
fi

echo "$(date) - Unity Hub & Unity 6+ installation complete!" | tee -a "$LOGFILE"
exit 0

