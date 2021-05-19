#!/bin/bash
#
# The master/main installer for macOS and Linux Distributions.
#
# COMMENT '[letter].[number].' KEY INFO:
#   A.1. - Return to prevent further code execution.
#   B.1. - Set the execution permissions for the downloaded script, then execute it.
#   C.1. - Prevent the code from running if the options is disabled.
#
########################################################################################
#### [ Variables and Functions ]
#### The variables and functions below are designed specifically for either macOS or
#### Linux distribution.


# Keeps track of this script's process id, in case it needs to be manually killed.
export _NADEKO_MASTER_INSTALLER_PID=$$


if [[ $_DISTRO != "Darwin" ]]; then
    ####################################################################################
    #### [[ Used On 'Linux Distributions' ]]
    
    ####################################################################################
    ######## [[[ Variables ]]]


    prereqs_installer="linux_prereqs_installer.sh"
    nadeko_runner="linux_nadeko_runner.sh"

    ## To be exported
    _NADEKO_SERVICE="/etc/systemd/system/nadeko.service"
    _NADEKO_SERVICE_NAME="nadeko.service"


    ######## End of [[[ Variables ]]]
    ####################################################################################
    ######## [[[ Functions ]]]


    _SERVICE_ACTIONS() {
        ####
        # FUNCTION INFO:
        #
        # Actions dealing with the status/state of the 'nadeko.service' service.
        #
        # @param $1 The actions to be performed (i.e. get service status or stop
        #           service)
        # @param $2 Dictates whether or not text indicating that the service has been
        #           stopped or is currently stopped, should be printed to the terminal.
        #
        ####

        ## Saves the status of '$_NADEKO_SERVICE_NAME' to $_NADEKO_SERVICE_STATUS.
        if [[ $1 = "nadeko_service_status" ]]; then
            _NADEKO_SERVICE_STATUS=$(systemctl is-active $_NADEKO_SERVICE_NAME)
        ## Stops '$_NADEKO_SERVICE_NAME' if it is actively running.
        elif [[ $1 = "stop_service" ]]; then
            if [[ $_NADEKO_SERVICE_STATUS = "active" ]]; then
                echo "Stopping '$_NADEKO_SERVICE_NAME'..."
                sudo systemctl stop $_NADEKO_SERVICE_NAME || {
                    echo "${_RED}Failed to stop '$_NADEKO_SERVICE_NAME'" >&2
                    echo "${_CYAN}You will need to restart '$_NADEKO_SERVICE_NAME' to" \
                        "apply any updates to NadekoBot$_NC"
                    return 1  # A.1. Return to prevent further code execution.
                }
                if [[ $2 = true ]]; then
                    echo -e "\n${_GREEN}NadekoBot has been stopped$_NC"
                fi
            else
                if [[ $2 = true ]]; then
                    echo -e "\n${_CYAN}NadekoBot is currently not running$_NC"
                fi
            fi
        fi
    }


    ######## End of [[[ Functions ]]]
    ####################################################################################

    ######## End of [[ Used On 'Linux Distributions' ]]
