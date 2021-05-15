#!/bin/bash
#
# The master/main installer for macOS and Linux Distributions.
#
# COMMENT '[letter].[number].' KEY INFO:
#   A.1. - Save the current time and date, which will be used in conjunction with
#          journalctl.
#   B.1. - Decide whether we need to use 'disable' or 'enable', and what tense it
#          should be in.
#   C.1. - Add code to 'NadekoRun.sh' required to run NadekoBot in the background.
#   D.1. - Add code to 'NadekoRun.sh' required to run NadekoBot in the background with
#          auto restart.
#   E.1. - Return to prevent further code execution.
#   F.1. - Set the execution permissions for the downloaded script, then execute it.
#   G.1. - Prevent the code from running if the options is disabled.
#
########################################################################################
#### [ Variables and Functions ]
#### The variables and functions below are designed specifically for either macOS or
#### Linux distribution.


# Keeps track of this script's process id, in case it needs to be manually killed.
export _NADEKO_MASTER_INSTALLER_PID=$$

####################################################################################
######## [ Variables Used On 'Linux Distributions' ]


if [[ $_DISTRO != "Darwin" ]]; then
    ############################################################################
    ######## [ Variables ]


    nadeko_service="/etc/systemd/system/nadeko.service"
    nadeko_service_name="nadeko.service"
    prereqs_installer="linux_prereqs_installer.sh"
    nadeko_service_content="[Unit] \
        \nDescription=NadekoBot service\
        \n \
        \n[Service] \
        \nExecStart=/bin/bash $_WORKING_DIR/NadekoRun.sh \
        \nUser=$USER \
        \nType=simple \
        \nStandardOutput=syslog \
        \nStandardError=syslog \
        \nSyslogIdentifier=NadekoBot \
        \n \
        \n[Install] \
        \nWantedBy=multi-user.target"


    ######## End of [ Variables ]
    ############################################################################
    ######## [ Functions ]


    service_actions() {
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

        case "$1" in
            ## Saves the status of 'nadeko.service' to $nadeko_service_status.
            nadeko_service_status)
                nadeko_service_status=$(systemctl is-active nadeko.service)
                ;;
            ## Stops 'nadeko.service' if it is actively running.
            stop_service)
                if [[ $nadeko_service_status = "active" ]]; then
                    echo "Stopping 'nadeko.service'..."
                    sudo systemctl stop nadeko.service || {
                        echo "${_RED}Failed to stop 'nadeko.service'" >&2
                        echo "${_CYAN}You will need to restart 'nadeko.service' to" \
                            "apply any updates to NadekoBot$_NC"
                        return 1  # E.1. Return to prevent further code execution.
                    }
                    if [[ $2 = true ]]; then
                        echo -e "\n${_GREEN}NadekoBot has been stopped$_NC"
                    fi
                else
                    if [[ $2 = true ]]; then
                        echo -e "\n${_CYAN}NadekoBot is currently not running$_NC"
                    fi
                fi
                ;;
        esac
    }

    nadeko_starter() {
        ####
        # FUNCTION INFO:
        #
        # Start NadekoBot in the specified run mode.
        #
        # @param $1 Specifies which mode to run NadekoBot in.
        ####

        timer=60
        # A.1.
        start_time=$(date +"%F %H:%M:%S")

        ## B.1.
        if [[ $1 = "NadekoRun" ]]; then
            dis_en_lower="disable"
            dis_en_upper="Disabling"
        else
            dis_en_lower="enable"
            dis_en_upper="Enabling"
        fi

        ## Create 'nadeko.service', if it does not already exist.
        if [[ ! -f $nadeko_service ]]; then
            echo "Creating 'nadeko.service'..."
            echo -e "$nadeko_service_content" | sudo tee "$nadeko_service" &>/dev/null &&
                    sudo systemctl daemon-reload || {
                echo "${_RED}Failed to create 'nadeko.service'" >&2
                echo "${_CYAN}This service must exist for NadekoBot to work$_NC"
                _CLEAN_EXIT "1" "Exiting"
            }
        fi

        ## Disable or enable 'nadeko.service'.
        echo "$dis_en_upper 'nadeko.service'..."
        sudo systemctl "$dis_en_lower" nadeko.service || {
            echo "${_RED}Failed to $dis_en_lower 'nadeko.service'" >&2
            echo "${_CYAN}This service must be ${dis_en_lower}d in order to use this" \
                "run mode$_NC"
            read -rp "Press [Enter] to return to the installer menu"
            return 1  # E.1.
        }

        # Check if 'NadekoRun.sh' exists.
        if [[ -f NadekoRun.sh ]]; then
            echo "Updating 'NadekoRun.sh'..."
        else
            echo "Creating 'NadekoRun.sh'..."
            touch NadekoRun.sh
            sudo chmod +x NadekoRun.sh
        fi

        ## C.1.
        if [[ $1 = "NadekoRun" ]]; then
            echo -e "#!bin/bash \
                \n \
                \n_code_name_=\"NadekoRun\" \
                \n \
                \necho \"Running NadekoBot in the background\" \
                \nyoutube-dl -U \
                \n \
                \ncd $_WORKING_DIR/NadekoBot \
                \ndotnet build -c Release \
                \ncd $_WORKING_DIR/NadekoBot/src/NadekoBot \
                \necho \"Running NadekoBot...\" \
                \ndotnet run -c Release \
                \necho \"Done\" \
                \ncd $_WORKING_DIR \
                \n" > NadekoRun.sh
        ## D.1.
        else
            echo -e "#!/bin/bash \
                \n \
                \n_code_name_=\"NadekoRunAR\" \
                \n \
                \necho \"\" \
                \necho \"Running NadekoBot in the background with auto restart\" \
                \nyoutube-dl -U \
                \n \
                \nsleep 5 \
                \ncd $_WORKING_DIR/NadekoBot \
                \ndotnet build -c Release \
                \n \
                \nwhile true; do \
                \n    cd $_WORKING_DIR/NadekoBot/src/NadekoBot && \
                \n        dotnet run -c Release \
                \n \
                \n    youtube-dl -U \
                \n    sleep 10 \
                \ndone \
                \n \
                \necho \"Stopping NadekoBot\"" > NadekoRun.sh
        fi

        ## Restart 'nadeko.service' if it is currently active.
        if [[ $nadeko_service_status = "active" ]]; then
            echo "Restarting 'nadeko.service'..."
            sudo systemctl restart nadeko.service || {
                echo "${_RED}Failed to restart 'nadeko.service'$_NC" >&2
                read -rp "Press [Enter] to return to the installer menu"
                return 1  # E.1.
            }
            echo "Waiting 60 seconds for 'nadeko.service' to restart..."
        ## Start 'nadeko.service' if it is NOT currently active.
        else
            echo "Starting 'nadeko.service'..."
            sudo systemctl start nadeko.service || {
                echo "${_RED}Failed to start 'nadeko.service'$_NC" >&2
                read -rp "Press [Enter] to return to the installer menu"
                return 1  # E.1.
            }
            echo "Waiting 60 seconds for 'nadeko.service' to start..."
        fi

        ## Wait in order to give 'nadeko.service' enough time to (re)start.
        while ((timer > 0)); do
            echo -en "$_CLRLN$timer seconds left"
            sleep 1
            ((timer-=1))
        done

        # NOTE: $_NO_HOSTNAME is purposefully unquoted. Do not quote the variable.
        echo -e "\n\n-------- nadeko.service startup logs ---------" \
            "\n$(journalctl -q -u nadeko -b $_NO_HOSTNAME -S "$start_time" 2>/dev/null ||
            sudo journalctl -q -u nadeko -b $_NO_HOSTNAME -S "$start_time")" \
            "\n--------- End of nadeko.service startup logs --------\n"

        echo -e "${_CYAN}Please check the logs above to make sure that there aren't any" \
            "errors, and if there are, to resolve whatever issue is causing them\n"

        echo "${_GREEN}NadekoBot is now running in the background$_NC"
        read -rp "Press [Enter] to return to the installer menu"
    }


    ######## End of [ Functions ]
    ############################################################################

