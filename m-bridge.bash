#!/bin/bash
#
# This script acts as a bridge between the system running NadekoBot and
# 'n-main-prep.bash'. To avoid conflicts with manager updates, this script contains
# only essential code.
#
# README:
#   Since this script resides on the user's system, updates pushed to GitHub do not
#   automatically apply. To handle this, the variable $E_BRIDGE_REVISION used to
#   tracks changes. The 'n-main-prep.bash' script has a corresponding variable,
#   $C_LATEST_BRIDGE_REVISION, updated alongside it. When the manager runs,
#   'n-main-prep.bash' compares these values. If they differ, the latest 'm-bridge.bash'
#   version is fetched from GitHub.
#
# IMPORTANT:
#   If you change $manager_branch to anything other than "main" or "dev",
#   you must install the matching version of NadekoBot. For example, if you set
#   $manager_branch to "NadekoV4", you need to install NadekoBot v4. Failing
#   to do so will likely result in a broken installation.
#
########################################################################################
####[ Variables ]#######################################################################


###
### [ Configurable Variables ]
###
### ~~~ THESE VARIABLES CAN BE MODIFIED BY THE END-USER ~~~
###
### When the manager fetches the newest 'm-bridge.bash', it merges all user-modified
### variables (except $manager_repo and $E_FILES_TO_BACK_UP) into the updated script.
###

# The repository containing the manager's scripts.
#
# Only modify this variable if you have created a fork and plan on customizing the
# manager.
#
# Format:  manager_repo="[github username]/[repository name]"
# Default: "StrangeRanger/nadeko-manager-scripts"
manager_repo="StrangeRanger/nadeko-manager-scripts"

# The branch of $manager_repo from which the manager downloads its scripts.
#
# Options:
#   main     = Production-ready (latest stable code)
#   dev      = Development code (may be unstable)
#   NadekoV4 = Manager version for NadekoBot v4
#
# Default: "main"
manager_branch="main"

# Skip checking if all the prerequisites are installed. By setting this variable to
# "true", you acknowledge that the Bot and Manager are not guaranteed to work as
# expected.
#
# Options:
#   true  = Skip checking for prerequisites
#   false = Check for prerequisites
#
# Default: "false"
export E_SKIP_PREREQ_CHECK="false"


# Files to back up when executing option 7.
#
# 1. Paths must start from Nadeko's parent directory (e.g., nadekobot/...).
# 2. Separate files with a space or list them on separate lines.
#     - Valid:   "nadekobot/creds.yml
#                 nadekobot/data/bot.yml"
#     - Valid:   "nadekobot/creds.yml nadekobot/data/bot.yml"
#     - Invalid: "nadekobot/creds.yml, nadekobot/data/bot.yml"
#     - Invalid: "nadekobot/creds.yml,nadekobot/data/bot.yml"
# 3. Neither the file name nor its path can contain spaces.
#
# Default:
#   "nadekobot/creds.yml
#    nadekobot/data/NadekoBot.db
#    nadekobot/data/bot.yml
#    nadekobot/data/gambling.yml
#    nadekobot/data/games.yml
#    nadekobot/data/images.yml
#    nadekobot/data/xp.yml
#    nadekobot/data/xp_template.json"
export E_FILES_TO_BACK_UP="nadekobot/creds.yml
nadekobot/data/NadekoBot.db
nadekobot/data/bot.yml
nadekobot/data/gambling.yml
nadekobot/data/games.yml
nadekobot/data/images.yml
nadekobot/data/xp.yml
nadekobot/data/xp_template.json"

###
### [ General Variables ]
###

# 'm-bridge.bash' revision number.
export E_BRIDGE_REVISION=50
# URL to the raw code of a specified script.
export E_RAW_URL="https://raw.githubusercontent.com/$manager_repo/$manager_branch"


####[ Prepping ]########################################################################


## Change to the directory containing this script.
## NOTE:
##  We need to ensure 'm-bridge.bash' is in the current directory. If the user runs
##  `bash m-bridge.bash` instead of `./m-bridge.bash` while in the correct directory,
##  ${0%/*} will return 'm-bridge.bash' rather than '.', causing the '||' block to
##  execute when it attempts to change into a file instead of a directory.
if [[ ! -f m-bridge.bash ]]; then
    cd "${0%/*}" || {
        echo "Failed to change working directory" >&2
        echo "Change your working directory to that of the executed script"
        exit 1
    }
fi


####[ Main ]############################################################################


echo "Downloading the latest manager..."
curl -O "$E_RAW_URL"/n-main-prep.bash
chmod +x n-main-prep.bash && ./n-main-prep.bash
exit "$?"
