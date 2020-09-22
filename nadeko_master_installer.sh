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
		echo "1. Download NadekoBot"
		echo "2. Run Nadeko (Normally)"
		echo "3. Run Nadeko with Auto Restart in this session"
		echo "4. Auto-Install Prerequisites (For Ubuntu, Debian and CentOS)"
		echo "5. Set up credentials.json (If you have downloaded NadekoBot already)"
		echo "6. Auto-Install pm2 (For pm2 information, see README!)"
		echo "7. Start Nadeko in pm2 (Complete option 6 first!)"
		echo "8. Exit"
		read -p "Choose [1] to Download, [2 or 3] to Run, [6 and 7] for pm2 setup/startup (see README) or [8] to Exit. " choice
		case "$choice" in
			1)
				clear -x
				wget -qN https://raw.githubusercontent.com/"$installer_repo"/"$installer_branch"/nadeko_installer_latest.sh
				chmod +x nadeko_installer_latest.sh && ./nadeko_installer_latest.sh
				clear -x
				;;
			2)
				clear -x
				wget -qN https://raw.githubusercontent.com/"$installer_repo"/"$installer_branch"/nadeko_run.sh
				chmod +x nadeko_run.sh && ./nadeko_run.sh
				clear -x
				;;
			3)
				clear -x
				wget -qN https://raw.githubusercontent.com/"$installer_repo"/"$installer_branch"/NadekoAutoRestartAndUpdate.sh
				chmod +x NadekoAutoRestartAndUpdate.sh && ./NadekoAutoRestartAndUpdate.sh
				clear -x
				;;
			4)
				clear -x
				wget -qN https://raw.githubusercontent.com/"$installer_repo"/"$installer_branch"/nadekoautoinstaller.sh
				chmod +x nadekoautoinstaller.sh && ./nadekoautoinstaller.sh
				clear -x
				;;
			5)
				clear -x
				wget -qN https://raw.githubusercontent.com/"$installer_repo"/"$installer_branch"/credentials_setup.sh
				chmod +x credentials_setup.sh && ./credentials_setup
				clear -x
				;;
			6)
				clear -x
				wget -N https://github.com/Kwoth/NadekoBot-BashScript/raw/1.9/nadekopm2setup.sh
				chmod +x nadekopm2setup.sh && ./nadekopm2setup.sh
				clear -x	
				;;
			7)
				clear -x
				wget -N https://github.com/Kwoth/NadekoBot-BashScript/raw/1.9/nadekobotpm2start.sh
				chmod +x nadekobotpm2start.sh && ./nadekobotpm2start.sh
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
