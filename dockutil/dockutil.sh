###Run this in your terminal with sudo. add this as a dependency if automating. 
if ! command -v dockutil &> /dev/null; then
    echo "dockutil not found, installing..."
    curl -L https://github.com/kcrawford/dockutil/releases/latest/download/dockutil.pkg -o /tmp/dockutil.pkg
    sudo installer -pkg /tmp/dockutil.pkg -target /
    rm /tmp/dockutil.pkg
fi
