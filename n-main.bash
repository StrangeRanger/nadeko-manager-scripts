#!/bin/bash
#
# NadekoBot Manager Menu Script
#
# This interactive script provides a menu-driven interface for managing the NadekoBot
# service. It validates system prerequisites (e.g., Python3, ffmpeg, ccze, yt-dlp) and
# the presence of required credentials, then dynamically enables or disables menu
# options based on the current system state.
#
# The script allows you to download NadekoBot, start it (with or without auto-restart),
# stop the service, view live service logs, install prerequisites, and back up important
# files—all while handling exit conditions and errors gracefully.
#
# Comment Key:
#   - A.1.: Return to stop further code execution.
#   - B.1.: Prevent the code from running if the option is disabled.
#
########################################################################################
####[ Global Variables ]################################################################


readonly C_CREDS="creds.yml"

export E_BOT_SERVICE="nadeko.service"
export E_BOT_SERVICE_PATH="/etc/systemd/system/$E_BOT_SERVICE"
export E_BOT_EXE="NadekoBot"
export E_CREDS_EXAMPLE="creds_example.yml"
export E_CREDS_PATH="$E_BOT_DIR/$C_CREDS"
export E_LOCAL_BIN="$HOME/.local/bin"
export E_YT_DLP_PATH="$E_LOCAL_BIN/yt-dlp"


####[ Functions ]#######################################################################


####
# Evaluate the exit code passed by the caller and take appropriate action.
#
# Custom Exit Codes:
#   - 3: Signals an issue with the NadekoBot daemon service.
#   - 4: Signals an unsupported OS/distro.
#   - 5: Signals an error during finalization or backup.
#   - 50: Signals that the main Manager script should continue running.
#
# PARAMETERS:
#   - $1: exit_code (Required)
#
# RETURNS:
#   - 0: If the exit code is one of 3, 4, 5, or 50, allowing the script to continue.
#
# EXITS:
#   - $exit_code: The exit code provided by the caller.
exit_code_actions() {
    local exit_code="$1"

    case "$exit_code" in
        3|4|5|50) return 0 ;;
        129) echo -e "\n${E_WARN}Hangup signal detected (SIGHUP)" ;;
        130) ;;  # SIGINT is handled elsewhere; no message is printed here.
        143) echo -e "\n${E_WARN}Termination signal detected (SIGTERM)" ;;
    esac

    exit "$exit_code"
}

####
# Determine whether the 'token' field in the credentials file is set.
#
# NOTE:
#   This is not a comprehensive check for the validity of the token; it only verifies
#   that the token field is not empty.
#
# RETURNS:
#   - 0: If the token is set.
#   - 1: If the token is not set.
is_token_set() {
    if grep -Eq '^token: '\'\''' "$E_CREDS_PATH"; then
        return 1
    else
        return 0
    fi
}

####
# Display the reason for why a menu option is disabled based on the current system state
# and file conditions (e.g., missing prerequisites or required files).
#
# PARAMETERS:
#   - $1: menu_option (Required)
disabled_reasons() {
    local menu_option="$1"

    echo "${E_NOTE}Reason option '$menu_option' is disabled:"

    case "$menu_option" in
        1)
            echo "${E_NOTE}  One or more prerequisites are not installed"
            echo "${E_NOTE}    Use option 6 to install them all"
            echo ""
            ;;
        2|3)
            if [[ ! -d $E_BOT_DIR ]]; then
                echo "${E_NOTE}  NadekoBot could not be found"
                echo "${E_NOTE}    Use option 1 to download NadekoBot"
                echo ""
            elif [[ ! -f $E_CREDS_PATH ]]; then
                echo "${E_NOTE}  The '$C_CREDS' could not be found"
                echo "${E_NOTE}    Refer to the following guide for help:" \
                    "https://nadekobot.readthedocs.io/en/latest/creds-guide/"
                echo ""
            elif ! is_token_set; then
                echo "${E_NOTE}  The 'token' in '$C_CREDS' is not set"
                echo "${E_NOTE}    Refer to the following guide for help:" \
                    "https://nadekobot.readthedocs.io/en/latest/creds-guide/"
                echo ""
            else
                echo "${E_NOTE}  Unknown reason"
                echo ""
            fi
            ;;
        4|5)
            echo "${E_NOTE}  NadekoBot is not currently running"
            echo "${E_NOTE}    Use option 2 or 3 to start NadekoBot"
            echo ""
            ;;
        7)
            echo "${E_NOTE}  NadekoBot could not be found"
            echo "${E_NOTE}    Use option 1 to download NadekoBot"
            echo ""
            ;;
    esac
}

