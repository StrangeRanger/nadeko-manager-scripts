#!/bin/bash
#
# The master/main installer for macOS and Linux Distributions.
#
# Comment key for '[letter].[number].':
#   A.1. - Return to prevent further code execution.
#   B.1. - Prevent the code from running if the option is disabled.
#
########################################################################################
#### [ OS Specific Variables and Functions ]
#### The variables and functions below are designed specifically for either macOS or
#### Linux Distribution.


if [[ $_DISTRO != "Darwin" ]]; then
    ####################################################################################
    #### [[ Used On 'Linux Distributions' ]]

    ####################################################################################
    #### [[[ Variables ]]]


    prereqs_installer="linux_prereqs_installer.sh"
    nadeko_runner="linux_nadeko_runner.sh"
    ## To be exported.
    _NADEKO_SERVICE="/etc/systemd/system/nadeko.service"
    _NADEKO_SERVICE_NAME="nadeko.service"


    #### End of [[[ Variables ]]]
    ####################################################################################
    #### [[[ Functions ]]]


    _SERVICE_ACTIONS() {
        ####
        # Function Info: Actions dealing with the status/state of the NadekoBot's
        #                service.
        #
        # Parameters:
        #   $1 - The actions to be performed (i.e. get service status or stop service).
        #   $2 - Dictates whether or not the text indicating that the service has been
        #        stopped or is not running, should be printed to the terminal.
        ####

        ## Save the status of $_NADEKO_SERVICE_NAME to $_NADEKO_SERVICE_STATUS.
        if [[ $1 = "nadeko_service_status" ]]; then
            _NADEKO_SERVICE_STATUS=$(systemctl is-active "$_NADEKO_SERVICE_NAME")
        ## Stops $_NADEKO_SERVICE_NAME if it's actively running.
        elif [[ $1 = "stop_service" ]]; then
            if [[ $_NADEKO_SERVICE_STATUS = "active" ]]; then
                echo "Stopping '$_NADEKO_SERVICE_NAME'..."
                sudo systemctl stop "$_NADEKO_SERVICE_NAME" || {
                    echo "${_RED}Failed to stop '$_NADEKO_SERVICE_NAME'" >&2
                    echo "${_CYAN}You will need to restart '$2' to apply any updates" \
                        "to NadekoBot$_NC"
                    return 1  # A.1.
                }
                if [[ $2 = true ]]; then
                    echo -e "\n${_GREEN}NadekoBot has been stopped$_NC"
                fi
            else
                if [[ $2 = true ]]; then
                    echo -e "\n${_CYAN}NadekoBot is not currently running$_NC"
                fi
            fi
        fi
    }

    _FOLLOW_SERVICE_LOGS() {
        ####
        # Function Info: Display the logs from 'nadeko.server' as they are created.
        ####

        (
            trap 'exit' SIGINT
            sudo journalctl -f -u "$_NADEKO_SERVICE_NAME"  | ccze -A
        )
    }

    hash_ccze() {
        ####
        # Function Info: Return whether or not 'ccze' is installed.
        ####

        if hash ccze &>/dev/null; then ccze_installed=true
        else                           ccze_installed=false
        fi
    }


    #### End of [[[ Functions ]]]
    ####################################################################################

    #### End of [[ Used On 'Linux Distributions' ]]
