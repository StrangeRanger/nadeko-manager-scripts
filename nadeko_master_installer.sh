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
			echo "2. Run Nadeko (Normally) ${red}(Disabled until credentials.json, Nadeko, and prerequisites are installed)${nc}"
			echo "3. Run Nadeko with Auto Restart in this session ${red}(Disabled until credentials.json, Nadeko, and prerequisites are installed)${nc}"
			disabled_23="true"
		else
			echo "2. Run Nadeko (Normally)"
			echo "3. Run Nadeko with Auto Restart in this session"
			disabled_23="false"
		fi

		if [[ $distro = "Darwin" ]]; then
			echo "4. Install prerequisites ${red}(Disabled due to being run on macOS)${nc}"
			disabled_4="true"
		else
			echo "4. Install prerequisites"
			disabled_4="false"
		fi

		if [[ ! -d NadekoBot/src/NadekoBot/ ]]; then
			echo "5. Set up credentials.json ${red}(Disabled until Nadeko hash been downloaded)${nc}"
			disabled_5="true"
		else
			echo "5. Set up credentials.json"
			disabled_5="false"
		fi

		echo "6. Install pm2"
		
		if [[ ! -d NadekoBot/src/NadekoBot/ || ! -f NadekoBot/src/NadekoBot/credentials.json ]] || (! hash git || ! hash dotnet || ! hash node || ! hash pm2) &>/dev/null; then
			echo "7. Start Nadeko in pm2 ${red}(Disabled until credentials.json, Nadeko, and pm2 are installed)${nc}"
			disabled_7="true"
		else
			echo "7. Start Nadeko in pm2"
			disabled_7="false"
		fi

		echo "8. Exit"
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
				if [[ $disabled_23 = "true" ]]; then
					echo "${red}Option 2 is currently disabled${nc}"
					continue
				fi
				wget -qN https://raw.githubusercontent.com/"$installer_repo"/"$installer_branch"/nadeko_run.sh
				sudo chmod +x nadeko_run.sh && ./nadeko_run.sh
				clear -x
				;;
			3)
				clear -x
				if [[ $disabled_23 = "true" ]]; then
					echo "${red}Option 3 is currently disabled${nc}"
					continue
				fi
				wget -qN https://raw.githubusercontent.com/"$installer_repo"/"$installer_branch"/NadekoAutoRestartAndUpdate.sh
				sudo chmod +x NadekoAutoRestartAndUpdate.sh && ./NadekoAutoRestartAndUpdate.sh
				clear -x
				;;
			4)
				clear -x
				if [[ $disabled_4 = "true" ]]; then
					echo "${red}Option 4 is currently disabled${nc}"
					continue
				fi
				wget -qN https://raw.githubusercontent.com/"$installer_repo"/"$installer_branch"/nadekoautoinstaller.sh
				sudo chmod +x nadekoautoinstaller.sh && ./nadekoautoinstaller.sh
				clear -x
				;;
			5)
				clear -x
				if [[ $disabled_5 = "true" ]]; then
					echo "${red}Option 5 is currently disabled${nc}"
					continue
				fi
				wget -qN https://raw.githubusercontent.com/"$installer_repo"/"$installer_branch"/credentials_setup.sh
				sudo chmod +x credentials_setup.sh && ./credentials_setup.sh
				clear -x
				;;
			6)
				clear -x
				read -p "We will now setup pm2. Press [Enter] to continue."
	
				echo "Installing node/npm..."
				curl -sL https://deb.nodesource.com/setup_14.x | sudo -E bash -
				sudo apt-get install -y nodejs
				sudo apt-get install -y build-essential

				sudo npm install -g npm
				echo "Installing pm2..."
				sudo npm install -g pm2

				read -p "Press [Enter] to return to the installer menu"
				clear -x	
				;;
			7)
				clear -x
				if [[ $disabled_7 = "true" ]]; then
					echo "${red}Option 7 is currently disabled${nc}"
					continue
				fi
				wget -N https://github.com/Kwoth/NadekoBot-BashScript/raw/1.9/nadekobotpm2start.sh
				sudo chmod +x nadekobotpm2start.sh
				./nadekobotpm2start.sh
				clear -x
				;;
			8)
				clean_exit "0" "Exiting"
				;;
			*)
				clear -x
				echo "${red}Invalid input: '$option' is not a valid" \
					"option${nc}" >&2
				;;
		esac
	done
