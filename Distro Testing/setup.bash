#!/usr/bin/env bash
#
# Create a shared directory to be used by all the docker containers, and download the
# 'm-bridge.bash' script.
#
########################################################################################

C_BRIDGE="m-bridge.bash"
C_BRIDGE_BRANCH="dev"
C_BRIDGE_URL="https://raw.githubusercontent.com/StrangeRanger/nadeko-manager-scripts/$C_BRIDGE_BRANCH/$C_BRIDGE"

if [[ ! -d shared ]]; then
    echo "Creating shared directory..."
    mkdir shared
else
    echo "Shared directory already exists"
fi

if [[ ! -f shared/$C_BRIDGE ]]; then
    echo "Downloading $C_BRIDGE..."
    curl -L "$C_BRIDGE_URL" -o "shared/$C_BRIDGE"
else
    echo "$C_BRIDGE already exists"
fi

echo "Setting $C_BRIDGE as executable..."
chmod +x "shared/$C_BRIDGE"

echo "Setup complete"
