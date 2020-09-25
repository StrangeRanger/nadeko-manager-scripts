#!/bin/bash

################################################################################
#
# The master/main installer script for macOS and Linux Distributions
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
# Global [ variables ]
#
################################################################################
#	
	if [[ $distro != "Darwin" ]]; then
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
	else
		nadeko_service="/Users/$USER/Library/LaunchAgents/bot.nadeko.Nadeko.plist"
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
			\n		<string>$root_dir/NadekoRun.sh</string> \
			\n	</array> \
			\n	<key>RunAtLoad</key> \
			\n	<true/> \
			\n	<key>StandardErrorPath</key> \
			\n	<string>$root_dir/.bot.nadeko.Nadeko.stderr</string> \
			\n	<key>StandardOutPath</key> \
			\n	<string>$root_dir/.bot.nadeko.Nadeko.stdout</string> \
			\n</dict> \
			\n</plist>"
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
		# TODO: Numerics for $nadeko_service_status like $nadeko_service_startup???
        nadeko_service_status=$(systemctl is-active nadeko.service)
        nadeko_service_startup=$(systemctl is-enabled --quiet nadeko.service \
            2>/dev/null; echo $?)

		 # E.1. Creates 'nadeko.service', if it does not exist
        if [[ ! -f $nadeko_service ]]; then
            echo "Creating 'nadeko.service'..."
            echo -e "$nadeko_service_content" | sudo tee "$nadeko_service" > /dev/null || {
                echo "${red}Failed to create 'nadeko.service'" >&2
                echo "${cyan}This service must exist for nadeko to work${nc}"
                clean_exit "1" "Exiting"
            }
            # Reloads systemd daemons to account for the added service
            sudo systemctl daemon-reload
        fi

		########################################################################
        # User options for starting nadeko
        ########################################################################
		if (! hash git || ! hash dotnet) &>/dev/null; then
			echo "1. Download NadekoBot ${red}(Disabled until prerequisites are installed)${nc}"
			disabled_1="true"
		else
			echo "1. Download NadekoBot"
			disabled_1="false"
		fi
		
		if [[ ! -d NadekoBot/src/NadekoBot/ || ! -f NadekoBot/src/NadekoBot/credentials.json ]] || 
				(! hash git || ! hash dotnet) &>/dev/null; then
			echo "2. Run Nadeko in the background ${red}(Disabled until credentials.json," \
				"Nadeko, and prerequisites are installed)${nc}"
			echo "3. Run Nadeko in the background with auto-restart ${red}(Disabled until" \
				"credentials.json, Nadeko, and prerequisites are installed)${nc}"
			echo "4. Run Nadeko in the background with auto-restart and auto-update" \
				"${red}(Disabled until credentials.json, Nadeko, and prerequisites are installed)${nc}"
			disabled_234="true"
		else
			echo "2. Run Nadeko in the background"
			echo "3. Run Nadeko in the background with auto-restart"
			echo "4. Run Nadeko in the background with auto-restart and auto-update"
			disabled_234="false"
		fi

		if [[ $distro = "Darwin" ]]; then
			echo "5. Install prerequisites ${red}(Disabled due to being run on macOS)${nc}"
			disabled_5="true"
		else
			echo "5. Install prerequisites"
			disabled_5="false"
		fi

		if [[ ! -d NadekoBot/src/NadekoBot/ ]]; then
			echo "6. Set up credentials.json ${red}(Disabled until Nadeko hash been downloaded)${nc}"
			disabled_6="true"
		else
			echo "6. Set up credentials.json"
			disabled_6="false"
		fi

		echo "7. Exit"
		read choice
        case "$choice" in
			1)
				clear -x
				if [[ $disabled_1 = "true" ]]; then
					echo "${red}Option 1 is currently disabled${nc}"
					continue
				fi
				export nadeko_service
                export nadeko_service_content
				wget -qN https://raw.githubusercontent.com/"$installer_repo"/"$installer_branch"/nadeko_installer_latest.sh
				sudo chmod +x nadeko_installer_latest.sh && ./nadeko_installer_latest.sh
				exec "$installer_prep"
				;;
			2)
				clear -x
				if [[ $disabled_234 = "true" ]]; then
					echo "${red}Option 2 is currently disabled${nc}"
					continue
				fi
				export nadeko_service_status
                export nadeko_service_startup
				wget -qN https://raw.githubusercontent.com/"$installer_repo"/"$installer_branch"/NadekoB.sh
				sudo chmod +x NadekoB.sh && ./NadekoB.sh
				clear -x
				;;
			3)
				clear -x
				if [[ $disabled_234 = "true" ]]; then
					echo "${red}Option 3 is currently disabled${nc}"
					continue
				fi
				export nadeko_service_status
                export nadeko_service_startup
				wget -qN https://raw.githubusercontent.com/"$installer_repo"/"$installer_branch"/NadekoARB.sh
				sudo chmod +x NadekoARB.sh && ./NadekoARB.sh
				clear -x
				;;
			4)
				clear -x
				if [[ $disabled_234 = "true" ]]; then
					echo "${red}Option 4 is currently disabled${nc}"
					continue
				fi
				export nadeko_service_status
                export nadeko_service_startup
				wget -qN https://raw.githubusercontent.com/"$installer_repo"/"$installer_branch"/NadekoARBU.sh
				sudo chmod +x NadekoARBU.sh && ./NadekoARBU.sh
				clear -x
				;;
			5)
				clear -x
				if [[ $disabled_5 = "true" ]]; then
					echo "${red}Option 5 is currently disabled${nc}"
					continue
				fi
				wget -qN https://raw.githubusercontent.com/"$installer_repo"/"$installer_branch"/prereqs_installer.sh
				sudo chmod +x prereqs_installer.sh && ./prereqs_installer.sh
				clear -x
				;;
			6)
				clear -x
				if [[ $disabled_6 = "true" ]]; then
					echo "${red}Option 6 is currently disabled${nc}"
					continue
				fi
				export nadeko_service_status
                export nadeko_service_startup
				wget -qN https://raw.githubusercontent.com/"$installer_repo"/"$installer_branch"/credentials_setup.sh
				sudo chmod +x credentials_setup.sh && ./credentials_setup.sh
				clear -x
				;;
			7)
				clean_exit "0" "Exiting"
				;;
			*)
				clear -x
				echo "${red}Invalid input: '$choice' is not a valid" \
					"option${nc}" >&2
				;;
		esac
	done