######## End of [ Variables Used On 'Linux Distributions' ]
####################################################################################
else
####################################################################################
######## [ Variables Used On 'macOS' ]

    ############################################################################
    ######## [ Variables ]


    nadeko_service="/Users/$USER/Library/LaunchAgents/bot.nadeko.Nadeko.plist"
    nadeko_service_name="bot.nadeko.Nadeko"
    prereqs_installer="macos_prereqs_installer.sh"
    nadeko_service_content="<?xml version=\"1.0\" encoding=\"UTF-8\"?> \
        \n<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\"> \
        \n<plist version=\"1.0\"> \
        \n<dict> \
        \n	<key>Disabled</key> \
        \n	<false/> \
        \n	<key>Label</key> \
        \n	<string>bot.nadeko.Nadeko</string> \
        \n	<key>ProgramArguments</key> \
        \n	<array> \
        \n		<string>$(which bash)</string> \
        \n		<string>$_WORKING_DIR/NadekoRun.sh</string> \
        \n	</array> \
        \n	<key>RunAtLoad</key> \
        \n	<false/> \
        \n</dict> \
        \n</plist>"


    ######## End of [ Variables ]
    ############################################################################
    ######## [ Functions ]


    service_actions() {
        ####
        # FUNCTION INFO:
        #
        # Actions dealing with the status/state of the 'nadeko.service' service.
        #
        # @param $1 The actions to be performed (i.e. get service status or stop
        #           service)
        # @param $2 Dictates whether or not text indicating that the service has been
        #           stopped or is currently stopped, should be printed to the terminal.
        ####

        case "$1" in
            ## Saves the status of 'bot.nadeko.Nadeko' to $nadeko_service_status.
            nadeko_service_status)
                # Makes sure the nadeko service is enabled and loaded.
                launchctl enable gui/"$UID"/bot.nadeko.Nadeko &&
                    launchctl load "$nadeko_service" 2>/dev/null
                nadeko_service_status=$(launchctl print gui/$UID/bot.nadeko.Nadeko | grep "state") &&
                        nadeko_service_status=${nadeko_service_status/[[:blank:]]state = /} || {
                    nadeko_service_status="inactive"
                }
                ;;
            ## Stops 'bot.nadeko.Nadeko' if it is actively running.
            stop_service)
                if [[ $nadeko_service_status = "running" ]]; then
                    launchctl stop bot.nadeko.Nadeko || {
                        echo "${_RED}Failed to stop 'bot.nadeko.Nadeko'" >&2
                        echo "${_CYAN}You will need to restart 'bot.nadeko.Nadeko'" \
                            "to apply any updates to NadekoBot$_NC"
                        return 1  # E.1.
                    }
                    if [[ $2 = true ]]; then
                        echo -e "\n${_GREEN}NadekoBot has been stopped$_NC"
                    fi
                else
                    if [[ $2 = true ]]; then
                        echo -e "\n${_CYAN}NadekoBot is currently not running$_NC"
                    fi
                fi
                ;;
        esac
    }

    nadeko_starter() {
        ####
        # FUNCTION INFO:
        #
        # Start NadekoBot in the specified run mode.
        #
        # @param $1 Specifies which mode to run NadekoBot in.
        ####
        
        timer=60
        # A.1.
        start_time=$(date +"%F %H:%M:%S")

        ## B.1.
        if [[ $1 = "NadekoRun" ]]; then
            dis_en_lower="disable"
            dis_en_upper="Disabling"
        else
            dis_en_lower="enable"
            dis_en_upper="Enabling"
        fi

        echo "${_CYAN}NOTE: Due to limiations on macOS, NadekoBots's startup" \
            "logs will not be displayed$_NC"

        ## Create 'bot.nadeko.Nadeko', if it does not already exist.
        if [[ ! -f $nadeko_service ]]; then
            echo "Creating 'bot.nadeko.Nadeko'..."
            echo -e "$nadeko_service_content" | sudo tee "$nadeko_service" &>/dev/null
        fi

        # Check if 'NadekoRun.sh' exists.
        if [[ -f NadekoRun.sh ]]; then
            echo "Updating 'NadekoRun.sh'..."
            echo "Updating 'bot.nadeko.Nadeko'..."
        else
            echo "Creating 'NadekoRun.sh'..."
            touch NadekoRun.sh
            sudo chmod +x NadekoRun.sh
            echo "Updating 'bot.nadeko.Nadeko'..."
        fi

        ## C.1.
        if [[ $1 = "NadekoRun" ]]; then
            echo -e "#!/bin/bash \
                \n \
                \nexport DOTNET_CLI_HOME=/tmp \
                \n_code_name_=\"NadekoRun\" \
                \n \
                \nadd_date() { \
                \n    while IFS= read -r line; do \
                \n        echo -e \"\$(date +\"%F %H:%M:%S\") \$line\" \
                \n    done \
                \n} \
                \n \
                \n( \
                \n    echo \"\" \
                \n    echo \"Running NadekoBot in the background\" \
                \n    brew upgrade youtube-dl \
                \n) | add_date >> $_WORKING_DIR/bot.nadeko.Nadeko.log \
                \n \
                \n( \
                \n    cd $_WORKING_DIR/NadekoBot \
                \n    $(which dotnet) build -c Release \
                \n    cd $_WORKING_DIR/NadekoBot/src/NadekoBot \
                \n    echo \"Running NadekoBot...\" \
                \n    $(which dotnet) run -c Release \
                \n    echo \"Done\" \
                \n    cd $_WORKING_DIR \
                \n) | add_date >> $_WORKING_DIR/bot.nadeko.Nadeko.log" > NadekoRun.sh
            echo -e "<?xml version=\"1.0\" encoding=\"UTF-8\"?> \
                \n<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\"> \
                \n<plist version=\"1.0\"> \
                \n<dict> \
                \n    <key>Disabled</key> \
                \n    <false/> \
                \n    <key>Label</key> \
                \n    <string>bot.nadeko.Nadeko</string> \
                \n    <key>ProgramArguments</key> \
                \n    <array> \
                \n        <string>$(which bash)</string> \
                \n        <string>$_WORKING_DIR/NadekoRun.sh</string> \
                \n    </array> \
                \n    <key>RunAtLoad</key> \
                \n    <false/> \
                \n</dict> \
                \n</plist>" > "$nadeko_service"
        ## D.1.
        else
            echo -e "#!/bin/bash \
                \n \
                \nexport DOTNET_CLI_HOME=/tmp \
                \n_code_name_=\"NadekoRunAR\" \
                \n \
                \nadd_date() { \
                \n    while IFS= read -r line; do \
                \n        echo -e \"\$(date +\"%F %H:%M:%S\") \$line\" \
                \n    done \
                \n} \
                \n \
                \n( \
                \n    echo \"\" \
                \n    echo \"Running NadekoBot in the background with auto restart\" \
                \n    brew upgrade youtube-dl \
                \n \
                \n    sleep 5 \
                \n    cd $_WORKING_DIR/NadekoBot \
                \n    $(which dotnet) build -c Release \
                \n) | add_date >> $_WORKING_DIR/bot.nadeko.Nadeko.log \
                \n \
                \n( \
                \n    while true; do \
                \n        cd $_WORKING_DIR/NadekoBot/src/NadekoBot && \
                \n            $(which dotnet) run -c Release \
                \n \
                \n        brew upgrade youtube-dl \
                \n        sleep 10 \
                \n    done \
                \n    echo \"Stopping NadekoBot\" \
                \n) | add_date >> $_WORKING_DIR/bot.nadeko.Nadeko.log" > NadekoRun.sh
            echo -e "<?xml version=\"1.0\" encoding=\"UTF-8\"?> \
                \n<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\"> \
                \n<plist version=\"1.0\"> \
                \n<dict> \
                \n    <key>Disabled</key> \
                \n    <false/> \
                \n    <key>Label</key> \
                \n    <string>bot.nadeko.Nadeko</string> \
                \n    <key>ProgramArguments</key> \
                \n    <array> \
                \n        <string>$(which bash)</string> \
                \n        <string>$_WORKING_DIR/NadekoRun.sh</string> \
                \n    </array> \
                \n    <key>RunAtLoad</key> \
                \n    <true/> \
                \n</dict> \
                \n</plist>" > "$nadeko_service"
        fi

        ## Restart 'bot.nadeko.Nadeko' if it is currently running.
        if [[ $nadeko_service_status = "running" ]]; then
            echo "Restarting 'bot.nadeko.Nadeko'..."
            launchctl kickstart -k gui/$UID/bot.nadeko.Nadeko || {
                error_code=$(launchctl error "$?")
                echo "${_RED}Failed to restart 'bot.nadeko.Nadeko'$_NC" >&2
                echo "Error code: $error_code"
                read -rp "Press [Enter] to return to the installer menu"
                return 1  # E.1.
            }
            echo "Waiting 60 seconds for 'bot.nadeko.Nadeko' to restart..."
        ## Start 'bot.nadeko.Nadeko' if it is NOT currently running.
        else
            echo "Starting 'bot.nadeko.Nadeko'..."
            launchctl start bot.nadeko.Nadeko || {
                error_code=$(launchctl error "$?")
                echo "${_RED}Failed to start 'bot.nadeko.Nadeko'$_NC" >&2
                echo "Error code: $error_code"
                read -rp "Press [Enter] to return to the installer menu"
                return 1  # E.1.
            }
            echo "Waiting 60 seconds for 'bot.nadeko.Nadeko' to start..."
        fi

        ## Wait in order to give 'bot.nadeko.Nadeko' enough time to (re)start.
        while ((timer > 0)); do
            echo -en "${_CLRLN}${timer} seconds left"
            sleep 1
            ((timer-=1))
        done

        echo -e "\n\n${_CYAN}It's recommended to inspect 'bot.nadeko.Nadeko.log'" \
            "to confirm that there were no errors during NadekoBot's startup$_NC"
        read -rp "Press [Enter] to return to the installer menu"
    }


    ######## End of [ Functions ]
    ############################################################################