else  ##################################################################################
    ######## [[ Used On 'macOS' ]]

    ####################################################################################
    ######## [[ Variables ]]


    prereqs_installer="macos_prereqs_installer.sh"
    nadeko_runner="macos_nadeko_runner.sh"

    ## To be exported
    _NADEKO_SERVICE="/Users/$USER/Library/LaunchAgents/bot.nadeko.Nadeko.plist"
    _NADEKO_SERVICE_NAME="bot.nadeko.Nadeko"


    ######## End of [[ Variables ]]
    ####################################################################################
    ######## [[[ Functions ]]]


    _SERVICE_ACTIONS() {
        ####
        # FUNCTION INFO:
        #
        # Actions dealing with the status/state of the 'bot.nadeko.Nadeko' service.
        #
        # @param $1 The actions to be performed (i.e. get service status or stop
        #           service)
        # @param $2 Dictates whether or not text indicating that the service has been
        #           stopped or is currently stopped, should be printed to the terminal.
        ####

        ## Saves the status of '$_NADEKO_SERVICE_NAME' to $_NADEKO_SERVICE_STATUS.
        if [[ $1 = "nadeko_service_status" ]]; then
            # Makes sure the nadeko service is enabled and loaded.
            launchctl enable gui/"$UID"/$_NADEKO_SERVICE_NAME &&
                launchctl load "$_NADEKO_SERVICE" 2>/dev/null
            _NADEKO_SERVICE_STATUS=$(launchctl print gui/$UID/$_NADEKO_SERVICE_NAME | grep "state") &&
                    _NADEKO_SERVICE_STATUS=${_NADEKO_SERVICE_STATUS/[[:blank:]]state = /} || {
                _NADEKO_SERVICE_STATUS="inactive"
            }
        ## Stops '$_NADEKO_SERVICE_NAME' if it is actively running.
        elif [[ $1 = "stop_service" ]]; then
            echo "Stopping '$_NADEKO_SERVICE_NAME'..."
            if [[ $_NADEKO_SERVICE_STATUS = "running" ]]; then
                launchctl stop $_NADEKO_SERVICE_NAME || {
                    echo "${_RED}Failed to stop '$_NADEKO_SERVICE_NAME'" >&2
                    echo "${_CYAN}You will need to restart '$_NADEKO_SERVICE_NAME'" \
                        "to apply any updates to NadekoBot$_NC"
                    return 1  # A.1.
                }
                if [[ $2 = true ]]; then
                    echo -e "\n${_GREEN}NadekoBot has been stopped$_NC"
                fi
            else
                if [[ $2 = true ]]; then
                    echo -e "\n${_CYAN}NadekoBot is currently not running$_NC"
                fi
            fi
        fi
    }


    ######## End of [[[ Functions ]]]
    ####################################################################################

    #### End of [[ Used On 'macOS' ]]
    ####################################################################################

fi
#### End of [ Variables and Functions ]
########################################################################################
#### [ Main ]


echo -e "Welcome to the NadekoBot installer\n"

