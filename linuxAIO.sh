#!/bin/bash

################################################################################
#
# linuxAIO acts as the intermediary between the system Nadeko is being hosted
# on and the 'instaler_prep.sh'. To prevent any conflict with updates to
# the installer, this script has as little code as deemed necessary. In
# addition, linuxAIO is the only script that will remain on the system.
#
################################################################################
#
    # The exports below are for dev/testing purpouses (DO NOT MODIFY)
    export installer_branch="dev" # Determines which installer branch is used
    export installer_repo="StrangeRanger/NadekoBot-BashScript" # Determines which repo is used

    # Checks to see if this script was executed with root privilege
    if ((EUID != 0)); then 
        echo "Please run this script as root or with root privilege" >&2
        echo -e "\nExiting..."
        exit 1 
    fi

    echo "Downloading the latest installer..."
    wget -N https://raw.githubusercontent.com/"$installer_repo"/"$installer_branch"/installer_prep.sh || {
        echo "Failed to download 'nadeko_master_installer.sh'..." >&2
        echo -e "\nExiting..."
        exit 1
    }
    chmod +x nadeko_master_installer.sh && ./nadeko_master_installer.sh
