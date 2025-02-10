#!/bin/bash
#
# The main Manager script for NadekoBot. This script presents menu options and
# orchestrates the execution of additional scripts to install, run, and manage
# NadekoBot.
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
# Evaluates the exit code from executed scripts and takes the appropriate action.
#
# Custom Exit Codes:
#   - 3: Indicates an issue related to the NadekoBot daemon service.
#   - 4: Unsupported OS/distro.
#   - 5: An error occurred during finalization or backup.
#   - 50: Special code indicating that the main Manager script should continue running.
#
# PARAMETERS:
#   - $1: exit_code (Required)
#       - The exit code to evaluate.
#
# RETURNS:
#   - 0: If the exit code is one of 3, 4, 5, or 50, allowing the script to continue.
#
# EXITS:
#   - The script terminates with the provided exit code if it is not one of the above.
exit_code_actions() {
    local exit_code="$1"

    # For exit codes 3, 4, 5, or 50, continue running the main manager.
    case "$exit_code" in
        3|4|5|50) return 0 ;;
        129) echo -e "\n${E_WARN}Hangup signal detected (SIGHUP)" ;;
        130) ;;  # SIGINT is handled elsewhere; no message is printed here.
        143) echo -e "\n${E_WARN}Termination signal detected (SIGTERM)" ;;
    esac

    exit "$exit_code"
}