fi
######## End of [ Variables Used On 'macOS' ]
####################################################################################


#### End of [ Variables and Functions ]
########################################################################################
#### [ Main ]


echo -e "Welcome to the NadekoBot installer\n"

while true; do
    ## Create $nadeko_service_name, if it does not already exist.
    if [[ ! -f $nadeko_service ]]; then
        echo "Creating '$nadeko_service_name'..."
        ## If running on macOS, create '/Users/"$USER"/Library/LaunchAgents' if
        ## 'LaunchAgents' doesn't already exist.
        if [[ $_DISTRO = "Darwin" && ! -d /Users/$USER/Library/LaunchAgents/ ]]; then
            # TODO: Add error catching???
            mkdir /Users/"$USER"/Library/LaunchAgents
        fi
        # TODO: Add comments to this echo...
        echo -e "$nadeko_service_content" | sudo tee "$nadeko_service" &>/dev/null &&
            if [[ $_DISTRO != "Darwin" ]]; then
                # Make changes to services in 
                sudo systemctl daemon-reload
            else
                sudo chown "$USER":staff "$nadeko_service"
                launchctl enable gui/"$UID"/"$nadeko_service_name"
                launchctl load "$nadeko_service"
            fi || {
                echo "${_RED}Failed to create '$nadeko_service_name'" >&2
                echo "${_CYAN}This service must exist for NadekoBot to work$_NC"
                _CLEAN_EXIT "1" "Exiting"
            }
    fi

    # Get the current status of $nadeko_service_name.
    service_actions "nadeko_service_status"

    ################################################################################
    ##### [ User Options For Starting NadekoBot ]

    ## Disable option 1, if any of the following tools are not installed.
    if (! hash dotnet || ! hash redis-server || ! hash git || ! hash jq || (! hash \
            python && ! hash python3) || ! hash youtube-dl) &>/dev/null; then
        option_one_disabled=true
        echo "${_GREY}1. Download NadekoBot (Disabled until option 6 is ran)$_NC"
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

        echo "${_GREY}2. Run NadekoBot in the background (Disabled until options 1," \
            "6, and 6 are ran)"
        echo "3. Run NadekoBot in the background with auto restart (Disabled until" \
            "options 1, 6, and 6 are ran)$_NC"
    ## Enable the ability to run NadekoBot in any run mode, if 'NadekoRun.sh' does not
    ## exist.
    elif [[ -f NadekoRun.sh ]]; then
        option_two_and_three_disabled=false

        ## Enable option 5 if NadekoBot's service is running.
        if [[ $nadeko_service_status = "active" || $nadeko_service_status = "running" ]]; then
            option_five_disabled=false
            run_mode_status=" ${_GREEN}(Running in this mode)$_NC"
        ## Disable option 5 if NadekoBot's service not running.
        elif [[ $nadeko_service_status = "inactive" || $nadeko_service_status = "waiting" ]]; then
            option_five_disabled=true
            run_mode_status=" ${_YELLOW}(Set up to run in this mode)$_NC"
        ## Else don't do anything...
        else
            run_mode_status=" ${_YELLOW}(Status unkown)$_NC"
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
        echo "2. Run NadekoBot in the background"
        echo "3. Run NadekoBot in the background with auto restart"
    fi

    echo "4. Stop NadekoBot"

    if [[ $option_five_disabled = true ]]; then
        echo "${_GREY}5. Display '$nadeko_service_name' logs in follow mode" \
            "(Disabled until NadekoBot has been started)$_NC"
    else
        echo "5. Display '$nadeko_service_name' logs in follow mode"
    fi

    echo "6. Install prerequisites"

    ## Disable option 7 if NadekoBot has not been downloaded.
    if [[ ! -d NadekoBot/src/NadekoBot/ ]]; then
        echo "${_GREY}7. Set up credentials.json (Disabled until option 1 is ran)$_NC"
        option_seven_disabled=true
    else
        echo "7. Set up credentials.json"
        option_seven_disabled=false
    fi

    echo "8. Exit"
    read -r choice
    case "$choice" in
        1)  
            ## G.1. 
            if [[ $option_one_disabled = true ]]; then
                clear -x
                echo "${_RED}Option 1 is currently disabled$_NC"
                continue
            fi

            export nadeko_service
            export -f service_actions
            export nadeko_service_name
            export nadeko_service_status
            if [[ $_DISTRO != "Darwin" ]]; then export nadeko_service_content; fi

            echo "Downloading 'nadeko_latest_installer.sh'..."
            # Download the latest version of 'nadeko_latest_installer.sh'.
            curl -s "$_RAW_URL"/nadeko_latest_installer.sh -o nadeko_latest_installer.sh || {
                echo "${_RED}Failed to download latest 'nadeko_latest_installer.sh'...$_NC" >&2
                _CLEAN_EXIT "1" "Exiting" "true"
            }
            clear -x
            # F.1.
            sudo chmod +x nadeko_latest_installer.sh && ./nadeko_latest_installer.sh

            # Rexecutes the new/downloaded version of 'installer_prep.sh', so that all
            # changes are applied.
            exec "$_INSTALLER_PREP"
            ;;
        2)
            clear -x
            ## G.1. 
            if [[ $option_two_and_three_disabled = true ]]; then
                echo "${_RED}Option 2 is currently disabled$_NC"
                continue
            fi

            printf "We will now run NadekoBot in the background. "
            read -rp "Press [Enter] to begin."
            nadeko_starter "NadekoRun"
            clear -x
            ;;
        3)
            clear -x
            ## G.1. 
            if [[ $option_two_and_three_disabled = true ]]; then
                echo "${_RED}Option 3 is currently disabled$_NC"
                continue
            fi

            printf "We will now run NadekoBot in the background with auto restart. "
            read -rp "Press [Enter] to begin."
            nadeko_starter "NadekoRunAR"
            clear -x
            ;;
        4)
            clear -x
            printf "We will now stop NadekoBot. "
            read -rp "Press [Enter] to begin."
            service_actions "stop_service" "true"
            read -rp "Press [Enter] to return to the installer menu"
            clear -x
            ;;
        5)
            clear -x
            ## G.1. 
            if [[ $option_five_disabled = true ]]; then
                echo "${_RED}Option 5 is currently disabled$_NC"
                continue
            fi

            echo "Watching '$nadeko_service_name' logs, live..."
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
                sudo journalctl -f -u "$nadeko_service_name"  | less -FRSXM
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
            # F.1.
            sudo chmod +x prereqs_installer.sh && ./prereqs_installer.sh
            clear -x
            ;;
        7)
            ## G.1. 
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
            # F.1.
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


    ##### End of [ User Options For Starting NadekoBot ]
    ################################################################################

done
#### End of [ Main ]
########################################################################################
