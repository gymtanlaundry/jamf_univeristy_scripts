#!/bin/bash

# Path to dockutil
DOCKUTIL="/usr/local/bin/dockutil"

# Remove all existing Dock items
echo "Removing existing Dock items..."
$DOCKUTIL --remove all --no-restart

# Add new apps
echo "Adding new Dock items..."
$DOCKUTIL --add "/Applications/Sublime Text.app"
$DOCKUTIL --add "/Applications/Aseprite.app"
$DOCKUTIL --add "/Applications/Blender.app"
$DOCKUTIL --add "/Applications/Cyberduck.app"
$DOCKUTIL --add "/Applications/Discord.app"
$DOCKUTIL --add "/Applications/GIMP.app"
$DOCKUTIL --add "/Applications/SourceTree.app"
$DOCKUTIL --add "/Applications/Steam.app"
$DOCKUTIL --add "/Applications/Unity Hub.app"
$DOCKUTIL --add "/Applications/GitHub Desktop.app"
$DOCKUTIL --add "/Applications/Firefox.app"
$DOCKUTIL --add "/Applications/Google Chrome.app"

# Add Folders (Documents & Downloads)
echo "Adding Documents & Downloads to Dock..."
$DOCKUTIL --add ~/Documents --view grid --display folder --section others
$DOCKUTIL --add ~/Downloads --view fan --display stack --section others

# Restart the Dock
echo "Restarting Dock..."
killall Dock

echo "Dock setup completed!"
