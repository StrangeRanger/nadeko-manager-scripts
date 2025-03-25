#!/usr/bin/env bash
#
# Download the script that initiates the installation and management of NadekoBot.
#
############################################################################################

# Enable strict error handling.
set -euxo pipefail


C_BRIDGE="m-bridge.bash"
C_BRIDGE_BRANCH="main"
C_BRIDGE_URL="https://raw.githubusercontent.com/StrangeRanger/nadeko-manager-scripts/$C_BRIDGE_BRANCH/$C_BRIDGE"


echo "Downloading $C_BRIDGE..."
curl -L "$C_BRIDGE_URL" -o "$C_BRIDGE"

echo "Setting $C_BRIDGE as executable..."
chmod +x "$C_BRIDGE"

echo "Done"
