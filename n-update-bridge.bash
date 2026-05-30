#!/bin/bash
#
# NadekoBot Manager — m-bridge.bash Update and Configuration Migration Script
#
# This script automates the update process for 'm-bridge.bash'. It checks for a newer
# version of the script, backs up the current version by renaming it to 'm-bridge.bash.old',
# and then downloads and installs the latest version. Additionally, it transfers existing
# configuration settings (such as manager branch and prerequisite checks) from the old
# version to the new one.
#
############################################################################################
####[ Functions ]###########################################################################


####
# Revert changes made to 'm-bridge.bash' if the script is interrupted or fails.
#
# PARAMETERS:
#   - $1: exit_code (Required)
revert() {
    exit_code="$1"

    if [[ -f m-bridge.bash.old && ! -f m-bridge.bash ]]; then
        echo ""
        echo -n "${E_INFO}Restoring the previous version of 'm-bridge.bash'..."
        mv m-bridge.bash.old m-bridge.bash \
            || E_STDERR "Failed to restore 'm-bridge.bash'" "1"
        chmod +x m-bridge.bash
    fi

    exit "$exit_code"
}

####
# Download the latest 'm-bridge.bash' from $E_RAW_URL and make it executable.
download_bridge() {
    echo "${E_INFO}Downloading latest version of 'm-bridge.bash'..."
    curl -O "$E_RAW_URL"/m-bridge.bash || {
        E_STDERR "Failed to download 'm-bridge.bash'"
        revert "1"
    }
    chmod +x m-bridge.bash
}

####
# Transfer configuration settings from the old 'm-bridge.bash' to the new version.
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
        echo "${E_WARN}Failed to find 'manager_branch' in 'm-bridge.bash.old'" >&2
    fi

    if (( skip_prereq_check_found == 0 )); then
        sed -i "s/^export E_SKIP_PREREQ_CHECK=.*/$skip_prereq_check/" m-bridge.bash
    else
        echo "${E_WARN}Failed to find 'E_SKIP_PREREQ_CHECK' in 'm-bridge.bash.old'" >&2
    fi
}

####
# Determine whether the bridge is too old for automatic migration.
#
# RETURNS:
#   - 0: Manual update is required.
#   - 1: Automatic migration can proceed.
requires_manual_update() {
    [[ -n ${E_LINUXAIO_REVISION:-} ]] && return 0
    [[ -z ${E_BRIDGE_REVISION:-} ]] && return 0
    (( E_BRIDGE_REVISION < 48 )) && return 0
    return 1
}

####
# Notify the user that their bridge is too old for automatic migration and provide
# instructions for manual updating.
#
# EXITS:
#   - 1: Exits to allow user to perform the manual update.
manual_update_required() {
    echo "${E_WARN}This Manager version is too old to update automatically." >&2

    if [[ -n ${E_LINUXAIO_REVISION:-} ]]; then
        echo "${E_NOTE}Detected legacy 'linuxAIO' revision '$E_LINUXAIO_REVISION'"
    elif [[ -n ${E_BRIDGE_REVISION:-} ]]; then
        echo "${E_NOTE}Detected 'm-bridge.bash' revision '$E_BRIDGE_REVISION'"
    else
        E_STDERR "INTERNAL: Unable to determine the current 'm-bridge.bash' revision" "1"
    fi

    echo "${E_IMP}Back up your current configuration, then manually download the newest" \
        "'m-bridge.bash'"
    echo "${E_NOTE}The newest version can be found at" \
        "https://github.com/StrangeRanger/nadeko-manager-scripts/blob/main/m-bridge.bash"
    echo "${E_NOTE}After downloading it, reapply any settings you still need from your" \
        "old bridge script"
    exit 1
}

####
# Prepare the system for upgrading to NadekoBot v7 by moving files and directories to their
# new locations. Where necessary, remove appropriate files and directories.
revision_53() {
    cat << EOF
${E_WARN}NadekoBot v7 Upgrade Preparation ${E_YELLOW}<==${E_NC}
  ${E_YELLOW}|${E_NC}  You are about to download the latest version of 'm-bridge.bash', which only supports NadekoBot v7.
  ${E_YELLOW}|${E_NC}  If you'd like to continue using NadekoBot v5, modify the value of 'manager_branch' in 'm-bridge.bash' to 'NadekoV5'.
  ${E_YELLOW}|${E_NC}  If you would like to upgrade to NadekoBot v7, type 'yes' EXACTLY as shown below.
  ${E_YELLOW}|${E_NC}  Please note, by typing 'yes', you are not actually upgrading to NadekoBot v7. This is only the preparation step.
  ${E_YELLOW}|${E_NC}  To complete the upgrade, you will need to download the latest version of NadekoBot using the Manager menu.
${E_WARN}NadekoBot v7 Upgrade Preparation ${E_YELLOW}<==${E_NC}
EOF
    read -rp "${E_NOTE}Would you like to continue? [yes/N] " answer

    answer=${answer,,}
    if [[ $answer != "yes" ]]; then
        echo "${E_WARN}NadekoBot v7 upgrade aborted" >&2
        revert "0"
    fi

    ## TODO: Improve error handling...
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
    echo "${E_IMP}Ensure you execute option 1 in the Manager menu to download v7 of NadekoBot"
    exit 0
}


####[ Trapping Logic ]######################################################################


trap 'revert "130"' SIGINT


####[ Main ]################################################################################


printf "%s" "$E_CLR_LN"  # Clear the "Downloading 'm-bridge.bash'..." message.

if requires_manual_update; then
    manual_update_required
fi

if [[ -z ${E_LATEST_BRIDGE_REVISION:-} ]]; then
    E_STDERR "Unable to determine the latest 'm-bridge.bash' revision" "1"
fi

if (( E_BRIDGE_REVISION == E_LATEST_BRIDGE_REVISION )); then
    echo "${E_SUCCESS}You are already using the latest version of 'm-bridge.bash'"
    exit 0
fi

read -rp "${E_NOTE}Press [Enter] to download the latest version"

if [[ -f m-bridge.bash.old ]]; then
    echo "${E_INFO}Removing existing 'm-bridge.bash.old'..."
    rm m-bridge.bash.old
fi

if [[ -f m-bridge.bash ]]; then
    echo "${E_INFO}Backing up 'm-bridge.bash' as 'm-bridge.bash.old'..."
    mv m-bridge.bash m-bridge.bash.old
fi

[[ -f m-bridge.bash.old ]] && chmod -x m-bridge.bash.old

echo "${E_INFO}Performing revision checks..."
if (( E_BRIDGE_REVISION <= 53 )); then
    revision_53
elif (( E_BRIDGE_REVISION != E_LATEST_BRIDGE_REVISION )); then
    download_bridge
    transfer_bridge_data
fi

echo "${E_SUCCESS}Successfully downloaded the newest version of 'm-bridge.bash' with" \
    "existing configurations applied"
echo "${E_IMP}Review the 'm-bridge.bash.old' file for configurations that were not" \
    "automatically transferred to the new 'm-bridge.bash'"
