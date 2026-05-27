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
#   - $1: raw_exit_code (Required)
#   - $2: allowed_codes (Optional, Default: "")
#      - A space-separated list of exit codes that should still return to the menu.
#   - $3: skip_return_prompt (Optional, Default: false)
#      - Whether to skip prompting before exiting.
#
# NEW GLOBALS:
#   - C_MENU_EXIT_CODE: The normalized exit code.
#   - C_SKIP_RETURN_PROMPT: Whether to skip the return-to-menu prompt.
E_PREP_MENU_EXIT() {
    local raw_exit_code="$1"
    local menu_return_codes="${2:-}"
    local skip_return_prompt="${3:-false}"

    C_MENU_EXIT_CODE="$raw_exit_code"
    C_SKIP_RETURN_PROMPT="$skip_return_prompt"

    case "$C_MENU_EXIT_CODE" in
        1)
            C_MENU_EXIT_CODE=50
            ;;
        130)
            echo -e "\n${E_WARN}User interrupt detected (SIGINT)"
            C_MENU_EXIT_CODE=50
            ;;
        *)
            if [[ " $menu_return_codes " != *" $C_MENU_EXIT_CODE "* ]]; then
                C_SKIP_RETURN_PROMPT=true
            fi
            ;;
    esac
}

####
# Clear traps before cleanup starts to avoid re-entering a cleanup handler while it is
# already running.
E_CLEAR_MENU_TRAPS() {
    local trap_signals="${1:-EXIT SIGINT SIGHUP SIGTERM}"
    local -a trap_signal_array
    local IFS=' '

    read -r -a trap_signal_array <<< "$trap_signals"
    trap - "${trap_signal_array[@]}"
}

####
# Exit a manager child script after cleanup has already been performed.
E_FINISH_MENU_EXIT() {
    local prompt_message="${1:-${E_NOTE}Press [Enter] to return to the Manager menu}"

    if [[ -z ${C_MENU_EXIT_CODE:-} ]]; then
        echo "${C_ERROR}INTERNAL: C_MENU_EXIT_CODE is not set. Defaulting to 0." >&2
        C_MENU_EXIT_CODE=0
    fi

    if [[ ${C_SKIP_RETURN_PROMPT:-false} == false ]]; then
        read -rp "$prompt_message"
    fi

    exit "$C_MENU_EXIT_CODE"
}
