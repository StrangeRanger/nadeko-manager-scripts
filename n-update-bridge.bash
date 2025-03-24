#!/bin/bash
#
# m-bridge.bash Update and Configuration Migration Script
#
# This script automates the update process for 'm-bridge.bash'. It checks for a newer
# version of the script (or its legacy counterpart 'linuxAIO'), backs up the current version
# by renaming it to 'm-bridge.bash.old', and then downloads and installs the latest version.
# Additionally, it transfers existing configuration settings (such as manager branch and
# prerequisite checks) from the old version to the new one.
#
############################################################################################
####[ Functions ]###########################################################################


####
# Reverts changes made to 'm-bridge.bash' if the script is interrupted or fails.
#
# EXITS:
#   - 1: Terminates the script immediately.
revert() {
    exit_code="$1"

    if [[ -f m-bridge.bash.old && ! -f m-bridge.bash ]]; then
        echo ""
        echo -n "${E_INFO}Restoring the previous version of 'm-bridge.bash'..."
        mv m-bridge.bash.old m-bridge.bash
        chmod +x m-bridge.bash
    fi

    exit "$exit_code"
}

####
# Downloads the latest 'm-bridge.bash' from $E_RAW_URL and makes it executable.
download_bridge() {
    echo "${E_INFO}Downloading latest version of 'm-bridge.bash'..."
    curl -O "$E_RAW_URL"/m-bridge.bash || {
        E_STDERR "Failed to download 'm-bridge.bash'"
        revert "1"
    }
    chmod +x m-bridge.bash
}

####
# Transfers configuration settings from the old 'm-bridge.bash' to the new version.
transfer_bridge_data() {
    local manager_branch
    local manager_branch_found
    manager_branch=$(grep '^manager_branch=.*' m-bridge.bash.old)
    manager_branch_found="$?"
    local skip_prereq_check
    local skip_prereq_check_found
    skip_prereq_check=$(grep '^export E_SKIP_PREREQ_CHECK=.*' m-bridge.bash.old)
    skip_prereq_check_found="$?"

    echo "${E_INFO}Applying existing configurations to the new 'm-bridge.bash'..."

    if (( manager_branch_found == 0 )); then
        sed -i "s/^manager_branch=.*/$manager_branch/" m-bridge.bash
    else
        echo "${E_WARN}Failed to find 'manager_branch' in 'm-bridge.bash.old'"
    fi

    if (( skip_prereq_check_found == 0 )); then
        sed -i "s/^export E_SKIP_PREREQ_CHECK=.*/$skip_prereq_check/" m-bridge.bash
    else
        echo "${E_WARN}Failed to find 'E_SKIP_PREREQ_CHECK' in 'm-bridge.bash.old'"
    fi
}

####
# Notifies the user that the current Manager version (revision 40 or earlier) is very
# outdated and does not support the automatic transfer of configurations to the new
# 'm-bridge.bash'.
#
# EXITS:
#   - 1: Terminates the script after displaying the notification.
revision_40() {
    echo "${E_WARN}You are using a very old version of the Manager, where it's not" \
        "possible to automatically transfer configurations to the new 'm-bridge.bash'." >&2
    echo "${E_NOTE}'m-bridge.bash' has replaced 'linuxAIO'"
    echo "${E_IMP}It's highly recommended to back up your current configurations and" \
        "of NadekoBot, then re-download NadekoBot using the newest version of the Manager."
    echo "${E_NOTE}The newest version of the Manager can be found at" \
        "https://github.com/StrangeRanger/nadeko-manager-scripts/blob/main/m-bridge.bash"
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
    [[ -f $E_BOT_DIR/$E_CREDS_EXAMPLE && -f $E_BOT_DIR/NadekoBot.dll ]] && return 0

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

        echo "${E_IMP}It is highly recommended to download the newest version of" \
            "NadekoBot before continuing."
    fi

    revision_47.5 "$additional_changes"
}

####
# Updates variable names in 'm-bridge.bash.old' to match the new naming conventions.
#
# PARAMETERS:
#   - $1: additional_changes (Optional, Default: false)
#       - Indicates whether additional changes are required.
#       - Accepted values: true, false.
#
# EXITS:
#   - 1: If the function fails to update the variables in 'm-bridge.bash'.
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

