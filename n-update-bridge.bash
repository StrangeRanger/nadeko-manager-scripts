#!/bin/bash
#
# This script checks for a newer release of 'm-bridge.bash' and, if available, downloads it.
# Any existing configurations from the old version are then transferred to the new one
# where possible.
#
########################################################################################
####[ Functions ]#######################################################################


####
# Reverts any changes made to 'm-bridge.bash' if this script is interrupted or fails,
# restoring the older version if it still exists.
#
# EXITS:
#   - 1: The script terminates immediately.
revert() {
    if [[ -f m-bridge.bash.old && ! -f m-bridge.bash ]]; then
        echo ""
        echo -n "${E_INFO}Restoring the previous version of 'm-bridge.bash'..."
        mv m-bridge.bash.old m-bridge.bash
        chmod +x m-bridge.bash
    fi

    exit 1
}

####
# Downloads the latest version of 'm-bridge.bash' and transfers any existing configurations
# (e.g., the manager branch) from the old version.
download_and_transfer() {
    local manager_branch
    local manager_branch_found
    manager_branch=$(grep '^manager_branch=.*' m-bridge.bash.old)
    manager_branch_found="$?"

    echo "${E_INFO}Downloading latest version of 'm-bridge.bash'..."

    curl -O "$E_RAW_URL"/m-bridge.bash || {
        E_STDERR "Failed to download 'm-bridge.bash'"
        revert
    }
    chmod +x m-bridge.bash

    echo "${E_INFO}Applying existing configurations to the new 'm-bridge.bash'..."

    [[ $manager_branch_found == 0 ]] \
        && sed -i "s/^manager_branch=.*/$manager_branch/" m-bridge.bash
}

####
#
revision_40() {
    echo "WARNING: You are using a very old version of the manager, where it's not" \
        "possible to automatically transfer configurations to the new"\
        "'m-bridge.bash'." >&2
    echo "NOTE: 'm-bridge.bash' has replaced 'linuxAIO'"
    echo "IMPORTANT: It's highly recommended to back up your current configurations" \
        "and version of NadekoBot, then re-download NadekoBot using the newest" \
        "version of the manager."
    echo "NOTE: The newest version of the manager can be found at" \
        "https://github.com/StrangeRanger/NadekoBot-BashScript/blob/main/m-bridge.bash"
    echo "Exiting..."
    exit 1
}

####
# Performs additional checks and modifications for 'm-bridge.bash' revision 45 and earlier,
# ensuring compatibility with updated structures.
#
# RETURNS:
#   - 0: If the function completes successfully or no actions are required.
revision_45() {
    [[ -f $E_BOT_DIR/$E_CREDS_EXAMPLE && -f $E_BOT_DIR/NadekoBot.dll ]] \
        && return 0

    echo "${E_WARN}The new version of 'm-bridge.bash' has several breaking changes from" \
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

####
#
revision_47.5() {
    echo "${E_NOTE}There are several changes to 'linuxAIO' that must be made before" \
        "continuing:"
    echo "  ${E_CYAN}|${E_NC}    - 'linuxAIO' will be renamed to 'm-bridge.bash'"
    echo "  ${E_CYAN}|${E_NC}    - Variables will be updated to reflect the new name"
    echo "  ${E_CYAN}|${E_NC}    - The script will be updated to the latest version"
    read -rp "${E_NOTE}Press 'Enter' to continue or 'Ctrl + C' to cancel"

    echo "${E_INFO}Backing up 'linuxAIO'..."
    cp "linuxAIO" "linuxAIO.bak" || E_STDERR "Failed to backup 'linuxAIO'" "1"

    echo "${E_INFO}Renaming 'linuxAIO' to 'm-bridge.bash'..."
    mv "linuxAIO" "m-bridge.bash" \
        || E_STDERR "Failed to rename 'linuxAIO' to 'm-bridge.bash'" "1"

    echo "${E_INFO}Updating variables in 'm-bridge.bash'..."
    sed -i \
        -e 's/installer_repo/manager_repo/g' \
        -e 's/installer_branch/manager_branch/g' \
        -e 's/E_LINUXAIO_REVISION/E_BRIDGE_REVISION/g' \
        -e 's/E_BRIDGE_REVISION/E_BRIDGE_REVISION/g' \
        -e 's/C_CURRENT_LINUXAIO_REVISION/C_LATEST_BRIDGE_REVISION/g' \
        "m-bridge.bash" || E_STDERR "Failed to update variables in 'm-bridge.bash'" "1"
}


####[ Trapping Logic ]##################################################################


trap 'revert' SIGINT


####[ Main ]############################################################################


printf "%s" "$E_CLR_LN"  # Clear the "Downloading 'm-bridge.bash'..." message.
read -rp "${E_NOTE}Press [Enter] to download the latest version"

if [[ -f m-bridge.bash.old ]]; then
    echo "${E_INFO}Removing existing 'm-bridge.bash.old'..."
    rm m-bridge.bash.old
fi

if [[ -f linuxAIO ]]; then  # Used in revisions 39 to 47.5.
    [[ -f linuxAIO.old ]] && rm linuxAIO.old
    echo "${E_INFO}Backing up 'linuxAIO' as 'm-bridge.bash.old'..."
    mv linuxAIO m-bridge.bash.old
elif [[ -f m-bridge.bash ]]; then
    echo "${E_INFO}Backing up 'm-bridge.bash' as 'm-bridge.bash.old'..."
    mv m-bridge.bash m-bridge.bash.old
fi

chmod -x m-bridge.bash.old

if (( E_LINUXAIO_REVISION <= 40 )); then
    revision_40
elif (( E_LINUXAIO_REVISION <= 45 )); then
    download_and_transfer
    revision_45
elif [[ $E_LINUXAIO_REVISION -le 47 && $E_CURRENT_LINUXAIO_REVISION == 47.5 ]]; then
    revision_47.5
    download_and_transfer
elif (( E_BRIDGE_REVISION != C_LATEST_BRIDGE_REVISION )); then
    download_and_transfer

    echo "${E_SUCCESS}Successfully downloaded the newest version of 'm-bridge.bash' with" \
        "existing configurations applied"
    echo "${E_IMP}Review the 'm-bridge.bash.old' file for configurations that were" \
        "not automatically transferred to the new 'm-bridge.bash'"
else
    echo "${E_SUCCESS}You are already using the latest version of 'm-bridge.bash'"
fi
