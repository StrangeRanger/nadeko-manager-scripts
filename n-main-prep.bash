#!/bin/bash
#
# NadekoBot Manager Pre-Preparation Script
#
# This script sets up the environment for the NadekoBot Manager by verifying system
# compatibility and initializing global variables and functions required by the Manager.
# It performs several key tasks:
#   - Detects the system's architecture (e.g., x64, arm64) to ensure only supported
#     64-bit systems are used.
#   - Defines ANSI escape sequences and message prefixes for consistent, colorized
#     terminal output.
#   - Exports essential environment variables (such as directories and script names)
#     used by the Manager and its sub-scripts.
#   - Implements functions for cleanup, error handling, and remote script downloading.
#   - Checks if the current m-bridge revision is up-to-date; if not, it updates the
#     bridge script.
#   - Verifies that systemd is installed and running, a prerequisite for managing
#     NadekoBot services.
#   - Finally, it executes the main Manager script (n-main.bash) once all preconditions
#     are met.
#
########################################################################################
####[ Exported and Global Variables ]###################################################


# See the 'README' note at the beginning of 'm-bridge.bash' for details.
readonly C_LATEST_BRIDGE_REVISION=50
readonly C_MAIN_MANAGER="n-main.bash"

## Define ANSI escape sequences for colored terminal output.
E_YELLOW="$(printf '\033[1;33m')"
E_GREEN="$(printf '\033[0;32m')"
E_BLUE="$(printf '\033[0;34m')"
E_CYAN="$(printf '\033[0;36m')"
E_RED="$(printf '\033[1;31m')"
E_NC="$(printf '\033[0m')"
E_GREY="$(printf '\033[0;90m')"
E_CLR_LN="$(printf '\r\033[K')"
export E_YELLOW E_GREEN E_BLUE E_CYAN E_RED E_NC E_GREY E_CLR_LN

## Define shorthand colorized message prefixes for terminal output.
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
### Variables requiring extra checks before being set and exported.
###

## Define the system's architecture and bit type (32 or 64).
case $(uname -m) in
    x86_64)  BITS="64"; export E_ARCH="x64" ;;
    aarch64) BITS="64"; export E_ARCH="arm64" ;;
    armv8l)  BITS="32"; export E_ARCH="arm32" ;;  # ARMv8 in 32-bit mode.
    armv*)   BITS="32"; export E_ARCH="arm32" ;;  # Generic ARM 32-bit.
    i*86)    BITS="32"; export E_ARCH="x86" ;;
    *)       BITS="?";  export E_ARCH="unknown" ;;
esac


####[ Functions ]#######################################################################


####
# Cleanly exit the Manager by performing cleanup tasks and then terminating the script.
# The function performs the following actions:
#   1. Removes temporary Manager files created during the installation process.
#   2. Displays an exit message based on the provided exit code.
#   3. Changes directory back to the root directory and exits with the specified status
#      code.
#
# PARAMETERS:
#   - $1: exit_code (Required)
#       - The exit status code with which the script should terminate.
#   - $2: use_extra_newline (Optional, Default: false)
#       - If "true", outputs an extra blank line to distinguish previous output from the
#         exit messages.
#       - Acceptable values: true, false.
#
# EXITS:
#   - $exit_code: The exit code passed by the caller.
clean_exit() {
    local exit_code="$1"
    local use_extra_newline="${2:-false}"
    # List of temporary Manager files to remove during cleanup.
    local manager_files=("n-main-prep.bash" "n-main.bash" "n-update.bash"
        "n-runner.bash" "n-file-backup.bash" "n-prereqs.bash" "n-update-bridge.bash")

    trap - EXIT
    [[ $use_extra_newline == true ]] && echo ""

    ## Handle signals for SIGHUP, SIGINT, and SIGTERM.
    ## Although these signals are processed in 'n-main.bash', they are handled here as
    ## well because they do not propagate to the parent script.
    case "$exit_code" in
        0|1) echo "" ;;
        129) echo -e "\n${E_WARN}Hangup signal detected (SIGHUP)" ;;
        130) echo -e "\n${E_WARN}User interrupt detected (SIGINT)" ;;
        143) echo -e "\n${E_WARN}Termination signal detected (SIGTERM)" ;;
        *)   echo -e "\n${E_WARN}Exiting with status code: $exit_code" ;;
    esac

    echo "${E_INFO}Cleaning up..."
    cd "$E_ROOT_DIR" || E_STDERR "Failed to move working directory to '$E_ROOT_DIR'" "1"

    for file in "${manager_files[@]}"; do
        [[ -f $file ]] && rm "$file"
    done

    echo "${E_INFO}Exiting..."
    exit "$exit_code"
}

####
# Downloads and executes the main Manager script, then exits with its exit code.
#
# EXITS:
#   - $?: The exit code returned by the main Manager script.
execute_main_script() {
    E_DOWNLOAD_SCRIPT "$C_MAIN_MANAGER" "true"
    ./"$C_MAIN_MANAGER"
    clean_exit "$?"
}

###
### [ Functions to be Exported ]
###

####
# Downloads the specified script from the remote location defined by $E_RAW_URL and
# grants it executable permissions. Optionally, it displays a message indicating that
# the download is in progress.
#
# PARAMETERS:
#   - $1: script_name (Required)
#   - $2: script_output (Optional, Default: false)
#       - If "true", prints a message indicating that the download is underway.
#       - Acceptable values: true, false.
E_DOWNLOAD_SCRIPT() {
    local script_name="$1"
    local script_output="${2:-false}"

    [[ $script_output == true ]] \
        && printf "%sDownloading '%s'..." "${E_INFO}" "$script_name"

    curl -O -s "$E_RAW_URL"/"$script_name"
    chmod +x "$script_name"
}
export -f E_DOWNLOAD_SCRIPT

####
# Outputs an error message to stderr, optionally prints an additional message, and
# terminates the script if an exit code is provided.
#
# PARAMETERS:
#   - $1: error_message (Required)
#   - $2: exit_code (Optional, Default: "")
#       - If provided, the script will exit with this code.
#   - $3: additional_message (Optional, Default: "")
#       - If provided, displays this message after the main error message.
#
# EXITS:
#   - $exit_code: The exit code provided by the caller.
E_STDERR() {
    local error_message="$1"
    local exit_code="${2:-}"
    local additional_message="${3:-}"

    echo "${E_ERROR}$error_message" >&2
    [[ $additional_message ]] && echo -e "$additional_message" >&2
    [[ $exit_code ]] && exit "$exit_code"
}
export -f E_STDERR


####[ Trapping Logic ]##################################################################


trap 'clean_exit "129" "true"' SIGHUP
trap 'clean_exit "130" "true"' SIGINT
trap 'clean_exit "143" "true"' SIGTERM
trap 'clean_exit "$?" "true"' EXIT


####[ Prepping ]########################################################################


if [[ $E_BRIDGE_REVISION != "$C_LATEST_BRIDGE_REVISION" ]]; then
    export E_LATEST_BRIDGE_REVISION="$C_LATEST_BRIDGE_REVISION"

    echo "${E_WARN}You are using an older version of 'm-bridge.bash'"
    E_DOWNLOAD_SCRIPT "n-update-bridge.bash" "true"
    ./n-update-bridge.bash
    clean_exit 0
fi


####[ Main ]############################################################################


clear -x

if [[ $BITS == "32" ]]; then
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
