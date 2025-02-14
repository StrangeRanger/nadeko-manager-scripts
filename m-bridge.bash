#!/bin/bash
#
# This script acts as a bridge between the system running NadekoBot and
# 'n-main-prep.bash'. To avoid conflicts with Manager updates, this script contains
# only essential code.
#
# README:
#   The bridge revision ($E_BRIDGE_REVISION) is used to track changes in this script. If
#   it doesn't match $C_LATEST_BRIDGE_REVISION in 'n-main-prep.bash', the latest version
#   of 'm-bridge.bash' is downloaded.
#
# IMPORTANT:
#   Changing $manager_branch to something other than "main" or "dev" means you must
#   install the corresponding NadekoBot version (e.g. "NadekoV4" requires NadekoBot v4),
#   or the installation may break.
#
########################################################################################
####[ Variables ]#######################################################################


###
### [ Configurable Variables ]
###
### When the manager fetches the newest 'm-bridge.bash', it merges all user-modified
### variables (except $manager_repo and $E_FILES_TO_BACK_UP) into the updated script.
###

# The repository containing the manager's scripts.
#
# Format:  manager_repo="[github username]/[repository name]"
# Default: "StrangeRanger/nadeko-manager-scripts"
manager_repo="StrangeRanger/nadeko-manager-scripts"

# The branch of $manager_repo from which the manager downloads its scripts. If you
# change this variable to anything other than 'main' or 'dev', please read the IMPORTANT
# note above.
#
# Options:
#   main     = Production-ready (latest stable code)
#   dev      = Development code (may be unstable)
#   NadekoV4 = Manager version for NadekoBot v4
#
# Default: "main"
manager_branch="main"


# Only versions matching this major version will be listed for download. If you change
# this variable, please read the IMPORTANT note above.
#
# Options:
#   "5" = NadekoBot v5
#   "4" = NadekoBot v4
#
# Default: "5"
export E_NADEKO_MAJOR_VERSION="5"

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
### [ Non-configurable Variables ]
###

export E_BRIDGE_REVISION=51
export E_RAW_URL="https://raw.githubusercontent.com/$manager_repo/$manager_branch"


####[ Prepping ]########################################################################


## Ensure the script is executed from its directory to avoid path issues.
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
