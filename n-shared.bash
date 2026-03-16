#!/bin/bash
#
# NadekoBot Manager — Shared Helpers
#
# Shared helper functions for Manager scripts.
#
############################################################################################
####[ Functions ]###########################################################################


####
# Normalize common manager child-script exit behavior so callers can preserve their own
# output and cleanup order.
#
# PARAMETERS:
#   - $1: exit_code (Required)
#   - $2: allowed_codes (Optional, Default: "")
#       - Space-separated list of exit codes that should still return to the menu.
#   - $3: exit_now (Optional, Default: false)
#       - Whether to skip prompting before exiting.
#
# NEW GLOBALS:
#   - C_MENU_EXIT_CODE: The normalized exit code.
#   - C_MENU_EXIT_NOW: Whether to skip the return-to-menu prompt.
E_PREP_MENU_EXIT() {
    local exit_code="$1"
    local allowed_codes="${2:-}"
    local exit_now="${3:-false}"

    C_MENU_EXIT_CODE="$exit_code"
    C_MENU_EXIT_NOW="$exit_now"

    case "$C_MENU_EXIT_CODE" in
        1)
            C_MENU_EXIT_CODE=50
            ;;
        130)
            echo -e "\n${E_WARN}User interrupt detected (SIGINT)"
            C_MENU_EXIT_CODE=50
            ;;
        *)
            if [[ " $allowed_codes " != *" $C_MENU_EXIT_CODE "* ]]; then
                C_MENU_EXIT_NOW=true
            fi
            ;;
    esac
}

####
# Clear traps before cleanup starts to avoid re-entering a cleanup handler while it is
# already running.
#
# PARAMETERS:
#   - $1: trap_signals (Optional, Default: "EXIT SIGINT SIGHUP SIGTERM")
E_CLEAR_MENU_TRAPS() {
    local trap_signals="${1:-EXIT SIGINT SIGHUP SIGTERM}"
    local -a trap_signal_array
    local IFS=' '

    read -r -a trap_signal_array <<< "$trap_signals"
    trap - "${trap_signal_array[@]}"
}

####
# Exit a manager child script after cleanup has already been performed.
#
# PARAMETERS:
#   - $1: prompt_message (Optional)
#
# EXITS:
#   - $C_MENU_EXIT_CODE: The normalized exit code.
E_FINISH_MENU_EXIT() {
    local prompt_message="${1:-${E_NOTE}Press [Enter] to return to the Manager menu}"

    if [[ $C_MENU_EXIT_NOW == false ]]; then
        read -rp "$prompt_message"
    fi

    exit "$C_MENU_EXIT_CODE"
}
