#!/bin/bash

################################################################################
#
# TODO: Add a file description
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
# [ Main ]
#
################################################################################
#
	echo "Welcome to NadekoBot."
	echo ""

	while true; do
		if (! hash git || ! hash dotnet) &>/dev/null; then
			echo "1. Download NadekoBot ${red}(Disabled until prerequisites are installed)${nc}"
			disabled_1="true"
		else
			echo "1. Download NadekoBot"
			disabled_1="false"
		fi
		
		if [[ ! -d NadekoBot/src/NadekoBot/ || ! -f NadekoBot/src/NadekoBot/credentials.json ]] || (! hash git || ! hash dotnet) &>/dev/null; then
			echo "2. Run Nadeko in the background ${red}(Disabled until credentials.json, Nadeko, and prerequisites are installed)${nc}"
			echo "3. Run Nadeko in the background with auto-restart ${red}(Disabled until credentials.json, Nadeko, and prerequisites are installed)${nc}"
			echo "4. Run Nadeko in the background with auto-restart and auto-update ${red}(Disabled until credentials.json, Nadeko, and prerequisites are installed)${nc}"
			disabled_234="true"
		else
			echo "2. Run Nadeko in the background"
			echo "3. Run Nadeko in the background with auto-restart"
			echo "4. Run Nadeko in the background with auto-restart and auto-update "
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
		read -p "Choose [1] to Download, [2 or 3] to Run, [6 and 7] for pm2 setup/startup (see README) or [8] to Exit. " choice
		case "$choice" in
			1)
				clear -x
				if [[ $disabled_1 = "true" ]]; then
					echo "${red}Option 1 is currently disabled${nc}"
					continue
				fi
				wget -qN https://raw.githubusercontent.com/"$installer_repo"/"$installer_branch"/nadeko_installer_latest.sh
				sudo chmod +x nadeko_installer_latest.sh && ./nadeko_installer_latest.sh
				clear -x
				;;
			2)
				clear -x
				if [[ $disabled_234 = "true" ]]; then
					echo "${red}Option 2 is currently disabled${nc}"
					continue
				fi
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
				wget -qN https://raw.githubusercontent.com/"$installer_repo"/"$installer_branch"/credentials_setup.sh
				sudo chmod +x credentials_setup.sh && ./credentials_setup.sh
				clear -x
				;;
			7)
				clean_exit "0" "Exiting"
				;;
			*)
				clear -x
				echo "${red}Invalid input: '$option' is not a valid" \
					"option${nc}" >&2
				;;
		esac
	done
