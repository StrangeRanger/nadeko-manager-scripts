#!/bin/bash
#
# Acts as a transition script from linuxAIO revision 36 to 37. During these changes,
# many of the files were renamed and had the file extension ('.sh') removed.
#
########################################################################################
#### [ Variables ]


## Modify output text color.
cyan="$(printf '\033[0;36m')"
red="$(printf '\033[1;31m')"
nc="$(printf '\033[0m')"


#### End of [ Variables ]
########################################################################################
#### [ Main ]


echo -n "${cyan}There've been some changes that require special intervention. When" \
    "the installer has exited, re-execute the installer and re-run NadekoBot in your" \
    "chosen run mode. "
read -rp "Press [Enter] to continue.${nc}"

## Save the values of the current Configuration Variables specified in 'linuxAIO.sh', to
## be set in 'linuxAIO'.
installer_branch=$(grep '^installer_branch=.*' linuxAIO.sh)  # A.1.
installer_branch_found="$?"	                                 # A.1.
nadeko_install_version=$(grep '^export _NADEKO_INSTALL_VERSION=.*' linuxAIO.sh)  # A.2.
nadeko_install_version_found="$?"                                                # A.2.

curl -O "$_RAW_URL"/linuxAIO && sudo chmod +x linuxAIO
echo "Applying existing configurations to 'linuxAIO'..."

## Set $installer_branch inside of 'linuxAIO'.
[[ $installer_branch_found = 0 ]] \
    && sed -i "s/^installer_branch=.*/$installer_branch/" linuxAIO
## Set $nadeko_install_version inside of 'linuxAIO'.
[[ $nadeko_install_version_found = 0 ]] \
    && sed -i "s/^export _NADEKO_INSTALL_VERSION=.*/$nadeko_install_version/" linuxAIO

echo "Cleaning up..."
[[ -f NadekoRun.sh ]]      && mv NadekoRun.sh NadekoRun
[[ -f installer-prep ]]    && rm installer-prep
[[ -f installer_prep.sh ]] && rm installer_prep.sh

if [[ -f linuxAIO.sh && -f linuxAIO ]]; then
    rm linuxAIO.sh
else
    echo "${red}'linuxAIO.sh' and 'linuxAIO' should exist, but one or both do not.${nc}"
    exit 1
fi


#### End of [ Main ]
########################################################################################
