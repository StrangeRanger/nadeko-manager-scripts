#!/bin/bash
#
# This script checks for a newer release of 'linuxAIO' and, if available, downloads it.
# Any existing configurations from the old version are then transferred to the new one
# where possible.
#
########################################################################################
####[ Functions ]#######################################################################


####
# Reverts any changes made to 'linuxAIO' if this script is interrupted or fails,
# restoring the older version if it still exists.
#
# EXITS:
#   - 1: The script terminates immediately.
revert() {
    if [[ -f linuxAIO.old && ! -f linuxAIO ]]; then
        echo ""
        echo -n "${E_INFO}Restoring the previous version of 'linuxAIO'..."
        mv linuxAIO.old linuxAIO
        chmod +x linuxAIO
    fi

    exit 1
}

####
# Downloads the latest version of 'linuxAIO' and transfers any existing configurations
# (e.g., the installer branch) from the old version.
download_and_transfer() {
    local installer_branch
    local installer_branch_found
    installer_branch=$(grep '^installer_branch=.*' linuxAIO.old)
    installer_branch_found="$?"

    echo "${E_INFO}Downloading latest version of 'linuxAIO'..."

    curl -O "$E_RAW_URL"/linuxAIO || {
        E_STDERR "Failed to download 'linuxAIO'"
        revert
    }
    chmod +x linuxAIO

    echo "${E_INFO}Applying existing configurations to the new 'linuxAIO'..."

    [[ $installer_branch_found == 0 ]] \
        && sed -i "s/^installer_branch=.*/$installer_branch/" linuxAIO
}

####
# Performs additional checks and modifications for 'linuxAIO' revision 45 and earlier,
# ensuring compatibility with updated structures.
#
# RETURNS:
#   - 0: If the function completes successfully or no actions are required.
revision_45() {
    [[ -f $E_BOT_DIR/$E_CREDS_EXAMPLE && -f $E_BOT_DIR/NadekoBot.dll ]] \
        && return 0

    echo "${E_WARN}The new version of 'linuxAIO' has several breaking changes from" \
        "revision 45 and earlier. They will be handled automatically."
    echo "${E_NOTE}For more information, view the 'v5.0.0' release notes at" \
            "https://github.com/StrangeRanger/NadekoBot-BashScript/blob/main/CHANGELOG.md"
    read -rp "${E_NOTE}Press [Enter] to continue"

    echo "${E_INFO}Renaming '$E_BOT_DIR' to '$E_BOT_DIR.rev45.bak'..."
    mv "$E_BOT_DIR" "$E_BOT_DIR.rev45.bak"

    echo "${E_INFO}Copying '$E_BOT_DIR.rev45.bak/output' to '$E_BOT_DIR'..."
    cp -r "$E_BOT_DIR.rev45.bak/output" "$E_BOT_DIR"

    echo "${E_IMP}It is highly recommended to downloaded the newest version of" \
        "NadekoBot before continuing."
}


####[ Trapping Logic ]##################################################################


trap 'revert' SIGINT


####[ Main ]############################################################################


printf "%s" "$E_CLR_LN"  # Clear the "Downloading 'linuxAIO'..." message.
read -rp "${E_NOTE}Press [Enter] to download the latest version"

if [[ -f linuxAIO.old ]]; then
    echo "${E_INFO}Removing existing 'linuxAIO.old'..."
    rm linuxAIO.old
fi

if [[ -f linuxAIO.sh ]]; then
    echo "${E_INFO}Backing up 'linuxAIO.sh' as 'linuxAIO.old'..."
    mv linuxAIO.sh linuxAIO.old
elif [[ -f linuxAIO ]]; then
    echo "${E_INFO}Backing up 'linuxAIO' as 'linuxAIO.old'..."
    mv linuxAIO linuxAIO.old
fi

chmod -x linuxAIO.old

## Due to changes in 'linuxAIO', existing configurations cannot be directly applied to
## the newest version of 'linuxAIO'. Instead, these configurations are backed up as
## 'linuxAIO.old', and the user must reconfigure 'linuxAIO' manually.
#
# shellcheck disable=SC2153
#   $_LINUXAIO_REVISION and $_RAW_URL were used in revision 38 and earlier. Therefore,
#   we don't check for $E_LINUXAIO_REVISION in deciding whether the current version is
#   revision 38 or older.
if [[ $_LINUXAIO_REVISION ]] && ((_LINUXAIO_REVISION <= 38)); then
    curl -O "$_RAW_URL/linuxAIO" || {
        E_STDERR "Failed to download 'linuxAIO'"
        revert
    }
    chmod +x linuxAIO

    echo "${E_NOTE}Existing configurations will NOT be applied to 'linuxAIO'"
    echo "${E_SUCCESS}Successfully downloaded the newest version of 'linuxAIO'"
## For newer revisions, perform extra checks, then apply existing configurations where
## possible.
elif (( E_LINUXAIO_REVISION != E_CURRENT_LINUXAIO_REVISION )); then
    echo "${E_INFO}Performing additional revision checks..."

    (( E_LINUXAIO_REVISION <= 45 )) && revision_45

    download_and_transfer

    echo "${E_SUCCESS}Successfully downloaded the newest version of 'linuxAIO' with" \
        "existing configurations applied"
    echo "${E_IMP}Review the 'linuxAIO.old' file for configurations that were" \
        "not automatically transferred to the new 'linuxAIO'"
else
    echo "${E_SUCCESS}You are already using the latest version of 'linuxAIO'"
fi
