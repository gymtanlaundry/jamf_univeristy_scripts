#!/bin/bash

LOGFILE="/var/log/garageband_setup.log"
echo "$(date) - Starting GarageBand installation and content setup..." | tee -a "$LOGFILE"

# Function to install mas-cli if missing
install_mas() {
    if ! command -v mas &> /dev/null; then
        echo "$(date) - Installing mas-cli..." | tee -a "$LOGFILE"
        brew install mas
    fi
}

# Install GarageBand if not present
install_garageband() {
    if [ ! -d "/Applications/GarageBand.app" ]; then
        echo "$(date) - GarageBand not found. Installing from Mac App Store..." | tee -a "$LOGFILE"
        install_mas
        mas install 682658836  # GarageBand App Store ID
    else
        echo "$(date) - GarageBand is already installed." | tee -a "$LOGFILE"
    fi
}

# Install additional GarageBand content
install_additional_content() {
    echo "$(date) - Checking and installing additional GarageBand content..." | tee -a "$LOGFILE"
    
    # Ensure the softwareupdate service is running
    /usr/sbin/softwareupdate --list | grep "GarageBand" | tee -a "$LOGFILE"
    
    # Install additional sounds and loops
    /usr/sbin/softwareupdate --install "GarageBand Instruments and Apple Loops" | tee -a "$LOGFILE"
}

# Open GarageBand to trigger content installation
launch_garageband() {
    echo "$(date) - Launching GarageBand to finalize content installation..." | tee -a "$LOGFILE"
    open -a "/Applications/GarageBand.app"
    sleep 20  # Wait for GarageBand to load
}

# Automate UI interaction with AppleScript
automate_installation() {
    echo "$(date) - Automating installation of additional content..." | tee -a "$LOGFILE"
    osascript <<EOF
    tell application "GarageBand"
        activate
        delay 10
        try
            tell application "System Events"
                -- Click "Download" button if available
                if exists (button "Download" of window 1 of process "GarageBand") then
                    click button "Download" of window 1 of process "GarageBand"
                end if
            end tell
        end try
    end tell
EOF
}

# Main Execution Flow
install_garageband
install_additional_content
launch_garageband
automate_installation

echo "$(date) - GarageBand installation and setup completed." | tee -a "$LOGFILE"
exit 0