###
### [ Functions to be Exported ]
###

####
# Retrieve the current status of NadekoBot's service using systemctl and update the
# global variable $E_BOT_SERVICE_STATUS accordingly.
#
# NEW GLOBALS:
#   - E_BOT_SERVICE_STATUS: The current status of NadekoBot's service.
E_GET_SERVICE_STATUS() {
    E_BOT_SERVICE_STATUS=$(systemctl is-active "$E_BOT_SERVICE")
}
export -f E_GET_SERVICE_STATUS

####
# Halt NadekoBot's service if it is currently running, and optionally output a message
# indicating whether the service was stopped or is already inactive.
#
# PARAMETERS:
#   - $1: verbose (Optional, Default: false)
#       - Whether to output a message indicating the service's new or current status.
#       - Acceptable values: true, false
E_STOP_SERVICE() {
    local verbose="${1:-false}"

    if [[ $E_BOT_SERVICE_STATUS == "active" ]]; then
        echo "${E_INFO}Stopping '$E_BOT_SERVICE'..."
        sudo systemctl stop "$E_BOT_SERVICE" \
            || E_STDERR "Failed to stop '$E_BOT_SERVICE'" "" \
                "${E_NOTE}You will need to restart '$E_BOT_SERVICE' to apply any updates to NadekoBot"
        [[ $verbose == true ]] \
            && echo -e "\n${E_SUCCESS}NadekoBot has been stopped"
    else
        [[ $verbose == true ]] \
            && echo -e "\n${E_NOTE}NadekoBot is not currently running"
    fi
}
export -f E_STOP_SERVICE

####
# Display real-time logs from NadekoBot's service by following its journal entries.
E_FOLLOW_SERVICE_LOGS() {
    local journal_pid

    if command -v ccze &>/dev/null; then
        sudo journalctl --no-hostname -f -u "$E_BOT_SERVICE" | ccze -A &
        journal_pid=$!
    else
        echo "${E_WARN}The 'ccze' command is not installed; logs will not be colorized"
        sudo journalctl --no-hostname -f -u "$E_BOT_SERVICE" &
        journal_pid=$!
    fi

    read -r

    kill "$journal_pid"
    wait "$journal_pid" 2>/dev/null
}
export -f E_FOLLOW_SERVICE_LOGS

####
# Provide contextual information when displaying NadekoBot's service logs, indicating
# whether the logs are viewed from a runner script or directly from the main Manager.
#
# PARAMETERS:
#   - $1: log_type (Required)
#       - Specifies the caller context.
#       - Acceptable values:
#           - runner: Called from the runner scripts.
#           - opt_five: Called from the main Manager (this script).
#
# EXITS:
#   - 2: If an invalid parameter is provided.
E_WATCH_SERVICE_LOGS() {
    local log_type="$1"

    if [[ $log_type == "runner" ]]; then
        echo "${E_INFO}Displaying '$E_BOT_SERVICE' startup logs, live..."
    elif [[ $log_type == "opt_five" ]]; then
        echo "${E_INFO}Watching '$E_BOT_SERVICE' logs, live..."
    else
        E_STDERR "INTERNAL: Invalid parameter for 'E_WATCH_SERVICE_LOGS': $1" "2"
    fi

    echo "${E_NOTE}Press [Enter] to stop watching the logs"
    echo ""

    E_FOLLOW_SERVICE_LOGS

    if [[ $log_type == "runner" ]]; then
        echo "${E_NOTE}Please check the logs above to make sure that there aren't any" \
            "errors. If there are, resolve whatever issue is causing them."
    fi

    read -rp "${E_NOTE}Press [Enter] to return to the main menu"
}
export -f E_WATCH_SERVICE_LOGS


####[ Trapping Logic ]##################################################################


trap 'exit_code_actions "129"' SIGHUP
trap 'exit_code_actions "143"' SIGTERM


####[ Main ]############################################################################