else  ##################################################################################
    #### [[ Used On 'macOS' ]]

    ####################################################################################
    #### [[[ Variables ]]]


    prereqs_installer="macos_prereqs_installer.sh"
    nadeko_runner="macos_nadeko_runner.sh"
    ## To be exported.
    _NADEKO_SERVICE="/Users/$USER/Library/LaunchAgents/bot.nadeko.Nadeko.plist"
    _NADEKO_SERVICE_NAME="bot.nadeko.Nadeko"


    #### End of [[[ Variables ]]]
    ####################################################################################
    #### [[[ Functions ]]]


    _SERVICE_ACTIONS() {
        ####
        # Function Info: Actions dealing with the status/state of the NadekoBot's
        #                service.
        #
        # Parameters:
        #   $1 - The actions to be performed (i.e. get service status or stop service).
        #   $2 - Dictates whether or not the text indicating that the service has been
        #        stopped or is not running, should be printed to the terminal.
        ####

        ## Save the status of $_NADEKO_SERVICE_NAME to $_NADEKO_SERVICE_STATUS.
        if [[ $1 = "nadeko_service_status" ]]; then
            # Make sure that $_NADEKO_SERVICE_NAME is enabled and loaded.
            launchctl enable gui/"$UID"/"$_NADEKO_SERVICE_NAME" \
                && launchctl load "$_NADEKO_SERVICE" 2>/dev/null

            _NADEKO_SERVICE_STATUS=$(launchctl print gui/"$UID"/"$_NADEKO_SERVICE_NAME" | grep "state") \
                && _NADEKO_SERVICE_STATUS=${_NADEKO_SERVICE_STATUS/[[:blank:]]state = /} \
                || _NADEKO_SERVICE_STATUS="inactive"
        ## Stop $_NADEKO_SERVICE_NAME if it's currently running.
        elif [[ $1 = "stop_service" ]]; then
            launchctl stop "$_NADEKO_SERVICE_NAME" || {
                echo "${_RED}Failed to stop '$_NADEKO_SERVICE_NAME'" >&2
                echo "${_CYAN}You will need to restart '$2' to apply any updates to" \
                    "NadekoBot$_NC"
                return 1  # A.1.
            }

            if [[ $2 = true ]]; then echo -e "\n${_GREEN}NadekoBot has been stopped$_NC"
            fi
        ## PURPOSE: Internal error protection.
        else
            echo "${_RED}INTERNAL ERROR: Bad parameter was provide (parameter: $2)$_NC" >&2
            exit 3
        fi
    }

    _FOLLOW_SERVICE_LOGS() {
        ####
        # Function Info: Display the logs from 'bot.nadeko.Nadeko' as they are created.
        ####

        (
            trap 'exit' SIGINT
            tail -f "${_NADEKO_SERVICE_NAME}.log"
        )
    }

    hash_ccze() {
        ####
        # Function Info: Always return that ccze is installed, even if it isn't, since
        #                it's never used when the installer is run on macOS.
        # Returns:       true
        ####

        ccze_installed=true
    }


    #### End of [[[ Functions ]]]
    ####################################################################################

    #### End of [[ Used On 'macOS' ]]
    ####################################################################################
fi


#### End of [ OS Specific Variables and Functions ]
########################################################################################
#### [ General Variables and Functions ]


# Store process id of 'nadeko_master_installer.sh', in case it needs to be manually
# killed by a sub/child script.
export _NADEKO_MASTER_INSTALLER_PID=$$

exit_code_actions() {
    ####
    # Function Info: Depending on the return/exit code from any of the executed scripts,
    #                perform the corresponding/appropriate actions.
    #
    # Parameters:
    #   $1 - Return/exit code.
    #
    # Code Meaning:
    #	1   - Something happened that requires the exit of the entire installer.
    #   127 - When the end-user uses 'CTRL' + 'C' or 'CTRL' + 'Z'.
    ####

    case "$1" in
        1|127) exit "$1" ;;
        *)               ;;
    esac

}

jq_checker() {
    if hash jq; then
        if [[ -z $(jq -r ".Token" NadekoBot/src/NadekoBot/credentials.json) ]]; then
            jq_check="empty"
        else
            jq_check="filled"
        fi
    else
        jq_check="empty"
    fi
}

_WATCH_SERVICE_LOGS() {
    ####
    # Function Info: Output the general information to go along with the output of the
    #                function '_FOLLOW_SERVICE_LOGS'.
    #
    # Parameters:
    #   $1 - Indicates if the function was called from one of the runner scripts or
    #        from within the master installer.
    ####

    if [[ $1 = "runner" ]]; then
        echo "Displaying '$_NADEKO_SERVICE_NAME' startup logs, live..."
    else
        echo "Watching '$_NADEKO_SERVICE_NAME' logs, live..."
    fi

    echo "${_CYAN}To stop displaying the startup logs:"
    echo "1) Press 'Ctrl' + 'C'$_NC"
    echo ""

    _FOLLOW_SERVICE_LOGS

    if [[ $1 = "runner" ]]; then
        echo -e "\n"
        echo "Please check the logs above to make sure that there aren't any" \
            "errors, and if there are, to resolve whatever issue is causing them"
    fi

    echo -e "\n"
    read -rp "Press [Enter] to return to the installer menu"
}


#### End of [ General Variables and Functions ]
########################################################################################
#### [ Main ]


