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
# ...
download_bridge() {
    echo "${E_INFO}Downloading latest version of 'm-bridge.bash'..."

    curl -O "$E_RAW_URL"/m-bridge.bash || {
        E_STDERR "Failed to download 'm-bridge.bash'"
        revert
    }
    chmod +x m-bridge.bash
}

####
# ....
transfer_bridge_data() {
    local manager_branch
    local manager_branch_found
    manager_branch=$(grep '^manager_branch=.*' m-bridge.bash.old)
    manager_branch_found="$?"

    echo "${E_INFO}Applying existing configurations to the new 'm-bridge.bash'..."

    [[ $manager_branch_found == 0 ]] \
        && sed -i "s/^manager_branch=.*/$manager_branch/" m-bridge.bash
}

####
# ....
revision_40() {
    echo "${E_WARN}You are using a very old version of the manager, where it's not" \
        "possible to automatically transfer configurations to the new"\
        "'m-bridge.bash'." >&2
    echo "${E_NOTE}'m-bridge.bash' has replaced 'linuxAIO'"
    echo "${E_IMP}It's highly recommended to back up your current configurations" \
        "and version of NadekoBot, then re-download NadekoBot using the newest" \
        "version of the manager."
    echo "${E_NOTE}The newest version of the manager can be found at" \
        "https://github.com/StrangeRanger/NadekoBot-BashScript/blob/main/m-bridge.bash"
    exit 1
}

####
# Performs additional checks and modifications for 'm-bridge.bash' revision 45 and earlier,
# ensuring compatibility with updated structures.
#
# RETURNS:
#   - 0: If the function completes successfully or no actions are required.
revision_45() {
    local additional_changes=false
    [[ -f $E_BOT_DIR/$E_CREDS_EXAMPLE && -f $E_BOT_DIR/NadekoBot.dll ]] \
        && return 0

    if [[ -d "$E_BOT_DIR" ]]; then
        additional_changes=true
        echo "${E_WARN}The new version of 'linuxAIO', now called 'm-bridge.bash', has" \
            "several breaking changes since revision 45 and earlier. They will be handled" \
            "automatically."
        read -rp "${E_NOTE}Press [Enter] to continue"

        echo "${E_INFO}Renaming '$E_BOT_DIR' to '$E_BOT_DIR.rev45.bak'..."
        mv "$E_BOT_DIR" "$E_BOT_DIR.rev45.bak"

        echo "${E_INFO}Copying '$E_BOT_DIR.rev45.bak/output' to '$E_BOT_DIR'..."
        cp -r "$E_BOT_DIR.rev45.bak/output" "$E_BOT_DIR"

        echo "${E_IMP}It is highly recommended to downloaded the newest version of" \
            "NadekoBot before continuing."
    fi

    revision_47.5 "$additional_changes"
}

####
#
revision_47.5() {
    local additional_changes="${1:-false}"

    if [[ $additional_changes == true ]]; then
        echo "${E_NOTE}There are several additional changes that must be made to" \
            "'m-bridge.bash'"
    else
        echo "${E_NOTE}There are several changes that must be made to 'm-bridge.bash'"
    fi

    read -rp "${E_NOTE}Press 'Enter' to continue"

    echo "${E_INFO}Updating variables in 'm-bridge.bash.old'..."
    sed -i \
        -e 's/installer_repo/manager_repo/g' \
        -e 's/installer_branch/manager_branch/g' \
        -e 's/E_LINUXAIO_REVISION/E_BRIDGE_REVISION/g' \
        -e 's/E_BRIDGE_REVISION/E_BRIDGE_REVISION/g' \
        -e 's/C_CURRENT_LINUXAIO_REVISION/C_LATEST_BRIDGE_REVISION/g' \
        "m-bridge.bash.old" \
        || E_STDERR "Failed to update variables in 'm-bridge.bash'" "1"
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

echo "${E_INFO}Performing revision checks..."
if (( E_LINUXAIO_REVISION <= 40 )); then
    # Will exit script after the function call.
    revision_40
elif [[ $E_LINUXAIO_REVISION -le 47 && $E_CURRENT_LINUXAIO_REVISION == 47.5 ]]; then
    download_bridge

    if (( E_LINUXAIO_REVISION <= 45 )); then
        revision_45
    else
        revision_47.5
    fi

    transfer_bridge_data
elif (( E_BRIDGE_REVISION != C_LATEST_BRIDGE_REVISION )); then
    download_bridge
    transfer_bridge_data
else
    echo "${E_SUCCESS}You are already using the latest version of 'm-bridge.bash'"
    exit 0
fi

echo "${E_SUCCESS}Successfully downloaded the newest version of 'm-bridge.bash' with" \
    "existing configurations applied"
echo "${E_IMP}Review the 'm-bridge.bash.old' file for configurations that were not" \
    "automatically transferred to the new 'm-bridge.bash'"
