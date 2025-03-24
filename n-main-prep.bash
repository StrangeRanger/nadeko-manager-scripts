#!/bin/bash
#
# NadekoBot Manager Bridge Script
#
# This script acts as a bootstrapper for the NadekoBot Manager. It performs environment
# validation (ensuring a 64-bit system and systemd are present), checks for bridge updates,
# and downloads the main Manager script from a remote source. After setting up global
# variables and performing initial checks, it executes the main Manager script and ensures
# proper cleanup on exit.
#
############################################################################################
####[ Exported and Global Variables ]#######################################################


# See the 'README' note at the beginning of 'm-bridge.bash' for details.
readonly C_LATEST_BRIDGE_REVISION=53

E_YELLOW="$(printf '\033[1;33m')"
E_GREEN="$(printf '\033[0;32m')"
E_BLUE="$(printf '\033[0;34m')"
E_CYAN="$(printf '\033[0;36m')"
E_RED="$(printf '\033[1;31m')"
E_NC="$(printf '\033[0m')"
E_GREY="$(printf '\033[0;90m')"
E_CLR_LN="$(printf '\r\033[K')"
export E_YELLOW E_GREEN E_BLUE E_CYAN E_RED E_NC E_GREY E_CLR_LN

E_SUCCESS="${E_GREEN}==>${E_NC} "
E_WARN="${E_YELLOW}==>${E_NC} "
E_ERROR="${E_RED}ERROR:${E_NC} "
E_INFO="${E_BLUE}==>${E_NC} "
E_NOTE="${E_CYAN}==>${E_NC} "
E_IMP="${E_CYAN}IMPORTANT:${E_NC} "
export E_SUCCESS E_WARN E_ERROR E_INFO E_NOTE E_IMP

export E_BOT_DIR="nadekobot"
export E_ROOT_DIR="$PWD"
export E_MANAGER_PREP="$E_ROOT_DIR/n-main-prep.bash"

###
### Variables that require extra checks before being set and exported.
###

case $(uname -m) in
    x86_64)  C_BITS="64"; export E_ARCH="x64" ;;
    aarch64) C_BITS="64"; export E_ARCH="arm64" ;;
    armv8l)  C_BITS="32"; export E_ARCH="arm32" ;;  # ARMv8 in 32-bit mode.
    armv*)   C_BITS="32"; export E_ARCH="arm32" ;;  # Generic ARM 32-bit.
    i*86)    C_BITS="32"; export E_ARCH="x86" ;;
    *)       C_BITS="?";  export E_ARCH="unknown" ;;
esac


####[ Functions ]###########################################################################


####
# Cleanly exit the Manager by performing cleanup tasks and then terminating the script.
#
# PARAMETERS:
#   - $1: exit_code (Required)
#       - The exit status code with which the script should terminate.
#   - $2: use_extra_newline (Optional, Default: false)
#       - Whether to output an extra newline before the exit message.
#       - Acceptable values: true, false
#
# EXITS:
#   - $exit_code: The exit code passed by the caller.
clean_exit() {
    local exit_code="$1"
    local use_extra_newline="${2:-false}"
    local manager_files=("n-main-prep.bash" "n-main.bash" "n-update.bash" "n-runner.bash"
        "n-file-backup.bash" "n-prereqs.bash" "n-update-bridge.bash")

    trap - EXIT  # Remove the exit trap to prevent re-entry after exiting.
    [[ $use_extra_newline == true ]] && echo ""

    case "$exit_code" in
        0|1) echo "" ;;
        129) echo -e "\n${E_WARN}Hangup signal detected (SIGHUP)" ;;
        130) echo -e "\n${E_WARN}User interrupt detected (SIGINT)" ;;
        143) echo -e "\n${E_WARN}Termination signal detected (SIGTERM)" ;;
        *)   echo -e "\n${E_WARN}Exiting with status code: $exit_code" ;;
    esac

    echo "${E_INFO}Cleaning up..."
    cd "$E_ROOT_DIR" || E_STDERR "Failed to change working directory to '$E_ROOT_DIR'" "1"

    for file in "${manager_files[@]}"; do
        [[ -f $file ]] && rm "$file"
    done

    echo "${E_INFO}Exiting..."
    exit "$exit_code"
}

####
# Download and execute the main Manager script, then call 'clean_exit' with the exit code
# returned by the script.
execute_main_script() {
    E_DOWNLOAD_SCRIPT "n-main.bash" "true"
    ./n-main.bash
    clean_exit "$?"
}

###
### [ Functions to be Exported ]
###

####
# Download the specified script from the remote location defined by $E_RAW_URL and grant it
# executable permissions.
#
# PARAMETERS:
#   - $1: script_name (Required)
#   - $2: should_print (Optional, Default: false)
#       - Whether to print a message indicating that the script is being downloaded.
#       - Acceptable values: true, false.
E_DOWNLOAD_SCRIPT() {
    local script_name="$1"
    local should_print="${2:-false}"

    [[ $should_print == true ]] && printf "%sDownloading '%s'..." "${E_INFO}" "$script_name"

    curl -O -s "$E_RAW_URL"/"$script_name"
    chmod +x "$script_name"
}
export -f E_DOWNLOAD_SCRIPT

####
# Output an error message to stderr, optionally print an additional message, and terminate
# the script if an exit code is provided.
#
# PARAMETERS:
#   - $1: error_message (Required)
#   - $2: exit_code (Optional, Default: "")
#       - If provided, exit the script with this exit code.
#   - $3: additional_message (Optional, Default: "")
#       - If provided, display the given message after the main error message.
#
# EXITS:
#   - $exit_code: The exit code passed by the caller.
E_STDERR() {
    local error_message="$1"
    local exit_code="${2:-}"
    local additional_message="${3:-}"

    echo "${E_ERROR}$error_message" >&2
    [[ $additional_message ]] && echo -e "$additional_message" >&2
    [[ $exit_code ]] && exit "$exit_code"
}
export -f E_STDERR


####[ Trapping Logic ]######################################################################


trap 'clean_exit "129" "true"' SIGHUP
trap 'clean_exit "130" "true"' SIGINT
trap 'clean_exit "143" "true"' SIGTERM
trap 'clean_exit "$?" "true"' EXIT


####[ Prepping ]############################################################################


# Verify that the revision number in 'm-bridge.bash' matches the latest revision.
if [[ $E_BRIDGE_REVISION != "$C_LATEST_BRIDGE_REVISION" ]]; then
    export E_LATEST_BRIDGE_REVISION="$C_LATEST_BRIDGE_REVISION"

    echo "${E_WARN}You are using an older version of 'm-bridge.bash'"
    E_DOWNLOAD_SCRIPT "n-update-bridge.bash" "true"
    ./n-update-bridge.bash
    clean_exit 0
fi


####[ Main ]################################################################################


clear -x

if [[ $C_BITS == "32" ]]; then
    echo "${E_ERROR}Current system is 32-bit, which is not supported"
    echo "${E_NOTE}NadekoBot only supports 64-bit systems"
    exit 1
fi

if [[ $(ps -p 1 -o comm=) != "systemd" ]]; then
    echo "${E_ERROR}Systemd is not installed or running"
    echo "${E_NOTE}The Manager requires systemd to function properly"
    exit 1
fi

execute_main_script
