#!/bin/bash
#
# This script checks the operating system, architecture, bit type, and other factors to
# confirm NadekoBot's compatibility. If the system is supported, it downloads and
# executes the main script.
#
########################################################################################
####[ Exported and Global Variables ]###################################################


# Refer to the 'README' note at the beginning of 'm-bridge.bash' for more information.
readonly C_LATEST_BRIDGE_REVISION=48
readonly C_MAIN_MANAGER="n-main.bash"

## Modify output text color.
E_YELLOW="$(printf '\033[1;33m')"
E_GREEN="$(printf '\033[0;32m')"
E_BLUE="$(printf '\033[0;34m')"
E_CYAN="$(printf '\033[0;36m')"
E_RED="$(printf '\033[1;31m')"
E_NC="$(printf '\033[0m')"
E_GREY="$(printf '\033[0;90m')"
E_CLR_LN="$(printf '\r\033[K')"
export E_YELLOW E_GREEN E_BLUE E_CYAN E_RED E_NC E_GREY E_CLR_LN

## Short-hand colorized messages.
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


####[ Functions ]#######################################################################


# TODO: Update function comments.
####
# Identify the operating system, version, architecture, bit type (32/64), etc. This
# information is then made available to this and the rest of the scripts.
#
# NEW GLOBALS:
#   - bits: Bit type
detect_sys_info() {
    case $(uname -m) in
        x86_64)  bits="64"; export E_ARCH="x64" ;;
        aarch64) bits="64"; export E_ARCH="arm64" ;;
        armv8l)  bits="32"; export E_ARCH="arm32" ;;  # ARMv8 in 32-bit mode.
        armv*)   bits="32"; export E_ARCH="arm32" ;;  # Generic ARM 32-bit.
        i*86)    bits="32"; export E_ARCH="x86" ;;
        *)       bits="?";  export E_ARCH="unknown" ;;  # Fallback to uname output.
    esac
}

####
# Cleanly exit the manager by performing the following steps:
#   1. Remove any temporary files created during the installation process.
#   2. Display an appropriate exit message based on the provided exit code.
#   3. Exit the script with the specified status code.
#
# PARAMETERS:
#   - $1: exit_code (Required)
#       - The exit status code with which the script should terminate.
#   - $2: use_extra_newline (Optional, Default: false)
#       - If set to "true", outputs an extra blank line to visually separate previous
#         output from the exit message.
#       - Acceptable values:
#           - true
#           - false
#
# EXITS:
#   - exit_code: Terminates the script with the exit code provided as $1.
clean_exit() {
    local exit_code="$1"
    local use_extra_newline="${2:-false}"
    # Files to be removed during the cleanup process.
    local manager_files=("n-main-prep.bash" "n-main.bash" "n-update.bash"
        "n-runner.bash" "n-file-backup.bash" "n-prereqs.bash" "n-update-bridge.bash")

    trap - EXIT
    [[ $use_extra_newline == true ]] && echo ""

    ## Although SIGHUP and SIGTERM output is specified in 'n-main.bash', we
    ## handle these signals here as well because they do not propagate to the parent
    ## script.
    case "$exit_code" in
        0|1) echo "" ;;
        129) echo -e "\n${E_WARN}Hangup signal detected (SIGHUP)" ;;
        130) echo -e "\n${E_WARN}User interrupt detected (SIGINT)" ;;
        143) echo -e "\n${E_WARN}Termination signal detected (SIGTERM)" ;;
        *)   echo -e "\n${E_WARN}Exiting with code: $exit_code" ;;
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
# Downloads the main manager script and executes it. This function is typically one of
# the final steps of this script. After it finishes, the script exits using the exit
# code from 'n-main.bash'.
#
# EXITS:
#   - $?: The exit code returned by 'n-main.bash'.
execute_main_script() {
    E_DOWNLOAD_SCRIPT "$C_MAIN_MANAGER" "true"
    ./"$C_MAIN_MANAGER"
    clean_exit "$?"
}

###
### [ Functions To Be Exported ]
###

####
# Downloads the specified script from the $E_RAW_URL location and grants it executable
# permissions. Optionally displays a message indicating that the download is in
# progress.
#
# PARAMETERS:
#   - $1: script_name (Required)
#       - The name of the script to download.
#   - $2: script_output (Optional, Default: false)
#       - Whether to indicate that the script is being downloaded.
#       - Acceptable values:
#           - true
#           - false
E_DOWNLOAD_SCRIPT() {
    local script_name="$1"
    local script_output="${2:-false}"

    [[ $script_output == true ]] \
        && printf "%sDownloading '%s'..." "${E_INFO}" "$script_name"

    curl -O -s "$E_RAW_URL"/"$script_name"
    sudo chmod +x "$script_name"
}
export -f E_DOWNLOAD_SCRIPT

####
# Outputs an error message to stderr, optionally prints an additional message, and
# terminates the script if an exit code is provided.
#
# PARAMETERS:
#   - $1: error_message (Required)
#       - The main error message to display.
#   - $2: exit_code (Optional, Default: "")
#       - If provided, the script will exit with this code.
#   - $3: additional_message (Optional, Default: "")
#       - If provided, displays this message after the main error message.
#
# EXITS:
#   - exit_code: If specified, the script exits with the given exit code.
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
detect_sys_info

if [[ $bits == "32" ]]; then
    echo "${E_ERROR}Current system is 32-bit, which is not supported"
    echo "${E_NOTE}NadekoBot only supports 64-bit systems"
    exit 1
fi

execute_main_script
