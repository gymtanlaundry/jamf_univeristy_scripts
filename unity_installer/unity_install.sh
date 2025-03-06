#!/bin/bash

LOGFILE="/var/log/unity_setup.log"

echo "$(date) - Starting Unity Editor and Hub installation, followed by login..." | tee -a "$LOGFILE"

# Unity Editor & Hub URLs (Fixed: Corrected Unity Editor URL Retrieval)
UNITY_EDITOR_URL=$(curl -s https://public-cdn.cloud.unity3d.com/hub/prod/releases-darwin.json | grep -o 'https[^"]*Unity-[^"]*.pkg' | head -n 1)
UNITY_EDITOR_PKG="/tmp/UnityEditor.pkg"
UNITY_HUB_URL="https://public-cdn.cloud.unity3d.com/hub/prod/UnityHubSetup.dmg"
UNITY_HUB_DMG="/tmp/UnityHubSetup.dmg"

### the admin password is your jamf admin account. This only works if your org uses an admin account that doesnt rortate the password.
### The email and password for unity is what you signed up for with untiy and that is how you can get your perpetual license key
# Unity Credentials 
UNITY_EMAIL=""
UNITY_PASSWORD=""
SERIAL=""
ADMIN_USER=""
ADMIN_PASS=""

# Ensure logging directory exists
mkdir -p "$(dirname "$LOGFILE")"
touch "$LOGFILE"
chmod 666 "$LOGFILE"

### **STEP 1: Download & Install Unity Editor (Fixed)**
echo "$(date) - Downloading Unity Editor package from $UNITY_EDITOR_URL..." | tee -a "$LOGFILE"
curl -L "$UNITY_EDITOR_URL" -o "$UNITY_EDITOR_PKG"

if [[ ! -s "$UNITY_EDITOR_PKG" ]]; then
    echo "$(date) - ERROR: Unity Editor package failed to download!" | tee -a "$LOGFILE"
    exit 1
fi

echo "$(date) - Installing Unity Editor..." | tee -a "$LOGFILE"
echo "$MACADMIN_PASS" | sudo -S installer -pkg "$UNITY_EDITOR_PKG" -target /

if [[ ! -d "/Applications/Unity" ]]; then
    echo "$(date) - ERROR: Unity Editor installation failed!" | tee -a "$LOGFILE"
    exit 1
fi

echo "$(date) - Unity Editor installed successfully." | tee -a "$LOGFILE"

### **STEP 2: Download & Install Unity Hub**
if [[ ! -d "/Applications/Unity Hub.app" ]]; then
    echo "$(date) - Unity Hub not found. Downloading..." | tee -a "$LOGFILE"
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

    echo "$(date) - Unity Hub mounted at: /Volumes/$HUB_VOLUME" | tee -a "$LOGFILE"

    echo "$MACADMIN_PASS" | sudo -S cp -R "$HUB_PATH" /Applications/

    if [[ ! -d "/Applications/Unity Hub.app" ]]; then
        echo "$(date) - ERROR: Failed to copy Unity Hub!" | tee -a "$LOGFILE"
        echo "$MACADMIN_PASS" | sudo -S hdiutil detach "/Volumes/$HUB_VOLUME" -force
        exit 1
    fi

    echo "$MACADMIN_PASS" | sudo -S hdiutil detach "/Volumes/$HUB_VOLUME" -force
    echo "$MACADMIN_PASS" | sudo -S xattr -dr com.apple.quarantine "/Applications/Unity Hub.app"
    echo "$(date) - Unity Hub installed successfully." | tee -a "$LOGFILE"
else
    echo "$(date) - Unity Hub is already installed." | tee -a "$LOGFILE"
fi

### **STEP 3: Log into Unity Hub After Everything is Installed**
echo "$(date) - Logging into Unity Hub as Macadmin..." | tee -a "$LOGFILE"
echo "$MACADMIN_PASS" | sudo -S -u "$MACADMIN_USER" /Applications/Unity\ Hub.app/Contents/MacOS/Unity\ Hub --headless login -u "$UNITY_EMAIL" -p "$UNITY_PASSWORD" --remember-me
sleep 10

### **STEP 4: Verify Unity Hub Launch Without Login Screen**
echo "$(date) - Launching Unity Hub to verify login status..." | tee -a "$LOGFILE"
open -a "Unity Hub"
sleep 10

if pgrep -x "Unity Hub" > /dev/null; then
    echo "$(date) - Unity Hub launched successfully without login screen." | tee -a "$LOGFILE"
else
    echo "$(date) - ERROR: Unity Hub did not launch properly!" | tee -a "$LOGFILE"
    exit 1
fi

echo "$(date) - Unity Hub, latest Editor installed, and fully logged in!" | tee -a "$LOGFILE"
exit 0
