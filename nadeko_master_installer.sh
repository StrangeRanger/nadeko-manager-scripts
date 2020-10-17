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
        nadeko_service_content="[Unit] \
            \nDescription=Nadeko \
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
        nadeko_arr="#!/bin/bash \
            \n \
            \necho \"\" \
            \necho \"Running NadekoBot with auto-restart\" \
            \nyoutube-dl -U \
            \n \
            \nsleep 5s \
            \ncd $root_dir/Nadeko/NadekoBot \
            \ndotnet restore && dotnet build -c Release \
            \n \
            \nwhile true; do cd $root_dir/Nadeko/NadekoBot/src/NadekoBot && dotnet run -c Release && youtube-dl -U; sleep 5s; done"
        nadeko_arrl="" # CURRENTLY NOT WORKING/DISABLED

        #-------------------------------
        # Function
        #-------------------------------
        service_actions() {
            case "$1" in
                nadeko_service_status)
                    nadeko_service_status=$(systemctl is-active nadeko.service)
                    ;;
                nadeko_service_enabled)
                    nadeko_service_enabled=$(systemctl is-enabled nadeko.service \
                        2>/dev/null; echo $?)
                    ;;
                stop_service)
                    sudo systemctl stop nadeko.service || {
                        echo "${red}Failed to stop 'nadeko.service'" >&2
                        echo "${cyan}You will need to restart 'nadeko.service'" \
                            "to apply any updates to Nadeko${nc}"
                    }
                ;;
            esac
        }

        nadeko_starter() {
            nadeko_service_status=$(systemctl is-active nadeko.service)
            nadeko_service_enabled=$(systemctl is-enabled nadeko.service \
                        &>/dev/null; echo $?)
            timer=60

            # Saves the current time and date, which will be used with journalctl
            start_time=$(date +"%F %H:%M:%S")

            # Disables 'nadeko.service' if enabled
            if [[ $nadeko_service_enabled = 0 ]]; then
                echo "Disabling 'nadeko.service'..."
                systemctl disable nadeko.service || {
                    echo "${red}Failed to disable 'nadeko.service'" >&2
                    echo "${cyan}This service must be disabled in order to use this" \
                        "run mode${nc}"
                    read -p "Press [Enter] to return to the installer menu"
                    clean_exit "1" "Exiting"
                }
            fi

            if [[ -f NadekoRun.sh ]]; then
                echo "Updating 'NadekoRun.sh'..."
            else
                echo "Creating 'NadekoRun.sh'..."
                touch NadekoRun.sh
                chmod +x NadekoRun.sh
            fi
            echo -e "#!bin/bash \
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

            # Starting or restarting 'nadeko.service'
            if [[ $nadeko_service_status = "active" ]]; then
                echo "Restarting 'nadeko.service'..."
                systemctl restart nadeko.service || {
                    echo "${red}Failed to restart 'nadeko.service'${nc}" >&2
                    read -p "Press [Enter] to return to the installer menu"
                    clean_exit "1" "Exiting"
                }
                echo "Waiting 60 seconds for 'nadeko.service' to restart..."
            else
                echo "Starting 'nadeko.service'..."
                systemctl start nadeko.service || {
                    echo "${red}Failed to start 'nadeko.service'${nc}" >&2
                    read -p "Press [Enter] to return to the installer menu"
                    clean_exit "1" "Exiting"
                }
                echo "Waiting 60 seconds for 'nadeko.service' to start..."
            fi

            # Waits in order to give 'nadeko.service' enough time to (re)start
            while ((timer > 0)); do
                echo -en "${clrln}${timer} seconds left"
                sleep 1
                ((timer-=1))
            done

            # Note: $no_hostname is purposefully unquoted. Do not quote those variables.
            echo -e "\n\n-------- nadeko.service startup logs ---------" \
                "\n$(journalctl -u nadeko -b $no_hostname -S "$start_time")" \
                "\n--------- End of nadeko.service startup logs --------\n"

            echo -e "${cyan}Please check the logs above to make sure that there aren't any" \
                "errors, and if there are, to resolve whatever issue is causing them\n"

            echo "${green}NadekoBot is now running in the background${nc}"
            read -p "Press [Enter] to return to the installer menu"

        }
        
        nadeko_rstarter() {
            nadeko_service_status=$(systemctl is-active nadeko.service)


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
        nadeko_service_content=("<?xml version=\"1.0\" encoding=\"UTF-8\"?> \
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
            \n		<string>$root_dir/NadekoRun.sh</string> \
            \n	</array> \
            \n	<key>RunAtLoad</key> \
            \n	<true/> \
            \n	<key>StandardErrorPath</key> \
            \n	<string>$root_dir/.bot.nadeko.Nadeko.stderr</string> \
            \n	<key>StandardOutPath</key> \
            \n	<string>$root_dir/.bot.nadeko.Nadeko.stdout</string> \
            \n</dict> \
            \n</plist>")
        #nadeko_run=""
        #nadeko_arr=""
        #nadeko_arrl="" # CURRENTLY NOT WORKING/DISABLED

        #-------------------------------
        # Function
        #-------------------------------
        service_actions() {
            case "$1" in
                nadeko_service_status)
                    launchctl load /Users/$USER/Library/LaunchAgents/bot.nadeko.Nadeko.plist 2>/dev/null
                    nadeko_service_status=$(launchctl print gui/$UID/bot.nadeko.Nadeko | grep "state") &&
                    nadeko_service_status=${nadeko_service_status/[[:blank:]]state = /} || {
                        nadeko_service_status="inactive"
                    }
                    ;;
                stop_service)
                    launchctl stop bot.nadeko.Nadeko || {
                        echo "${red}Failed to stop 'bot.nadeko.Nadeko'" >&2
                        echo "${cyan}You will need to restart 'bot.nadeko.Nadeko'" \
                            "to apply any updates to Nadeko${nc}"
                    }
                    ;;
            esac
        }
    fi

