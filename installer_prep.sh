#!/bin/bash

## Modify output text color.
_GREEN="$(printf '\033[0;32m')"
_CYAN="$(printf '\033[0;36m')"
_RED="$(printf '\033[1;31m')"
_NC="$(printf '\033[0m')"


echo -n "${_CYAN}Several scripts have been renamed, and require special intervention." \
    "When the installer has exited, re-execute the installer and re-run Nadeko in" \
    "your chosen mode. "
read -rp "Press [Enter] to continue.${_NC}"

## Save the values of the current Configuration Variables specified in 'linuxAIO', to be
## set in the new 'linuxAIO'.
installer_branch=$(grep '^installer_branch=.*' linuxAIO.sh)  # A.1.
installer_branch_found="$?"	                                 # A.1.
nadeko_install_version=$(grep '^export _NADEKO_INSTALL_VERSION=.*' linuxAIO.sh)  # A.2.
nadeko_install_version_found="$?"                                                # A.2.

curl -O "$_RAW_URL"/linuxAIO && sudo chmod +x linuxAIO

echo "Applying existing configurations to the new 'linuxAIO'..."

## Set $installer_branch inside of the new 'linuxAIO'.
[[ $installer_branch_found = 0 ]] \
    && sed -i "s/^installer_branch=.*/$installer_branch/" linuxAIO

## Set $nadeko_install_version inside of the new 'linuxAIO'.
[[ $nadeko_install_version_found = 0 ]] \
    && sed -i "s/^export _NADEKO_INSTALL_VERSION=.*/$nadeko_install_version/" linuxAIO

echo "Cleaning up..."
[[ -f NadekoRun.sh ]]      && mv NadekoRun.sh NadekoRun
[[ -f installer-prep ]]    && rm installer-prep
[[ -f installer_prep.sh ]] && rm installer_prep.sh

if [[ -f linuxAIO.sh && -f linuxAIO ]]; then
    echo "Deleting 'linuxAIO.sh'..."
    rm linuxAIO.sh
else
    echo "${_RED}'linuxAIO.sh' and 'linuxAIO' should exist, but one or both do not.${_NC}"
    exit 1
fi

exit 0
