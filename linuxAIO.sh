#!/bin/bash
#
# 'linuxAIO.sh' acts as the intermediary between the system NadekoBot is being hosted on
# and 'installer_prep.sh'. To prevent any conflicts with updates to the installer, this
# script has as little code as deemed necessary.
#
########################################################################################
#### [ Variables ]

########################################################################################
#### [[ Configuration Variables ]]
#### Variables used to modify the behavior of the installer.
####
#### ~~~ THESE VARIABLES CAN BE MODIFIED BY THE END-USER ~~~
####
#### Whenever the installer retrieves the newest version of 'linuxAIO.sh', all modified
#### variables, with the exception of $installer_repo, will be applied to the new
#### version of this script.


# The repository that the installer will use.
#
# The only time that this variable should be modified, is if you have created a fork of
# the repo and plan on making your own modifications to the installer.
#
# Format: installer_repo="[github username]/[repository name]"
installer_repo="StrangeRanger/NadekoBot-BashScript"

# The branch that the installer will use.
#
# Options:
#   master = Production ready code (the latest stable code)
#   dev    = Non-production ready code (has the possibility of breaking something)
#
# Default: master
installer_branch="master"

# The branch or tag (can also be referred to as NadekoBot's version) that the installer
# will download NadekoBot from.
#
# IMPORTANT: Having the installer download and use a version of NadekoBot that is older
#            than the one currently on your system, increases the likelihood of failed
#            builds due to incompatible changes in Nadeko being moved over to the
#            downloaded version.
#
# Options:
#   v3    = Latest version (the master/main branch)
#   x.x.x = Any other branch/tag (refer to the NadekoBot repo for available tags and
#           branches)
#
# Default: v3
export _NADEKO_INSTALL_VERSION="v3"


#### End of [[ Configuration Variables ]]
########################################################################################
#### [[ General Variables ]]


# Used to keep track of changes to 'linuxAIO.sh'.
# Refer to the '[ Prepping ]' section of 'installer_prep.sh' for more information.
export _LINUXAIO_REVISION="27"
# URL of the raw version of a (to be) specified script.
export _RAW_URL="https://raw.githubusercontent.com/$installer_repo/$installer_branch"


#### End of [[ General Variables ]]
########################################################################################

#### End of [ Variables ]
########################################################################################
#### [ Main ]


echo "Downloading the latest installer..."
curl -O "$_RAW_URL"/installer_prep.sh
sudo chmod +x installer_prep.sh \
    && ./installer_prep.sh \
    || exit "$?"  # Will provide the exit code passed by 'installer_prep.sh'.


#### End of [ Main ]
########################################################################################