#
################################################################################
#
# [ Main ]
#
################################################################################
#
    echo -e "Welcome to NadekoBot\n"

    while true; do
        service_actions "nadeko_service_status"
        service_actions "nadeko_service_enabled"

        # E.1. Creates '$nadeko_service_name', if it does not exist
        if [[ ! -f $nadeko_service ]]; then
            echo "Creating '$nadeko_service_name'..."
            echo -e "$nadeko_service_content" | sudo tee "$nadeko_service" >/dev/null &&
            if [[ $distro != "Darwin" ]]; then sudo systemctl daemon-reload; fi || {
                echo "${red}Failed to create '$nadeko_service_name'" >&2
                echo "${cyan}This service must exist for nadeko to work${nc}"
                clean_exit "1" "Exiting"
            }
        fi

        ########################################################################
        # User options for starting nadeko
        ########################################################################
        if (! hash git || ! hash dotnet) &>/dev/null; then
            echo "1. Download NadekoBot ${red}(Disabled until prerequisites are installed)${nc}"
            disabled_1=true
        else
            echo "1. Download NadekoBot"
            disabled_1=false
        fi

        if [[ ! -d NadekoBot/src/NadekoBot/ || ! -f NadekoBot/src/NadekoBot/credentials.json ||
                ! -d NadekoBot/src/NadekoBot/bin/Release || -z $(jq -r ".Token"
                NadekoBot/src/NadekoBot/credentials.json) ]] || (! hash git ||
                ! hash dotnet || ! hash jq) &>/dev/null; then
            if [[ -z $(jq -r ".Token" NadekoBot/src/NadekoBot/credentials.json) ]]; then
                disable_code=2
            else
                disable_code=1
            fi
            echo "2. Run Nadeko in the background ${red}(Disabled | $disable_code)${nc}"
            echo "3. Run Nadeko in the background with auto-restart ${red}(Disabled" \
                "| $disable_code)${nc}"
            echo "4. Run Nadeko in the background with auto-restart and auto-update" \
                "${red}(Disabled | $disable_code)${nc}"
            disabled_234=true
        else
            echo "2. Run Nadeko in the background"
            echo "3. Run Nadeko in the background with auto-restart"
            echo "4. Run Nadeko in the background with auto-restart and auto-update"
            disabled_234=false
        fi

        if [[ $distro = "Darwin" ]]; then
            echo "5. Install prerequisites ${red}(Disabled | 4)${nc}"
            disabled_5=true
        else
            echo "5. Install prerequisites"
            disabled_5=false
        fi

        if [[ ! -d NadekoBot/src/NadekoBot/ ]]; then
            echo "6. Set up credentials.json ${red}(Disabled | 3)${nc}"
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
            curl -s https://raw.githubusercontent.com/"$installer_repo"/"$installer_branch"/nadeko_installer_latest.sh \
                    -o nadeko_installer_latest.sh || {
                echo "${red}Failed to download latest 'nadeko_installer_latest.sh'...${nc}" >&2
                clean_exit "1" "Exiting" "true"
            }
            printf "We will now download/update Nadeko. "
            read -p "Press [Enter] to begin."
            sudo chmod +x nadeko_installer_latest.sh && ./nadeko_installer_latest.sh
            exec "$installer_prep"
            ;;
        2)
            clear -x
            if [[ $disabled_234 = true ]]; then
                echo "${red}Option 2 is currently disabled${nc}"
                continue
            fi
            printf "We will now run NadekoBot in the background. "
            read -p "Press [Enter] to begin."
            nadeko_starter

            clear -x
            ;;
        3)
            clear -x
            if [[ $disabled_234 = true ]]; then
                echo "${red}Option 3 is currently disabled${nc}"
                continue
            fi
            printf "We will now run NadekoBot in the background with auto restart. "
            read -p "Press [Enter] to begin."
            nadeko_rstarter

            clear -x
            ;;
        4)
            clear -x
            #if [[ $disabled_234 = true ]]; then
                echo "${red}Option 4 is currently disabled${nc}"
                continue
            #fi
            clear -x
            ;;
        5)
            clear -x
            if [[ $disabled_5 = true ]]; then
                echo "${red}Option 5 is currently disabled${nc}"
                continue
            fi
            curl -s https://raw.githubusercontent.com/"$installer_repo"/"$installer_branch"/prereqs_installer.sh \
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
                echo "${red}Failed to download latest 'nadeko_installer_latest.sh'...${nc}" >&2
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