####
# Determines whether the 'token' field in the credentials file is set.
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
# Outputs the reason why a specified menu option is disabled based on the current system
# state and file conditions (e.g., missing prerequisites or required files).
#
# PARAMETERS:
#   - $1: option_number (Required)
#       - The numeric identifier of the disabled menu option.
disabled_reasons() {
    local option_number="$1"

    echo "${E_NOTE}Reason option '$option_number' is disabled:"

    case "$option_number" in
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
# Retrieves the current status of the NadekoBot service using systemctl and updates the
# global variable $E_BOT_SERVICE_STATUS accordingly.
#
# NEW GLOBALS:
#   - E_BOT_SERVICE_STATUS: The current status of the NadekoBot service (e.g., "active",
#     "inactive").
E_GET_SERVICE_STATUS() {
    E_BOT_SERVICE_STATUS=$(systemctl is-active "$E_BOT_SERVICE")
}
export -f E_GET_SERVICE_STATUS

####
# Halts the NadekoBot service if it is currently running, and optionally outputs a
# message indicating whether the service was stopped or is already inactive.
#
# PARAMETERS:
#   - $1: output_text (Optional, Default: false)
#       - If "true", prints messages indicating the service status.
#       - Acceptable values: true, false.
E_STOP_SERVICE() {
    local output_text="${1:-false}"

    if [[ $E_BOT_SERVICE_STATUS == "active" ]]; then
        echo "${E_INFO}Stopping '$E_BOT_SERVICE'..."
        sudo systemctl stop "$E_BOT_SERVICE" \
            || E_STDERR "Failed to stop '$E_BOT_SERVICE'" "" \
                "${E_NOTE}You will need to restart '$E_BOT_SERVICE' to apply any updates to NadekoBot"
        [[ $output_text == true ]] \
            && echo -e "\n${E_SUCCESS}NadekoBot has been stopped"
    else
        [[ $output_text == true ]] \
            && echo -e "\n${E_NOTE}NadekoBot is not currently running"
    fi
}
export -f E_STOP_SERVICE

####
# Displays real-time logs from the NadekoBot service by following its journal entries.
# The output is piped through 'ccze' to add color, and SIGINT (Ctrl+C) is trapped to
# exit gracefully.
E_FOLLOW_SERVICE_LOGS() {
    (
        trap 'echo -e "\n"; exit 130' SIGINT
        sudo journalctl --no-hostname -f -u "$E_BOT_SERVICE" | ccze -A
    )
}
export -f E_FOLLOW_SERVICE_LOGS

####
# Provides contextual information when displaying NadekoBot service logs, indicating
# whether the logs are viewed from a runner script or directly from the main Manager.
#
# PARAMETERS:
#   - $1: log_type (Required)
#       - Specifies the caller context.
#       - Acceptable values:
#           - runner: Called from one of the runner scripts.
#           - opt_five: Called from the main Manager.
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

    echo "${E_NOTE}To stop displaying the startup logs:"
    echo "${E_NOTE}  1) Press 'Ctrl' + 'C'"
    echo ""

    E_FOLLOW_SERVICE_LOGS

    if [[ $1 == "runner" ]]; then
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
printf "%sWelcome to the NadekoBot manager menu\n\n" "$E_CLR_LN"

while true; do
    ###
    ### [ Temporary Variables ]
    ###
    ### These variables are modified within the while loop and must be reset each time
    ### the loop begins again.
    ###

    ## Disabled option text.
    dis_option=" (Execute option to display the reason it's disabled)"
    dis_opt_v2=" (Disabled until NadekoBot is running)"
    ## Option 1.
    opt_one_dis=false
    opt_one_text="1. Download NadekoBot"
    ## Option 2 & 3.
    opt_two_and_three_dis=false
    opt_two_text="2. Run NadekoBot in the background"
    opt_three_text="3. Run NadekoBot in the background with auto restart"
    ## Option 4.
    opt_four_dis=false
    opt_four_text="4. Stop NadekoBot"
    ## Option 5.
    opt_five_dis=false
    opt_five_text="5. Display '$E_BOT_SERVICE' logs in follow mode"
    ## Option 7.
    opt_seven_dis=false
    opt_seven_text="7. Back up important files"

    ###
    ### [ Variable Checks ]
    ###
    ### These checks reassess the status or existence of certain services or programs
    ### (e.g., ccze, yt_dlp) each time the loop restarts, as their availability might
    ### change.
    ###

    if command -v ccze &>/dev/null; then
        ccze_installed=true
    else
        ccze_installed=false
    fi

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
        || [[ $ccze_installed == false ]] \
        || [[ $yt_dlp_installed == false ]]; } \
        && [[ $E_SKIP_PREREQ_CHECK == false ]]
    then
        opt_one_dis=true
        opt_one_text="${E_GREY}${opt_one_text}${dis_option}${E_NC}"
    fi

    ## Disable options 2, 3, 4, and 5 if any of the required tools (from the previous
    ## check) are missing, or if required directories/files (e.g., $C_CREDS) do not
    ## exist, or if the NadekoBot token is not set.
    if [[ $opt_one_dis == true || ! -f $E_CREDS_PATH ]] || ! is_token_set; then
        opt_two_and_three_dis=true
        opt_two_text="${E_GREY}${opt_two_text}${dis_option}${E_NC}"
        opt_three_text="${E_GREY}${opt_three_text}${dis_option}${E_NC}"
        opt_four_dis=true
        opt_four_text="${E_GREY}${opt_four_text}${dis_opt_v2}${E_NC}"
        opt_five_dis=true
        opt_five_text="${E_GREY}${opt_five_text}${dis_opt_v2}${E_NC}"

        ## Disable option 7 if the NadekoBot directory is missing.
        if [[ ! -d $E_BOT_DIR ]]; then
            opt_seven_dis=true
            opt_seven_text="${E_GREY}${opt_seven_text}${dis_option}${E_NC}"
        fi
    ## If NadekoRun exists, options 2 and 3 remain enabled.
    # TODO: Replace below file with an exported variable to reduce hardcoding???
    elif [[ -f NadekoRun ]]; then
        ## Keep options 4 and 5 enabled if NadekoBot's service is running; otherwise,
        ## disable them.
        if [[ $E_BOT_SERVICE_STATUS == "active" ]]; then
            run_mode_status=" ${E_GREEN}(Running in this mode)${E_NC}"
        elif [[ $E_BOT_SERVICE_STATUS == "inactive" ]]; then
            opt_four_dis=true
            opt_four_text="${E_GREY}${opt_four_text}${dis_opt_v2}${E_NC}"
            opt_five_dis=true
            opt_five_text="${E_GREY}${opt_five_text}${dis_opt_v2}${E_NC}"
            run_mode_status=" ${E_YELLOW}(Set up to run in this mode)${E_NC}"
        else
            opt_four_dis=true
            opt_four_text="${E_GREY}${opt_four_text}${dis_opt_v2}${E_NC}"
            opt_five_dis=true
            opt_five_text="${E_GREY}${opt_five_text}${dis_opt_v2}${E_NC}"
            run_mode_status=" ${E_YELLOW}(Status unknown)${E_NC}"
        fi

        ## Display status text for background-running modes (with or without auto
        ## restart).
        if grep -q '_code_name_="NadekoRunAR"' NadekoRun; then
            opt_three_text="${opt_three_text}${run_mode_status}"
        elif grep -q '_code_name_="NadekoRun"' NadekoRun; then
            opt_two_text="${opt_two_text}${run_mode_status}"
        fi
    ## If NadekoRun does not exist, options 2 and 3 remain enabled, but 4 and 5 are
    ## disabled.
    else
        opt_four_dis=true
        opt_four_text="${E_GREY}${opt_four_text}${dis_opt_v2}${E_NC}"
        opt_five_dis=true
        opt_five_text="${E_GREY}${opt_five_text}${dis_opt_v2}${E_NC}"
    fi

    echo "$opt_one_text"
    echo "$opt_two_text"
    echo "$opt_three_text"
    echo "$opt_four_text"
    echo "$opt_five_text"
    echo "6. Install prerequisites"
    echo "$opt_seven_text"
    echo "8. Exit"
    read -r choice
    case "$choice" in
        1)
            ## B.1.
            if "$opt_one_dis"; then
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
            if "$opt_two_and_three_dis"; then
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
            if "$opt_four_dis"; then
                clear -x
                echo "${E_ERROR}Option 4 is currently disabled" >&2
                disabled_reasons 4
                continue
            fi

            clear -x
            read -rp "${E_NOTE}We will now stop NadekoBot. Press [Enter] to begin."
            E_STOP_SERVICE "true"
            read -rp "${E_NOTE}Press [Enter] to return to the manager menu"
            clear -x
            ;;
        5)
            ## B.1.
            if "$opt_five_dis"; then
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
            if "$opt_seven_dis"; then
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