####
#
revision_53() {
    cat <<EOF
${E_WARN}NadekoBot v6 Upgrade Preparation ${E_YELLOW}<==${E_NC}
  ${E_YELLOW}|${E_NC}  You are about to download the latest version of 'm-bridge.bash', which only supports NadekoBot v6.
  ${E_YELLOW}|${E_NC}  If you'd like to continue using NadekoBot v5, modify the value of 'manager_branch' in 'm-bridge.bash' to 'NadekoV5'.
  ${E_YELLOW}|${E_NC}  If you would like to upgrade to NadekoBot v6, type 'yes' EXACTLY as shown below.
  ${E_YELLOW}|${E_NC}  Please note, by typing 'yes', you are not actually upgrading to NadekoBot v6. This is only the preparation step.
  ${E_YELLOW}|${E_NC}  To complete the upgrade, you will need to download the latest version of NadekoBot using the Manager.
${E_WARN}NadekoBot v6 Upgrade Preparation ${E_YELLOW}<==${E_NC}
EOF
    read -rp "${E_NOTE}Would you like to continue? [yes/N] " answer

    answer=${answer,,}
    if [[ $answer != "yes" ]]; then
        echo "${E_WARN}NadekoBot v6 upgrade aborted"
        revert "0"
    fi

    echo "${E_INFO}Backing up current version of NadekoBot as '$E_BOT_DIR.v5.bak'..."
    cp -r "$E_BOT_DIR" "$E_BOT_DIR.v5.bak"

    echo "${E_INFO}Moving 'strings' and 'aliases' to '$E_BOT_DIR'..."
    mv "$E_BOT_DIR/data/strings" "$E_BOT_DIR/strings"
    mv "$E_BOT_DIR/data/aliases.yml" "$E_BOT_DIR/strings"

    echo "${E_INFO}Moving 'creds.yml' to '$E_BOT_DIR/data'..."
    mv "$E_BOT_DIR/creds.yml" "$E_BOT_DIR/data/creds.yml"

    echo "${E_INFO}Removing old files..."
    rm -rf "$E_BOT_DIR/data/strings.old" 2>/dev/null
    rm -rf "$E_BOT_DIR/data/aliases.old.yml" 2>/dev/null
    rm -rf "$E_BOT_DIR/data/last_known_version.txt" 2>/dev/null

    download_bridge
    transfer_bridge_data
    echo "${E_IMP}Ensure you execute option 1 in the Manager menu to download v6 of NadekoBot"
    exit 0
}


####[ Trapping Logic ]######################################################################


trap 'revert "130"' SIGINT


####[ Main ]################################################################################


printf "%s" "$E_CLR_LN"  # Clear the "Downloading 'm-bridge.bash'..." message.
read -rp "${E_NOTE}Press [Enter] to download the latest version"

if [[ -f m-bridge.bash.old ]]; then
    echo "${E_INFO}Removing existing 'm-bridge.bash.old'..."
    rm m-bridge.bash.old
fi

if [[ -f linuxAIO ]]; then  # Used in revisions 40 to 47.5.
    [[ -f linuxAIO.old ]] && rm linuxAIO.old
    echo "${E_INFO}Backing up 'linuxAIO' as 'm-bridge.bash.old'..."
    mv linuxAIO m-bridge.bash.old
elif [[ -f m-bridge.bash ]]; then
    echo "${E_INFO}Backing up 'm-bridge.bash' as 'm-bridge.bash.old'..."
    mv m-bridge.bash m-bridge.bash.old
fi

chmod -x m-bridge.bash.old

echo "${E_INFO}Performing revision checks..."
if [[ -n $E_LINUXAIO_REVISION ]] && (( E_LINUXAIO_REVISION <= 40 )); then
    revision_40  # Will exit script after the function call.
elif [[ $E_LINUXAIO_REVISION -le 47 && $E_CURRENT_LINUXAIO_REVISION == 47.5 ]]; then
    download_bridge

    if (( E_LINUXAIO_REVISION <= 45 )); then
        revision_45
    else
        revision_47.5
    fi

    transfer_bridge_data
elif (( E_BRIDGE_REVISION <= 53 )); then
    revision_53
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
