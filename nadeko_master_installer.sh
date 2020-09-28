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
    export sub_master_installer_pid=$$

#
################################################################################
#
# ??????????????? # TODO: privide description
#
################################################################################
#
    # Variables use when executed on 'macOS'
    if [[ $distro != "Darwin" ]]; then
        ########################################################################
        # Function
        ########################################################################
        service_actions() {
            case "$1" in
                nadeko_service_status)
                    nadeko_service_status=$(systemctl is-active nadeko.service)
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

        ########################################################################
        # Other variables
        ########################################################################
        nadeko_service="/lib/systemd/system/nadeko.service"
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
    # Variables use when executed on 'Linux Distributions'
    else
        ########################################################################
        # Function
        ########################################################################
        service_actions() {
            case "$1" in
                nadeko_service_status)
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

        ########################################################################
        # Other variables
        ########################################################################
        nadeko_service="/Users/$USER/Library/LaunchAgents/bot.nadeko.Nadeko.plist"
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

        # E.1. Creates '$nadeko_service_name', if it does not exist
        if [[ ! -f $nadeko_service ]]; then
            # Usually only occures if the mac was just set up
            if [[ ! -d /Users/$USER/Library/LaunchAgents/ ]]; then
                echo "Creating '/Users/$USER/Library/LaunchAgents/'..."
                mkdir /Users/$USER/Library/LaunchAgents || {
                    echo "${red}Failed to create '/Users/$USER/Library/LaunchAgents'${nc}" >&2
                    clean_exit "1" "Exiting" "true"
                }
            fi

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

        if [[ ! -d NadekoBot/src/NadekoBot/ || ! -f NadekoBot/src/NadekoBot/credentials.json ]] ||
            (! hash git || ! hash dotnet) &>/dev/null; then
            echo "2. Run Nadeko in the background ${red}(Disabled until credentials.json," \
                "Nadeko, and prerequisites are installed)${nc}"
            echo "3. Run Nadeko in the background with auto-restart ${red}(Disabled" \
                "until credentials.json, Nadeko, and prerequisites are installed)${nc}"
            echo "4. Run Nadeko in the background with auto-restart and auto-update" \
                "${red}(Disabled until credentials.json, Nadeko, and prerequisites" \
                "are installed)${nc}"
            disabled_234=true
        else
            echo "2. Run Nadeko in the background"
            echo "3. Run Nadeko in the background with auto-restart"
            echo "4. Run Nadeko in the background with auto-restart and auto-update"
            disabled_234=false
        fi

        if [[ $distro = "Darwin" ]]; then
            echo "5. Install prerequisites ${red}(Disabled due to being run on macOS)${nc}"
            disabled_5=true
        else
            echo "5. Install prerequisites"
            disabled_5=false
        fi

        if [[ ! -d NadekoBot/src/NadekoBot/ ]]; then
            echo "6. Set up credentials.json ${red}(Disabled until Nadeko hash" \
                "been downloaded)${nc}"
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
            export nadeko_service_status
            export nadeko_service_content
            curl -s https://raw.githubusercontent.com/"$installer_repo"/"$installer_branch"/nadeko_installer_latest.sh \
                    -o nadeko_installer_latest.sh || {
                echo "${red}Failed to download latest 'nadeko_installer_latest.sh'...${nc}" >&2
                clean_exit "1" "Exiting" "true"
            }
            sudo chmod +x nadeko_installer_latest.sh && ./nadeko_installer_latest.sh
            exec "$installer_prep"
            ;;
        2)
            clear -x
            if [[ $disabled_234 = true ]]; then
                echo "${red}Option 2 is currently disabled${nc}"
                continue
            fi
            export nadeko_service_status
            curl -s https://raw.githubusercontent.com/"$installer_repo"/"$installer_branch"/NadekoB.sh \
                    -o NadekoB.sh || {
                echo "${red}Failed to download latest 'NadekoB.sh'...${nc}" >&2
                clean_exit "1" "Exiting" "true"
            }
            sudo chmod +x NadekoB.sh && ./NadekoB.sh
            clear -x
            ;;
        3)
            clear -x
            if [[ $disabled_234 = true ]]; then
                echo "${red}Option 3 is currently disabled${nc}"
                continue
            fi
            export nadeko_service_status
            curl -s https://raw.githubusercontent.com/"$installer_repo"/"$installer_branch"/NadekoARB.sh \
                    -o NadekoARB.sh || {
                echo "${red}Failed to download latest 'NadekoARB.sh'...${nc}" >&2
                clean_exit "1" "Exiting" "true"
            }
            sudo chmod +x NadekoARB.sh && ./NadekoARB.sh
            clear -x
            ;;
        4)
            clear -x
            if [[ $disabled_234 = true ]]; then
                echo "${red}Option 4 is currently disabled${nc}"
                continue
            fi
            export nadeko_service_status
            curl -s https://raw.githubusercontent.com/"$installer_repo"/"$installer_branch"/NadekoARBU.sh \
                    -o NadekoARBU.sh || {
                echo "${red}Failed to download latest 'NadekoARBU.sh'...${nc}" >&2
                clean_exit "1" "Exiting" "true"
            }
            sudo chmod +x NadekoARBU.sh && ./NadekoARBU.sh
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
