#!/bin/bash

LOGFILE="/var/log/unity_setup.log"

echo "$(date) - Starting Unity Hub, Editor installation, and serialization..." | tee -a "$LOGFILE"

# Define Unity Hub download URL
UNITY_HUB_URL="https://public-cdn.cloud.unity3d.com/hub/prod/UnityHubSetup.dmg"

# Check if Unity Hub is installed
if [[ ! -d "/Applications/Unity Hub.app" ]]; then
    echo "$(date) - Unity Hub not found. Downloading..." | tee -a "$LOGFILE"

    # Download Unity Hub DMG
    curl -L "$UNITY_HUB_URL" -o /tmp/UnityHubSetup.dmg

    # Mount and install Unity Hub
    hdiutil attach /tmp/UnityHubSetup.dmg
    sudo cp -R "/Volumes/Unity Hub/Unity Hub.app" /Applications/
    hdiutil detach "/Volumes/Unity Hub"

    echo "$(date) - Unity Hub installed successfully." | tee -a "$LOGFILE"
else
    echo "$(date) - Unity Hub is already installed." | tee -a "$LOGFILE"
fi

# Get the latest Unity version available
LATEST_VERSION=$(/Applications/Unity\ Hub.app/Contents/MacOS/Unity\ Hub --headless editors --latest-installed | tail -n 1)
echo "$(date) - Latest Unity version detected: $LATEST_VERSION" | tee -a "$LOGFILE"

# Install the latest Unity Editor
echo "$(date) - Installing Unity Editor version $LATEST_VERSION..." | tee -a "$LOGFILE"
/Applications/Unity\ Hub.app/Contents/MacOS/Unity\ Hub --headless install --version $LATEST_VERSION

# Wait for installation to complete
sleep 300  

# Define Unity path after installation
UNITY_PATH="/Applications/Unity/Hub/Editor/$LATEST_VERSION/Unity.app/Contents/MacOS/Unity"

# Ensure Unity exists before serializing
if [[ ! -f "$UNITY_PATH" ]]; then
    echo "$(date) - Error: Unity executable not found at $UNITY_PATH" | tee -a "$LOGFILE"
    exit 1
fi

# Assign license
SERIAL="E4-"
USERNAME="Owner username"
PASSWORD="Owner password"

echo "$(date) - Serializing Unity..." | tee -a "$LOGFILE"
"$UNITY_PATH" -quit -batchmode -serial "$SERIAL" -username "$USERNAME" -password "$PASSWORD" 2>&1 | tee -a "$LOGFILE"

EXIT_CODE=${PIPESTATUS[0]}

if [[ $EXIT_CODE -ne 0 ]]; then
    echo "$(date) - Error: Unity serialization failed with exit code $EXIT_CODE" | tee -a "$LOGFILE"
    exit $EXIT_CODE
fi

echo "$(date) - Unity Hub, latest Editor installed, and serialized successfully!" | tee -a "$LOGFILE"
exit 0
