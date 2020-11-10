#!/bin/bash

################################################################################
#
# The master/main installer for macOS and Linux Distributions.
#
# Note: All variables not defined in this script, are exported from
# 'linuxAIO.sh' and 'installer_prep.sh'.
#
################################################################################
#
    export nadeko_master_installer_pid=$$

#
################################################################################
#
# [ Variables and Functions ]
#
# The variables and functions below are designed specifically for either macOS
# or linux distribution.
#
################################################################################
#
    ############################################################################
    # Variables used when executed on 'Linux Distributions'
    ############################################################################
    if [[ $distro != "Darwin" ]]; then
        #-------------------------------
        # Variables
        #-------------------------------
        nadeko_service="/lib/systemd/system/nadeko.service"
        nadeko_service_name="nadeko.service"
        prereqs_installer="linux_prereqs_installer.sh"
        nadeko_service_content="[Unit] \
            \nDescription=NadekoBot \
            \n \
            \n[Service] \
            \nExecStart=/bin/bash $root_dir/NadekoRun.sh \
            \nUser=$USER \
            \nType=simple \
            \nStandardOutput=syslog \
            \nStandardError=syslog \
            \nSyslogIdentifier=NadekoBot \
            \n \
            \n[Install] \
            \nWantedBy=multi-user.target"

        #-------------------------------
        # Function
        #-------------------------------
        service_actions() {
            case "$1" in
                nadeko_service_status)
                    nadeko_service_status=$(systemctl is-active $nadeko_service_name)
                    ;;
                stop_service)
                    if [[ $nadeko_service_status = "active" ]]; then
                        echo "Stopping '$nadeko_service_name'..."
                        sudo systemctl stop $nadeko_service_name || {
                            echo "${red}Failed to stop '$nadeko_service_name'" >&2
                            echo "${cyan}You will need to restart '$nadeko_service_name'" \
                                "to apply any updates to NadekoBot${nc}"
                        }
                        if [[ $2 = true ]]; then
                            echo -e "\n${green}NadekoBot has been stopped${nc}"
                        fi
                    else
                        if [[ $2 = true ]]; then
                            echo -e "\n${cyan}NadekoBot is currently not running${nc}"
                        fi
                    fi
                    ;;
            esac
        }

        nadeko_starter() {
            timer=60
            # Saves the current time and date, which will be used with journalctl
            start_time=$(date +"%F %H:%M:%S")

            if [[ $1 = "2" ]]; then
                disable_enable="disable"
                disable_enable2="Disabling"
            else
                disable_enable="enable"
                disable_enable2="Enabling"
            fi

            # E.1. Creates '$nadeko_service_name', if it does not exist
            if [[ ! -f $nadeko_service ]]; then
                echo "Creating '$nadeko_service_name'..."
                echo -e "$nadeko_service_content" | sudo tee "$nadeko_service" &>/dev/null &&
                    sudo systemctl daemon-reload || {
                        echo "${red}Failed to create '$nadeko_service_name'" >&2
                        echo "${cyan}This service must exist for NadekoBot to work${nc}"
                        clean_exit "1" "Exiting"
                    }
            fi

            # Disables or enables '$nadeko_service_name'
            echo "$disable_enable2 '$nadeko_service_name'..."
            sudo systemctl "$disable_enable" $nadeko_service_name || {
                echo "${red}Failed to $disable_enable '$nadeko_service_name'" >&2
                echo "${cyan}This service must be ${disable_enable}d in order" \
                    "to use this run mode${nc}"
                read -p "Press [Enter] to return to the installer menu"
                clean_exit "1" "Exiting"
            }

            if [[ -f NadekoRun.sh ]]; then
                echo "Updating 'NadekoRun.sh'..."
            else
                echo "Creating 'NadekoRun.sh'..."
                touch NadekoRun.sh
                sudo chmod +x NadekoRun.sh
            fi
            
            if [[ $1 = "2" ]]; then 
                echo -e "#!bin/bash \
                    \n \
                    \n_code_name_=\"NadekoRun\" \
                    \n \
                    \necho \"Running NadekoBot in the background\" \ 
                    \nyoutube-dl -U \
                    \n \
                    \ncd $root_dir/NadekoBot \
                    \ndotnet restore \
                    \ndotnet build -c Release \
                    \ncd $root_dir/NadekoBot/src/NadekoBot \
                    \necho \"Running NadekoBot...\" \
                    \ndotnet run -c Release \
                    \necho \"Done\" \
                    \ncd $root_dir \
                    \n" > NadekoRun.sh
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
                    \ncd $root_dir/NadekoBot \
                    \ndotnet restore && dotnet build -c Release \
                    \n \
                    \nwhile true; do \
                    \n    cd $root_dir/NadekoBot/src/NadekoBot && \
                    \n    dotnet run -c Release \
                    \n \
                    \n    youtube-dl -U \
                    \n    sleep 10 \
                    \ndone" > NadekoRun.sh
            fi

            # Starting or restarting '$nadeko_service_name'
            if [[ $nadeko_service_status = "active" ]]; then
                echo "Restarting '$nadeko_service_name'..."
                sudo systemctl restart $nadeko_service_name || {
                    echo "${red}Failed to restart '$nadeko_service_name'${nc}" >&2
                    read -p "Press [Enter] to return to the installer menu"
                    clean_exit "1" "Exiting"
                }
                echo "Waiting 60 seconds for '$nadeko_service_name' to restart..."
            else
                echo "Starting '$nadeko_service_name'..."
                sudo systemctl start $nadeko_service_name || {
                    echo "${red}Failed to start '$nadeko_service_name'${nc}" >&2
                    read -p "Press [Enter] to return to the installer menu"
                    clean_exit "1" "Exiting"
                }
                echo "Waiting 60 seconds for '$nadeko_service_name' to start..."
            fi

            # Waits in order to give '$nadeko_service_name' enough time to (re)start
            while ((timer > 0)); do
                echo -en "${clrln}${timer} seconds left"
                sleep 1
                ((timer-=1))
            done

            # Note: $no_hostname is purposefully unquoted. Do not quote those variables.
            echo -e "\n\n-------- $nadeko_service_name startup logs ---------" \
                "\n$(journalctl -q -u nadeko -b $no_hostname -S "$start_time")" \
                "\n--------- End of $nadeko_service_name startup logs --------\n"

            echo -e "${cyan}Please check the logs above to make sure that there aren't any" \
                "errors, and if there are, to resolve whatever issue is causing them\n"

            echo "${green}NadekoBot is now running in the background${nc}"
            read -p "Press [Enter] to return to the installer menu"

        }
    
    ############################################################################
    # Variables use when executed on 'macOS'
    ############################################################################
    else
        #-------------------------------
        # Variables
        #-------------------------------
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
            \n	<string>$nadeko_service_name</string> \
            \n	<key>ProgramArguments</key> \
            \n	<array> \
            \n		<string>$(which bash)</string> \
            \n		<string>$root_dir/NadekoRun.sh</string> \
            \n	</array> \
            \n	<key>RunAtLoad</key> \
            \n	<true/> \
            \n	<key>StandardErrorPath</key> \
            \n	<string>$root_dir/.$nadeko_service_name.stderr</string> \
            \n	<key>StandardOutPath</key> \
            \n	<string>$root_dir/.$nadeko_service_name.stdout</string> \
            \n</dict> \
            \n</plist>"

        #-------------------------------
        # Function
        #-------------------------------
        service_actions() {
            case "$1" in
                nadeko_service_status)
                    launchctl load /Users/$USER/Library/LaunchAgents/$nadeko_service_name.plist 2>/dev/null
                    # Have to save to two variables because if I place the code inside the paramerter
                    # expansion, it's save "status = [status]" instead of just "status"
                    nadeko_service_status=$(launchctl print gui/$UID/$nadeko_service_name | grep "state") &&
                        nadeko_service_status=${nadeko_service_status/[[:blank:]]state = /} || {
                            nadeko_service_status="inactive"
                        }
                    ;;
                # TODO: Update to be similar to linux version
                stop_service)
                    launchctl stop $nadeko_service_name || {
                        echo "${red}Failed to stop '$nadeko_service_name'" >&2
                        echo "${cyan}You will need to restart '$nadeko_service_name'" \
                            "to apply any updates to NadekoBot${nc}"
                    }
                    ;;
            esac
        }

        nadeko_starter() {
            timer=60
            # Saves the current time and date, which will be used with journalctl
            start_time=$(date +"%F %H:%M:%S")

            if [[ $1 = "2" ]]; then
                disable_enable="disable"
                disable_enable2="Disabling"
            else
                disable_enable="enable"
                disable_enable2="Enabling"
            fi

            # E.1. Creates '$nadeko_service_name', if it does not exist
            if [[ ! -f $nadeko_service ]]; then
                echo "Creating '$nadeko_service_name'..."
                echo -e "$nadeko_service_content" | sudo tee "$nadeko_service" &>/dev/null
            fi

            # Disables or enables '$nadeko_service_name'
            echo "$disable_enable2 '$nadeko_service_name'..."
            sudo launchctl "$disable_enable" gui/"$UID"/$nadeko_service_name || {
                echo "${red}Failed to $disable_enable '$nadeko_service_name'" >&2
                echo "${cyan}This service must be ${disable_enable}d in order" \
                    "to use this run mode${nc}"
                read -p "Press [Enter] to return to the installer menu"
                clean_exit "1" "Exiting"
            }

            if [[ -f NadekoRun.sh ]]; then
                echo "Updating 'NadekoRun.sh'..."
            else
                echo "Creating 'NadekoRun.sh'..."
                touch NadekoRun.sh
                sudo chmod +x NadekoRun.sh
            fi
            
            if [[ $1 = "2" ]]; then 
                echo -e "#\!/bin/bash \
                    \n \
                    \nexport DOTNET_CLI_HOME=/tmp \
                    \necho \"\" \
                    \necho \"Running NadekoBot in the background\" \
                    \nbrew upgrade youtube-dl \
                    \n \
                    \ncd $root_dir/NadekoBot \
                    \n$(which dotnet) restore \
                    \n$(which dotnet) build -c Release \
                    \ncd $root_dir/NadekoBot/src/NadekoBot \
                    \necho \"Running NadekoBot...\" \
                    \n$(which dotnet) run -c Release \
                    \necho \"Done\" \
                    \ncd $root_dir \
                    \n" > NadekoRun.sh
            else
                echo -e "#\!/bin/bash \
                    \n \
                    \nexport DOTNET_CLI_HOME=/tmp \
                    \necho \"\" \
                    \necho \"Running NadekoBot in the background with auto restart\" \
                    \nbrew upgrade youtube-dl \
                    \n \
                    \nsleep 5 \
                    \ncd $root_dir/NadekoBot \
                    \n$(which dotnet) restore && $(which dotnet) build -c Release \
                    \n \
                    \nwhile true; do \
                    \n    cd $root_dir/NadekoBot/src/NadekoBot && \
                    \n    $(which dotnet) run -c Release \
                    \n \
                    \n    brew upgrade youtube-dl \
                    \n    sleep 10 \
                    \ndone" > NadekoRun.sh
            fi

            # Starting or restarting '$nadeko_service_name'
            if [[ $nadeko_service_status = "active" ]]; then
                echo "Restarting '$nadeko_service_name'..."
                sudo systemctl restart $nadeko_service_name || {
                    echo "${red}Failed to restart '$nadeko_service_name'${nc}" >&2
                    read -p "Press [Enter] to return to the installer menu"
                    clean_exit "1" "Exiting"
                }
                echo "Waiting 60 seconds for '$nadeko_service_name' to restart..."
            else
                echo "Starting '$nadeko_service_name'..."
                sudo systemctl start $nadeko_service_name || {
                    echo "${red}Failed to start '$nadeko_service_name'${nc}" >&2
                    read -p "Press [Enter] to return to the installer menu"
                    clean_exit "1" "Exiting"
                }
                echo "Waiting 60 seconds for '$nadeko_service_name' to start..."
            fi

            # Waits in order to give '$nadeko_service_name' enough time to (re)start
            while ((timer > 0)); do
                echo -en "${clrln}${timer} seconds left"
                sleep 1
                ((timer-=1))
            done

            # Note: $no_hostname is purposefully unquoted. Do not quote those variables.
            echo -e "\n\n-------- $nadeko_service_name startup logs ---------" \
                "\n$(journalctl -q -u nadeko -b $no_hostname -S "$start_time")" \
                "\n--------- End of $nadeko_service_name startup logs --------\n"

            echo -e "${cyan}Please check the logs above to make sure that there aren't any" \
                "errors, and if there are, to resolve whatever issue is causing them\n"

            echo "${green}NadekoBot is now running in the background${nc}"
            read -p "Press [Enter] to return to the installer menu"

        }
    fi

