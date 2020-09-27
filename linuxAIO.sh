#!/bin/bash

################################################################################
#
# linuxAIO acts as the intermediary between the system Nadeko is being hosted
# on and the 'installer_prep.sh'. To prevent any conflicts with updates to
# the installer, this script has as little code as deemed necessary. In
# addition, linuxAIO is the only script that will remain on the system.
#
################################################################################
#
    # The exports below are for dev/testing purpouses (DO NOT MODIFY)
    export linuxAIO_revision="3"                               # Keeps track of changes to linuxPMI.sh
    export installer_branch="dev"                              # Determines which installer branch is used
    export installer_repo="StrangeRanger/NadekoBot-BashScript" # Determines which repo is used

    # Dictates whether or not the installer can be run as the root user:
    # true = can be run with root privilege
    # false = cannot be run with root privilege (recommended)
    allow_run_as_root="false"

    # Checks if this script was executed with root privilege
    if ((EUID == 0)) && [[ $allow_run_as_root = "false" ]]; then
        echo "Please run this script without root privilege" >&2
        echo "While you will be performing specific tasks with root privilege," \
            "running the installer in it's entirety as root is not recommended"
        echo -e "\nExiting..."
        exit 1
    fi

    echo "Downloading the latest installer..."
    curl https://raw.githubusercontent.com/"$installer_repo"/"$installer_branch"/installer_prep.sh \
        -o installer_prep.sh || {
        echo "Failed to download 'installer_prep.sh'..." >&2
        echo -e "\nExiting..."
        exit 1
    }
    sudo chmod +x installer_prep.sh && ./installer_prep.sh
