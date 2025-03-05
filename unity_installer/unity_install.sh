# Function to completely reset and re-add Keychain entry silently using Macadmin's login Keychain
setup_keychain_entry() {
    local USERNAME=$1
    local USER_HOME=$(eval echo ~$USERNAME)

    echo "$(date) - Setting up Keychain entry for user: $USERNAME" | tee -a "$LOGFILE"

    # Ensure Keychain exists for user
    if [[ ! -f "$USER_HOME/Library/Keychains/login.keychain-db" ]]; then
        echo "$(date) - Creating login Keychain for $USERNAME" | tee -a "$LOGFILE"
        sudo -u "$USERNAME" security create-keychain -p "" "$USER_HOME/Library/Keychains/login.keychain-db"
    fi

    # Delete any old Unity Hub Keychain entry if it exists
    sudo -u "$USERNAME" security delete-generic-password -s "com.unity3d.unityhub" -a "$UNITY_EMAIL" 2>/dev/null

    # Add new Unity Hub Keychain entry silently using the login Keychain
    echo "$MACADMIN_PASS" | sudo -S -u "$USERNAME" security add-generic-password -s "com.unity3d.unityhub" -a "$UNITY_EMAIL" -w "$UNITY_PASSWORD" -U "$USER_HOME/Library/Keychains/login.keychain-db"

    # Grant Unity Hub access without prompting
    echo "$MACADMIN_PASS" | sudo -S -u "$USERNAME" security set-key-partition-list -S "apple-tool:,apple:,teamid:6D757G3MZV" -s "com.unity3d.unityhub" -a "$UNITY_EMAIL" -U "$USER_HOME/Library/Keychains/login.keychain-db"

    # Verify entry exists before continuing
    if ! sudo -u "$USERNAME" security find-generic-password -s "com.unity3d.unityhub" -a "$UNITY_EMAIL" "$USER_HOME/Library/Keychains/login.keychain-db" >/dev/null 2>&1; then
        echo "$(date) - ERROR: Keychain entry creation failed for $USERNAME!" | tee -a "$LOGFILE"
        exit 1
    else
        echo "$(date) - Keychain entry successfully created for $USERNAME." | tee -a "$LOGFILE"
    fi
}

# Set up Keychain for Macadmin first (before Unity Hub opens)
setup_keychain_entry "$MACADMIN_USER"

# Loop through all users and set up their Keychain entries (excluding system users)
for USER in $(ls /Users); do
    if [[ "$USER" != "Shared" && "$USER" != ".localized" && "$USER" != "Guest" ]]; then
        setup_keychain_entry "$USER"
    fi
done