echo -e "Welcome to the NadekoBot installer\n"

while true; do
    # Get the current status of $_NADEKO_SERVICE_NAME.
    # NOTE: Will return 'inactive' if the service doesn't exist and the OS is macOS.
    _SERVICE_ACTIONS "nadeko_service_status"

    # Determines if $ccze_installed is true or false.
    hash_ccze
    # Determines if $jq_check is "empty" or "filled".
    jq_checker

    ## Disable option 1 if any of the following tools are not installed.
    if (! hash dotnet \
            || ! hash redis-server \
            || ! hash git \
            || ! hash jq \
            || ! hash python3 \
            || ! hash youtube-dl \
            || [[ $ccze_installed = false ]]) &>/dev/null; then
        option_one_disabled=true
        echo "${_GREY}1. Download NadekoBot (Disabled until option 6 has been run)$_NC"
    else
        option_one_disabled=false
        echo "1. Download NadekoBot"
    fi

    ## Disable options 2, 3, 4, and 5 if any of the following tools are not installed or
    ## none of the directories/files could be found.
    if [[ ! -d NadekoBot/src/NadekoBot/ \
            || ! -f NadekoBot/src/NadekoBot/credentials.json \
            || ! -d NadekoBot/src/NadekoBot/bin/Release \
            || $jq_check = "empty" ]] \
            || ( ! hash dotnet \
                || ! hash redis-server \
                || ! hash git \
                || ! hash python3 \
                || ! hash youtube-dl \
                || [[ $ccze_installed = false ]]) &>/dev/null; then
        option_two_and_three_disabled=true
        option_four_disabled=true
        option_five_disabled=true
        stop_nadeko_service="${_GREY}4. Stop NadekoBot (Disabled until NadekoBot is running)$_NC"

        echo "${_GREY}2. Run NadekoBot in the background (Disabled until options 1, 6" \
            "and 7 has been run)"
        echo "3. Run NadekoBot in the background with auto restart (Disabled until" \
            "options 1, 6, and 7 has been run)$_NC"
    ## Enable options 2 and 3, if 'NadekoRun.sh' exists.
    elif [[ -f NadekoRun.sh ]]; then
        option_two_and_three_disabled=false

        ## Enable options 4 and 5 if NadekoBot's service is running.
        if [[ $_NADEKO_SERVICE_STATUS = "active" \
                || $_NADEKO_SERVICE_STATUS = "running" ]]; then
            option_four_disabled=false
            option_five_disabled=false
            stop_nadeko_service="4. Stop NadekoBot"
            run_mode_status=" ${_GREEN}(Running in this mode)$_NC"
        ## Disable options 4 and 5 if NadekoBot's service NOT running.
        elif [[ $_NADEKO_SERVICE_STATUS = "inactive" \
                || $_NADEKO_SERVICE_STATUS = "waiting" ]]; then
            option_four_disabled=true
            option_five_disabled=true
            stop_nadeko_service="${_GREY}4. Stop NadekoBot (Disabled until NadekoBot is running)$_NC"
            run_mode_status=" ${_YELLOW}(Set up to run in this mode)$_NC"
        ## Disable options 4 and 5.
        else
            option_four_disabled=true
            option_five_disabled=true
            stop_nadeko_service="${_GREY}4. Stop NadekoBot (Disabled until the status of NadekoBot isn't unknown)$_NC"
            run_mode_status=" ${_YELLOW}(Status unknown)$_NC"
        fi

        ## If NadekoBot is running in the background with auto restart...
        if grep -q '_code_name_="NadekoRunAR"' NadekoRun.sh; then
            echo "2. Run NadekoBot in the background"
            echo "3. Run NadekoBot in the background with auto restart${run_mode_status}"
        ## If NadekoBot is running in the background...
        elif grep -q '_code_name_="NadekoRun"' NadekoRun.sh; then
            echo "2. Run NadekoBot in the background${run_mode_status}"
            echo "3. Run NadekoBot in the background with auto restart"
        else
            echo "2. Run NadekoBot in the background"
            echo "3. Run NadekoBot in the background with auto restart"
        fi
    ## Enable options 2 and 3, but disable options 4 and 5.
    else
        option_two_and_three_disabled=false
        option_four_disabled=true
        option_five_disabled=true
        stop_nadeko_service="${_GREY}4. Stop NadekoBot (Disabled until NadekoBot is running)$_NC"
        echo "2. Run NadekoBot in the background"
        echo "3. Run NadekoBot in the background with auto restart"
    fi

    echo "$stop_nadeko_service"

    if [[ $option_five_disabled = true ]]; then
        echo "${_GREY}5. Display '$_NADEKO_SERVICE_NAME' logs in follow mode" \
            "(Disabled until NadekoBot is running)$_NC"
    else
        echo "5. Display '$_NADEKO_SERVICE_NAME' logs in follow mode"
    fi

    echo "6. Install prerequisites"

    ## Disable option 7 if NadekoBot has NOT been downloaded.
    if [[ ! -d NadekoBot/src/NadekoBot/ ]]; then
        option_seven_disabled=true
        echo "${_GREY}7. Set up 'credentials.json' (Disabled until option 1 has been" \
            "run)$_NC"
    else
        option_seven_disabled=false
        echo "7. Set up 'credentials.json'"
    fi

    echo "8. Exit"
    read -r choice
    case "$choice" in
        1)
            ## B.1.
            if [[ $option_one_disabled = true ]]; then
                clear -x
                echo "${_RED}Option 1 is currently disabled$_NC"
                continue
            fi

            export _NADEKO_SERVICE
            export -f _SERVICE_ACTIONS
            export _NADEKO_SERVICE_NAME
            export _NADEKO_SERVICE_STATUS

            _DOWNLOAD_SCRIPT "nadeko_latest_installer.sh" "nadeko_latest_installer.sh"
            clear -x
            ./nadeko_latest_installer.sh || exit_code_actions "$?"

            # Execute the newly downloaded version of 'installer_prep.sh', so that all
            # changes are applied.
            exec "$_INSTALLER_PREP"
            ;;
        2|3)
            ## B.1.
            if [[ $option_two_and_three_disabled = true ]]; then
                clear -x
                echo "${_RED}Option $choice is currently disabled$_NC"
                continue
            fi

            export _NADEKO_SERVICE
            export _NADEKO_SERVICE_NAME
            export _NADEKO_SERVICE_STATUS
            export -f _WATCH_SERVICE_LOGS
            export -f _FOLLOW_SERVICE_LOGS

            _DOWNLOAD_SCRIPT "$nadeko_runner" "nadeko_runner.sh"
            clear -x

            # If option 2 was executed...
            if [[ $choice = 2 ]]; then
                export _CODENAME="NadekoRun"
                printf "We will now run NadekoBot in the background. "
            # If option 3 was executed...
            else
                export _CODENAME="NadekoRunAR"
                printf "We will now run NadekoBot in the background with auto restart. "
            fi

            read -rp "Press [Enter] to begin."
            ./nadeko_runner.sh || exit_code_actions "$?"
            clear -x
            ;;
        4)
            clear -x
            ## B.1.
            if [[ $option_four_disabled = true ]]; then
                echo "${_RED}Option $choice is currently disabled$_NC"
                continue
            fi

            read -rp "We will now stop NadekoBot. Press [Enter] to begin."
            _SERVICE_ACTIONS "stop_service" "true"
            read -rp "Press [Enter] to return to the installer menu"
            clear -x
            ;;
        5)
            clear -x
            ## B.1.
            if [[ $option_five_disabled = true ]]; then
                echo "${_RED}Option 5 is currently disabled$_NC"
                continue
            fi

            _WATCH_SERVICE_LOGS "option_five"
            clear -x
            ;;
        6)
            _DOWNLOAD_SCRIPT "$prereqs_installer" "prereqs_installer.sh"
            clear -x
            ./prereqs_installer.sh || exit_code_actions "$?"
            clear -x
            ;;
        7)
            ## B.1.
            if [[ $option_seven_disabled = true ]]; then
                clear -x
                echo "${_RED}Option 7 is currently disabled$_NC"
                continue
            fi

            _DOWNLOAD_SCRIPT "credentials_setup.sh" "credentials_setup.sh"
            clear -x
            ./credentials_setup.sh || exit_code_actions "$?"
            clear -x
            ;;
        8)
            exit 0
            ;;
        *)
            clear -x
            echo "${_RED}Invalid input: '$choice' is not a valid option$_NC" >&2
            ;;
    esac
done


#### End of [ Main ]
########################################################################################