cd "$E_ROOT_DIR" || E_STDERR "Failed to change working directory to '$E_ROOT_DIR'" "1"
printf "%sWelcome to the NadekoBot Manager menu\n\n" "$E_CLR_LN"

while true; do
    ###
    ### [ Temporary Variables ]
    ###
    ### These variables are modified within the while loop and must be reset each time
    ### the loop begins.
    ###

    ## Disabled option text.
    disabled_option_message=" (Execute option to display the reason it's disabled)"
    disabled_service_message=" (Disabled until NadekoBot is running)"
    ## Option 1.
    option_one_disabled=false
    option_one_text="1. Download NadekoBot"
    ## Options 2 and 3.
    options_two_three_disabled=false
    option_two_text="2. Run NadekoBot in the background"
    option_three_text="3. Run NadekoBot in the background with auto restart"
    ## Option 4.
    option_four_disabled=false
    option_four_text="4. Stop NadekoBot"
    ## Option 5.
    option_five_disabled=false
    option_five_text="5. Display '$E_BOT_SERVICE' logs in follow mode"
    ## Option 7.
    option_seven_disabled=false
    option_seven_text="7. Back up important files"

    ###
    ### [ Variable Checks ]
    ###
    ### These checks reassess the status or existence of certain services or programs
    ### (e.g., ccze, yt_dlp) each time the loop restarts, as their availability might
    ### change.
    ###

    if [[ -f "$E_YT_DLP_PATH" ]] || command -v yt-dlp &>/dev/null; then
        yt_dlp_installed=true
    else
        yt_dlp_installed=false
    fi

    E_GET_SERVICE_STATUS

    ###
    ### [ Main Continued ]
    ###

    ## Disable option 1 if any of the required tools are not installed.
    if { ! command -v python3 &>/dev/null \
        || ! command -v ffmpeg &>/dev/null \
        || [[ $yt_dlp_installed == false ]]; } \
        && [[ $E_SKIP_PREREQ_CHECK == false ]]
    then
        option_one_disabled=true
        option_one_text="${E_GREY}${option_one_text}${disabled_option_message}${E_NC}"
    fi

    ## Disable options 2, 3, 4, and 5 if any of the required tools are missing, the
    ## required directories/files do not exist, or NadekoBot's credentials token is not
    ## set.
    if [[ $option_one_disabled == true || ! -f $E_CREDS_PATH ]] || ! is_token_set; then
        options_two_three_disabled=true
        option_two_text="${E_GREY}${option_two_text}${disabled_option_message}${E_NC}"
        option_three_text="${E_GREY}${option_three_text}${disabled_option_message}${E_NC}"
        option_four_disabled=true
        option_four_text="${E_GREY}${option_four_text}${disabled_service_message}${E_NC}"
        option_five_disabled=true
        option_five_text="${E_GREY}${option_five_text}${disabled_service_message}${E_NC}"

        ## Disable option 7 if the NadekoBot directory is missing.
        if [[ ! -d $E_BOT_DIR ]]; then
            option_seven_disabled=true
            option_seven_text="${E_GREY}${option_seven_text}${disabled_option_message}${E_NC}"
        fi
    ## If 'NadekoRun' exists, options 2 and 3 remain enabled.
    elif [[ -f NadekoRun ]]; then
        ## If NadekoBot's service is running, options 4 and 5 remain enabled; otherwise,
        ## disable them.
        if [[ $E_BOT_SERVICE_STATUS == "active" ]]; then
            run_mode_status=" ${E_GREEN}(Running in this mode)${E_NC}"
        elif [[ $E_BOT_SERVICE_STATUS == "inactive" ]]; then
            option_four_disabled=true
            option_four_text="${E_GREY}${option_four_text}${disabled_service_message}${E_NC}"
            option_five_disabled=true
            option_five_text="${E_GREY}${option_five_text}${disabled_service_message}${E_NC}"
            run_mode_status=" ${E_YELLOW}(Set up to run in this mode)${E_NC}"
        else
            option_four_disabled=true
            option_four_text="${E_GREY}${option_four_text}${disabled_service_message}${E_NC}"
            option_five_disabled=true
            option_five_text="${E_GREY}${option_five_text}${disabled_service_message}${E_NC}"
            run_mode_status=" ${E_YELLOW}(Status unknown)${E_NC}"
        fi

        ## Set the status text for the run mode.
        if grep -q '_code_name_="NadekoRunAR"' NadekoRun; then
            option_three_text="${option_three_text}${run_mode_status}"
        elif grep -q '_code_name_="NadekoRun"' NadekoRun; then
            option_two_text="${option_two_text}${run_mode_status}"
        fi
    ## If 'NadekoRun' does not exist, options 2 and 3 remain enabled, but 4 and 5 are
    ## disabled.
    else
        option_four_disabled=true
        option_four_text="${E_GREY}${option_four_text}${disabled_service_message}${E_NC}"
        option_five_disabled=true
        option_five_text="${E_GREY}${option_five_text}${disabled_service_message}${E_NC}"
    fi

    echo "$option_one_text"
    echo "$option_two_text"
    echo "$option_three_text"
    echo "$option_four_text"
    echo "$option_five_text"
    echo "6. Install prerequisites"
    echo "$option_seven_text"
    echo "8. Exit"
    read -r choice
    case "$choice" in
        1)
            ## B.1.
            if [[ $option_one_disabled == true ]]; then
                clear -x
                echo "${E_ERROR}Option 1 is currently disabled" >&2
                disabled_reasons 1
                continue
            fi

            export E_BOT_SERVICE_STATUS

            E_DOWNLOAD_SCRIPT "n-update.bash" "true"
            clear -x
            ./n-update.bash || exit_code_actions "$?"
            clear -x
            ;;
        2|3)
            ## B.1.
            if [[ $options_two_three_disabled == true ]]; then
                clear -x
                echo "${E_ERROR}Option $choice is currently disabled" >&2
                disabled_reasons "$choice"
                continue
            fi

            export E_BOT_SERVICE_STATUS

            E_DOWNLOAD_SCRIPT "n-runner.bash"
            clear -x

            if [[ $choice == 2 ]]; then
                export E_RUNNER_CODENAME="NadekoRun"
                printf "%sWe will now run NadekoBot in the background. " "$E_NOTE"

            else
                export E_RUNNER_CODENAME="NadekoRunAR"
                echo -n "${E_NOTE}We will now run NadekoBot in the background" \
                    "with auto restart. "
            fi

            (
                trap 'exit 1' SIGINT
                echo ""
                read -rp "Press [Enter] to begin."
            ) || {
                echo ""
                echo -e "\n${E_WARN}User interrupt detected (SIGINT)"
                read -rp "${E_NOTE}Press [Enter] to return to the main menu"
                clear -x
                continue
            }
            ./n-runner.bash || exit_code_actions "$?"
            clear -x
            ;;
        4)
            ## B.1.
            if [[ $option_four_disabled == true ]]; then
                clear -x
                echo "${E_ERROR}Option 4 is currently disabled" >&2
                disabled_reasons 4
                continue
            fi

            clear -x
            read -rp "${E_NOTE}We will now stop NadekoBot. Press [Enter] to begin."
            E_STOP_SERVICE "true"
            read -rp "${E_NOTE}Press [Enter] to return to the main menu"
            clear -x
            ;;
        5)
            ## B.1.
            if [[ $option_five_disabled == true ]]; then
                clear -x
                echo "${E_ERROR}Option 5 is currently disabled" >&2
                disabled_reasons 5
                continue
            fi

            clear -x
            E_WATCH_SERVICE_LOGS "opt_five"
            clear -x
            ;;
        6)
            E_DOWNLOAD_SCRIPT "n-prereqs.bash"
            clear -x
            ./n-prereqs.bash || exit_code_actions "$?"
            clear -x
            ;;
        7)
            ## B.1.
            if [[ $option_seven_disabled == true ]]; then
                clear -x
                echo "${E_ERROR}Option 7 is currently disabled" >&2
                disabled_reasons 7
                continue
            fi

            E_DOWNLOAD_SCRIPT "n-file-backup.bash"
            clear -x
            ./n-file-backup.bash || exit_code_actions "$?"
            clear -x
            ;;
        8)
            exit_code_actions 0
            ;;
        *)
            clear -x
            echo "${E_ERROR}Invalid input: '$choice' is not a valid option" >&2
            echo ""
            ;;
    esac
done