while true; do
    # Get the current status of $_NADEKO_SERVICE_NAME.
    # NOTE: Will return 'inactive'   if it does not exist...
    _SERVICE_ACTIONS "nadeko_service_status"

    ## Disable option 1, if any of the following tools are not installed.
    if (! hash dotnet || ! hash redis-server || ! hash git || ! hash jq || (! hash \
            python && ! hash python3) || ! hash youtube-dl) &>/dev/null; then
        option_one_disabled=true
        echo "${_GREY}1. Download NadekoBot (Disabled until option 6 has been run)$_NC"
    ## Else enable it.
    else
        option_one_disabled=false
        echo "1. Download NadekoBot"
    fi

    ## Disable options 2, 3, and 5 if any of the tools are not installed or non of the
    ## directories/files could be found.
    if [[ ! -d NadekoBot/src/NadekoBot/ || ! -f NadekoBot/src/NadekoBot/credentials.json ||
            ! -d NadekoBot/src/NadekoBot/bin/Release || 
            -z $(jq -r ".Token" NadekoBot/src/NadekoBot/credentials.json) ]] ||
            (! hash dotnet || ! hash redis-server || ! hash git || ! hash jq || 
            (! hash python && ! hash python3) || ! hash  youtube-dl) &>/dev/null; then
        option_two_and_three_disabled=true
        option_five_disabled=true
        stop_nadeko_service="4. Stop NadekoBot"

        echo "${_GREY}2. Run NadekoBot in the background (Disabled until options 1," \
            "6, and 7 has been run)"
        echo "3. Run NadekoBot in the background with auto restart (Disabled until" \
            "options 1, 6, and 7 has been run)$_NC"
    ## Enable the ability to run NadekoBot in any run mode, if 'NadekoRun.sh' does not
    ## exist.
    elif [[ -f NadekoRun.sh ]]; then
        option_two_and_three_disabled=false

        ## Enable option 5 if NadekoBot's service is running.
        if [[ $_NADEKO_SERVICE_STATUS = "active" || $_NADEKO_SERVICE_STATUS = "running" ]]; then
            option_five_disabled=false
            run_mode_status=" ${_GREEN}(Running in this mode)$_NC"
            stop_nadeko_service="4. Stop NadekoBot"
        ## Disable option 5 if NadekoBot's service not running.
        elif [[ $_NADEKO_SERVICE_STATUS = "inactive" || $_NADEKO_SERVICE_STATUS = "waiting" ]]; then
            option_five_disabled=true
            run_mode_status=" ${_YELLOW}(Set up to run in this mode)$_NC"
            stop_nadeko_service="4. ${_GREY}Stop NadekoBot ('$_NADEKO_SERVICE_NAME' isn't running)$_NC"
        ## Else don't do anything...
        else
            run_mode_status=" ${_YELLOW}(Status unkown)$_NC"
            stop_nadeko_service="4. Stop NadekoBot"
        fi

        ## If NadekoBot is running in the background with auto restart...
        if grep -q '_code_name_="NadekoRunAR"' NadekoRun.sh; then
            echo "2. Run NadekoBot in the background"
            echo "3. Run NadekoBot in the background with auto restart${run_mode_status}"
        ## Else if NadekoBot is running in the background...
        elif grep -q '_code_name_="NadekoRun"' NadekoRun.sh; then
            echo "2. Run NadekoBot in the background${run_mode_status}"
            echo "3. Run NadekoBot in the background with auto restart"
        else
            echo "2. Run NadekoBot in the background"
            echo "3. Run NadekoBot in the background with auto restart"
        fi
    ## Enable options 2 and 3, but disable option 5.
    else
        option_two_and_three_disabled=false
        option_five_disabled=true
        stop_nadeko_service="4. Stop NadekoBot"
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

    ## Disable option 7 if NadekoBot has not been downloaded.
    if [[ ! -d NadekoBot/src/NadekoBot/ ]]; then
        echo "${_GREY}7. Set up credentials.json (Disabled until option 1 has been run)$_NC"
        option_seven_disabled=true
    else
        echo "7. Set up credentials.json"
        option_seven_disabled=false
    fi

    echo "8. Exit"
    read -r choice
    case "$choice" in
        1)  
            ## C.1. 
            if [[ $option_one_disabled = true ]]; then
                clear -x
                echo "${_RED}Option 1 is currently disabled$_NC"
                continue
            fi

            export _NADEKO_SERVICE
            export -f _SERVICE_ACTIONS
            export _NADEKO_SERVICE_NAME
            export _NADEKO_SERVICE_STATUS

            echo "Downloading 'nadeko_latest_installer.sh'..."
            # Download the latest version of 'nadeko_latest_installer.sh'.
            curl -s "$_RAW_URL"/nadeko_latest_installer.sh -o nadeko_latest_installer.sh || {
                echo "${_RED}Failed to download latest 'nadeko_latest_installer.sh'...$_NC" >&2
                _CLEAN_EXIT "1" "Exiting" "true"
            }
            clear -x
            # B.1.
            sudo chmod +x nadeko_latest_installer.sh && ./nadeko_latest_installer.sh

            # Rexecutes the new/downloaded version of 'installer_prep.sh', so that all
            # changes are applied.
            exec "$_INSTALLER_PREP"
            ;;
        2)
            ## C.1. 
            if [[ $option_two_and_three_disabled = true ]]; then
                clear -x
                echo "${_RED}Option 2 is currently disabled$_NC"
                continue
            fi

            export _NADEKO_SERVICE
            export _NADEKO_SERVICE_NAME
            export _NADEKO_SERVICE_STATUS
            export _CODENAME="NadekoRun"

            echo "Downloading '$nadeko_runner'..."
            # Download the latest version of '$nadeko_runner'.
            curl -s "$_RAW_URL"/"$nadeko_runner" -o nadeko_runner.sh || {
                echo "${_RED}Failed to download latest '$nadeko_runner'...$_NC" >&2
                _CLEAN_EXIT "1" "Exiting" "true"
            }
            clear -x

            printf "We will now run NadekoBot in the background. "
            read -rp "Press [Enter] to begin."
            # B.1.
            sudo chmod +x nadeko_runner.sh && ./nadeko_runner.sh
            clear -x
            ;;
        3)
            ## C.1. 
            if [[ $option_two_and_three_disabled = true ]]; then
                clear -x
                echo "${_RED}Option 3 is currently disabled$_NC"
                continue
            fi

            export _NADEKO_SERVICE
            export _NADEKO_SERVICE_NAME
            export _NADEKO_SERVICE_STATUS
            export _CODENAME="NadekoRunAR"

            echo "Downloading '$nadeko_runner'..."
            # Download the latest version of '$nadeko_runner'.
            curl -s "$_RAW_URL"/"$nadeko_runner" -o nadeko_runner.sh || {
                echo "${_RED}Failed to download latest '$nadeko_runner'...$_NC" >&2
                _CLEAN_EXIT "1" "Exiting" "true"
            }
            clear -x

            printf "We will now run NadekoBot in the background with auto restart. "
            read -rp "Press [Enter] to begin."
            # B.1.
            sudo chmod +x nadeko_runner.sh && ./nadeko_runner.sh
            clear -x
            ;;
        4)
            clear -x
            printf "We will now stop NadekoBot. "
            read -rp "Press [Enter] to begin."
            _SERVICE_ACTIONS "stop_service" "true"
            read -rp "Press [Enter] to return to the installer menu"
            clear -x
            ;;
        5)
            clear -x
            ## C.1. 
            if [[ $option_five_disabled = true ]]; then
                echo "${_RED}Option 5 is currently disabled$_NC"
                continue
            fi

            echo "Watching '$_NADEKO_SERVICE_NAME' logs, live..."
            if [[ $_DISTRO != "Darwin" ]]; then
                echo -e "${_CYAN}To return to the installer menu:\n1) Press 'Ctrl'" \
                    "+ 'C'\n2) Press 'Q'$_NC"
            else
                echo -e "${_CYAN}To exit the installer:\n1) Press 'Ctrl" \
                    "+ C'\n2) Press 'Q'$_NC"
            fi
            if [[ $_DISTRO != "Darwin" ]]; then
                # The pipe makes it possible to exit journalctl without exiting the
                # script
                sudo journalctl -f -u "$_NADEKO_SERVICE_NAME"  | less -FRSXM
            else
                tail -f "bot.nadeko.Nadeko.log" | less -FRSXM
            fi
            clear -x
            ;;
        6)
            echo "Downloading '$prereqs_installer' as 'prereqs_installer.sh'..."
            # Download latest version of $prereqs_installer.
            curl -s "$_RAW_URL"/"$prereqs_installer" -o prereqs_installer.sh || {
                echo "${_RED}Failed to download latest '$prereqs_installer'...$_NC" >&2
                _CLEAN_EXIT "1" "Exiting" "true"
            }
            clear -x
            # B.1.
            sudo chmod +x prereqs_installer.sh && ./prereqs_installer.sh
            clear -x
            ;;
        7)
            ## C.1. 
            if [[ $option_seven_disabled = true ]]; then
                clear -x
                echo "${_RED}Option 7 is currently disabled$_NC"
                continue
            fi

            echo "Downloading 'credentials_setup.sh'..."
            # Download latest version of 'credentials_setup.sh'.
            curl -s "$_RAW_URL"/credentials_setup.sh -o credentials_setup.sh || {
                echo "${_RED}Failed to download latest 'credentials_setup.sh'...$_NC" >&2
                _CLEAN_EXIT "1" "Exiting" "true"
            }
            clear -x
            # B.1.
            sudo chmod +x credentials_setup.sh && ./credentials_setup.sh
            clear -x
            ;;
        8)
            _CLEAN_EXIT "0" "Exiting"
            ;;
        *)
            clear -x
            echo "${_RED}Invalid input: '$choice' is not a valid option$_NC" >&2
            ;;
    esac
done


#### End of [ Main ]
########################################################################################