#
################################################################################
#
# [ Main ]
#
################################################################################
#
    echo -e "Welcome to the NadekoBot installer\n"

    while true; do
        # E.1. Creates '$nadeko_service_name', if it does not exist
        if [[ ! -f $nadeko_service ]]; then
            echo "Creating '$nadeko_service_name'..."
            if [[ $distro = "Darwin" && ! -d /Users/$USER/Library/LaunchAgents/ ]]; then
                # TODO: Add error catching
                mkdir /Users/"$USER"/Library/LaunchAgents
            fi
            echo -e "$nadeko_service_content" | sudo tee "$nadeko_service" &>/dev/null &&
                if [[ $distro != "Darwin" ]]; then 
                    sudo systemctl daemon-reload
                else
                    sudo chown "$USER":staff "$nadeko_service"
                fi || {
                    echo "${red}Failed to create '$nadeko_service_name'" >&2
                    echo "${cyan}This service must exist for nadeko to work${nc}"
                    clean_exit "1" "Exiting"
                }
        fi

        service_actions "nadeko_service_status"

        ########################################################################
        # User options for starting nadeko
        ########################################################################
        if (! hash git || ! hash dotnet) &>/dev/null; then
            echo "${grey}1. Download NadekoBot (Disabled until option 5 is ran)${nc}"
            disabled_1=true
        else
            echo "1. Download NadekoBot"
            disabled_1=false
        fi

        if [[ ! -d NadekoBot/src/NadekoBot/ || ! -f NadekoBot/src/NadekoBot/credentials.json ||
                ! -d NadekoBot/src/NadekoBot/bin/Release || -z $(jq -r ".Token" NadekoBot/src/NadekoBot/credentials.json) ]] || 
                (! hash git || ! hash dotnet || ! hash jq) &>/dev/null; then
            echo "${grey}2. Run NadekoBot in the background (Disabled until option" \
                "1,5, and 6 is ran)${nc}"
            echo "${grey}3. Run NadekoBot in the background with auto restart (Disabled" \
                "until option 1,5, and 6 is ran)${nc}"
            disabled_23=true
        else
            if [[ $nadeko_service_status = "active" ]]; then
                run_mode_status=" ${green}(Running in this mode)${nc}"
            elif [[ $nadeko_service_status = "inactive" ]]; then
                run_mode_status=" ${yellow}(Set up to run in this mode)${nc}"
            else
                run_mode_status=" ${yellow}(Status unkown)${nc}"
            fi
            
            if [[ $(grep '_code_name_="NadekoRunARU"' NadekoRun.sh) ]]; then
                echo "2. Run NadekoBot in the background"
                echo "3. Run NadekoBot in the background with auto restart"
            elif [[ $(grep '_code_name_="NadekoRunAR"' NadekoRun.sh) ]]; then
                echo "2. Run NadekoBot in the background"
                echo "3. Run NadekoBot in the background with auto restart${run_mode_status}"
            elif [[ $(grep '_code_name_="NadekoRun"' NadekoRun.sh) ]]; then
                echo "2. Run NadekoBot in the background${run_mode_status}"
                echo "3. Run NadekoBot in the background with auto restart"
            else
                echo "2. Run NadekoBot in the background"
                echo "3. Run NadekoBot in the background with auto restart"
            fi

            disabled_23=false
        fi

        echo "4. Stop NadekoBot"
        echo "5. Install prerequisites"

        if [[ ! -d NadekoBot/src/NadekoBot/ ]]; then
            echo "${grey}6. Set up credentials.json (Disabled until option 1 is ran)${nc}"
            disabled_6=true
        else
            echo "6. Set up credentials.json"
            disabled_6=false
        fi

        echo "7. Exit"
        read choice
        case "$choice" in
        1)
            clear -x
            if [[ $disabled_1 = true ]]; then
                echo "${red}Option 1 is currently disabled${nc}"
                continue
            fi
            export nadeko_service
            export -f service_actions
            export nadeko_service_name
            export nadeko_service_status
            export nadeko_service_content
            curl -s https://raw.githubusercontent.com/"$installer_repo"/"$installer_branch"/nadeko_latest_installer.sh \
                    -o nadeko_latest_installer.sh || {
                echo "${red}Failed to download latest 'nadeko_latest_installer.sh'...${nc}" >&2
                clean_exit "1" "Exiting" "true"
            }
            printf "We will now download/update NadekoBot. "
            read -p "Press [Enter] to begin."
            sudo chmod +x nadeko_latest_installer.sh && ./nadeko_latest_installer.sh
            exec "$installer_prep"
            ;;
        2)
            clear -x
            if [[ $disabled_23 = true ]]; then
                echo "${red}Option 2 is currently disabled${nc}"
                continue
            fi
            printf "We will now run NadekoBot in the background. "
            read -p "Press [Enter] to begin."
            nadeko_starter "2"
            clear -x
            ;;
        3)
            clear -x
            if [[ $disabled_23 = true ]]; then
                echo "${red}Option 3 is currently disabled${nc}"
                continue
            fi
            printf "We will now run NadekoBot in the background with auto restart. "
            read -p "Press [Enter] to begin."
            nadeko_starter "3"
            clear -x
            ;;
        4)
            clear -x
            printf "We will now stop NadekoBot. "
            read -p "Press [Enter] to begin."
            service_actions "stop_service" "true"
            read -p "Press [Enter] to return to the installer menu"
            clear -x
            ;;
        5)
            clear -x
            curl -s https://raw.githubusercontent.com/"$installer_repo"/"$installer_branch"/"$prereqs_installer" \
                    -o prereqs_installer.sh || {
                echo "${red}Failed to download latest 'prereqs_installer.sh'...${nc}" >&2
                clean_exit "1" "Exiting" "true"
            }
            sudo chmod +x prereqs_installer.sh && ./prereqs_installer.sh
            clear -x
            ;;
        6)
            clear -x
            if [[ $disabled_6 = true ]]; then
                echo "${red}Option 6 is currently disabled${nc}"
                continue
            fi
            export nadeko_service_name
            export nadeko_service_status
            curl -s https://raw.githubusercontent.com/"$installer_repo"/"$installer_branch"/credentials_setup.sh \
                    -o credentials_setup.sh || {
                echo "${red}Failed to download latest 'credentials_setup.sh'...${nc}" >&2
                clean_exit "1" "Exiting" "true"
            }
            sudo chmod +x credentials_setup.sh && ./credentials_setup.sh
            clear -x
            ;;
        7)
            clean_exit "0" "Exiting"
            ;;
        *)
            clear -x
            echo "${red}Invalid input: '$choice' is not a valid option${nc}" >&2
            ;;
        esac
    done
