#!/bin/bash
#
# linuxAIO acts as the intermediary between the system NadekoBot is being hosted on and
# 'installer_prep.sh'. To prevent any conflicts with updates to the installer, this
# script has as little code as deemed necessary.
#
########################################################################################
#### [ Development Variables ]
#### The variables below are for dev/testing purpouses (!!! DO NOT MODIFY !!!).


# Used to keep track of changes to 'linuxAIO.sh'.
# Refer to the '[ Prepping ]' section of 'installer_prep.sh' for more information.
export _LINUXAIO_REVISION="13"
# Determines from which repository and what user the installer will use.
installer_repo="StrangeRanger/NadekoBot-BashScript"


#### End of [ Development Variables ]
########################################################################################
#### [ Configuration Variables ]
#### The variables below are used to modify the behavior of the installer and CAN BE
#### modified by the end user.


# The branch that the installer will use.
# master = The latest stable code
# dev    = Non-production ready code
#
# Default: master
installer_branch="master"

# Determines whether or not the installer can be run as the root user:
# true  = can be run with root privilege
# false = cannot be run with root privilege (recommended)
#
# Default: false
allow_run_as_root=false

# Determines what branch or tag the installer will download NadekoBot from.
# 1.9    = Latest version (the master/main branch)
# 2.39.1 = Version (tag) 2.39.1 of NadekoBot
# x.x.x  = So on and so forth (refer to the NadekoBot repo for available tags and
#          branches)
#
# Default: 1.9
export _NADEKO_INSTALL_VERSION="1.9"


#### End of [ Configuration Variables ]
########################################################################################
#### [ Variables ]
#### Variables that aren't Development or Configurable specific.


# URL to the raw version of a specified script.
export _RAW_URL="https://raw.githubusercontent.com/$installer_repo/$installer_branch"


#### End of [ Variables ]
########################################################################################
#### [ Main ]


# If executed with root privilege and $allow_run_as_root is false...
if [[ $EUID = 0 && $allow_run_as_root = false ]]; then
    echo "\033[1;31mPlease run this script without root privilege" >&2
    echo "\033[0;36mWhile you will be performing specific tasks with root privilege," \
        "running the installer in it's entirety as root is not recommended\033[0m"
    echo -e "\nExiting..."
    exit 1
fi

echo "Downloading the latest installer..."
curl "$_RAW_URL"/installer_prep.sh -o installer_prep.sh || {
    echo "\033[1;31mFailed to download 'installer_prep.sh'\033[0m" >&2
    echo -e "\nExiting..."
    exit 1
}
# Set the execution permissions for the downloaded script, then executes it.
sudo chmod +x installer_prep.sh && ./installer_prep.sh


#### End of [ Main ]
########################################################################################

