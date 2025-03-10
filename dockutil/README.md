Dock Management Script for macOS

Automate Dock Customization with dockutil via Jamf
This script removes all default macOS Dock items and adds custom applications & folders, ensuring a clean and uniform Dock setup across all managed Macs.

🚀 Features
Fully wipes the Dock (removes all default apps).
Adds custom applications (e.g., Chrome, Firefox, Unity, Discord, etc.).
Pins Documents & Downloads folders to the Dock.
Deployable via Jamf Pro (for automated management).
Ensures consistent Dock setup across all users.
🛠️ Prerequisites
dockutil must be installed on the system. The script automatically installs it if missing.
The script should be run with admin privileges (sudo).
📥 Installation

1️⃣ Clone the Repo
git clone https://github.com/YOUR-ORG/macOS-Dock-Setup.git
cd macOS-Dock-Setup
2️⃣ Make the Script Executable
chmod +x setup_dock.sh
3️⃣ Run the Script Locally (for Testing)
sudo ./setup_dock.sh

Jamf Policy Todo
