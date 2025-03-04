✅ 1. Run Script as "After" in Enrollment or Recurring Check-in
Best triggers:
"Enrollment Complete" → Ensures new devices are properly set.
"Recurring Check-in" (e.g., every 15 minutes) → Keeps time accurate.
"Startup" → Ensures time sync at every reboot.
📌 Why? Some settings (like network time sync) may fail during early-stage provisioning.

✅ 2. Verify Internet Connectivity Before Syncing
Since NTP requires an internet connection, add a check before running the sync:

# Check if we have an active internet connection
if ! nc -zw1 time.apple.com 123; then
    log "No internet connection or NTP server unreachable. Skipping time sync."
    exit 1
fi
📌 Why? Prevents script failures when offline.

✅ 3. Ensure the Time Sync Service Restarts
Some macOS versions may not immediately apply time sync changes. Restarting the timed service helps:

launchctl stop com.apple.timed
launchctl start com.apple.timed
log "Restarted the time synchronization service."
📌 Why? Helps macOS apply NTP settings immediately.

✅ 4. Deploy as a Jamf Policy with Logging Enabled
Enable "Execution Frequency" → Ongoing or Once per Computer.
Set "Log All Output" in Jamf Pro Policy to capture script success/failures.
📌 Why? Ensures visibility into failures.

✅ 5. Use a Configuration Profile for Persistent NTP Settings
Jamf Configuration Profiles can enforce NTP settings persistently.

Go to Jamf Pro → Computers → Configuration Profiles
Create a Custom Payload with this .mobile
