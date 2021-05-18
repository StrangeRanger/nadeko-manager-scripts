#!/bin/bash
#
# Downloads and updates NadekoBot.
#
# NOTE: All variables not defined in this script, are exported from 'linuxAIO.sh',
# 'installer_prep.sh', and 'linux_master_installer.sh'.
#
########################################################################################
#### [ Variables ]


# TODO: Put in master installer file and export them?
bak_credentials="NadekoBot.bak/src/NadekoBot/credentials.json"
new_credentials="NadekoBot/src/NadekoBot/credentials.json"
bak_database="NadekoBot.bak/src/NadekoBot/bin/"
new_database="NadekoBot/src/NadekoBot/bin/"
notcoreapp_version="netcoreapp3.1"


#### End of [ Variables ]
########################################################################################
#### [ Functions ]


clean_up() {
    ####
    # FUNCTION INFO:
    #
    # If 'nadeko_latest_installer.sh', for whatever reason, is not able to completely
    # update or download NadekoBot, this function will cleanup any remaining files and
    # restore the previous code and configurations.
    #
    # @param $1 Determines whether or not this function kills the script's parent
    #           processes.
    ####

    # Files to be removed.
    local installer_files=("credentials_setup.sh" "installer_prep.sh"
        "prereqs_installer.sh" "nadeko_latest_installer.sh"
        "nadeko_master_installer.sh" "nadeko_runner.sh")

    echo "Cleaning up files and directories..."
    ## Remove any and all files specified in $installer_files.
    for file in "${installer_files[@]}"; do
        if [[ -f $_WORKING_DIR/$file ]]; then rm "$_WORKING_DIR"/"$file"; fi
    done
    
    ## Remove the NadekoBot code that was just downloaded, then restore the old code.
    if [[ -d $_WORKING_DIR/NadekoBot && -d $_WORKING_DIR/NadekoBot.bak ]]; then
        rm -rf "$_WORKING_DIR"/NadekoBot

        echo "Restoring from 'NadekoBot.bak'..."
        mv -f "$_WORKING_DIR"/NadekoBot.bak "$_WORKING_DIR"/NadekoBot || {
            echo "${_RED}Failed to restore from 'NadekoBot.bak'" >&2
            echo "${_CYAN}Manually rename 'NadekoBot.bak' to 'NadekoBot'$_NC"
        }
    fi

    ## Kill the script's parent processes, if param $1 is true.
    if [[ $1 = true ]]; then
        echo "Killing parent processes..."
        kill -9 "$_NADEKO_MASTER_INSTALLER_PID" "$_INSTALLER_PREP_PID"
        echo "Exiting..."
        exit 1
    fi
}


#### End of [ Functions ]
########################################################################################
#### [ Error Trapping ]


# Execute when the user uses 'Ctrl + Z' or 'Ctrl + C'.
trap 'echo -e "\n\nScript forcefully stopped"
    clean_up
    echo "Killing parent processes..."
    kill -9 "$_NADEKO_MASTER_INSTALLER_PID" "$_INSTALLER_PREP_PID"
    echo "Exiting..."
    exit 1' \
    SIGINT SIGTSTP SIGTERM


#### End of [ Error Trapping ]
########################################################################################
#### [ Main ]


printf "We will now download/update NadekoBot. "
read -rp "Press [Enter] to begin."

####################################################################################
######## [ Stop service ]


## 'active' is used on Linux, while 'running' is used on macOS.
## Stop $_NADEKO_SERVICE_STATUS if it's currently active/running.
if [[ $_NADEKO_SERVICE_STATUS = "active" || $_NADEKO_SERVICE_STATUS = "running" ]]; then
    nadeko_service_active=true
    _SERVICE_ACTIONS "stop_service" "false"
fi


######## End of [ Stop service ]
####################################################################################
######## [ Create Backup, Then Update ]


## If the 'NadekoBot' directory exists, create a backup of it.
if [[ -d NadekoBot ]]; then
    echo "Backing up NadekoBot as 'NadekoBot.bak'..."
    mv -f NadekoBot NadekoBot.bak || {
        echo "${_RED}Failed to back up NadekoBot$_NC" >&2
        echo -e "\nPress [Enter] to return to the installer menu"
        clean_up "false"
    }
fi

echo "Downloading NadekoBot..."
git clone -b "$_NADEKO_INSTALL_VERSION" --recursive --depth 1 https://gitlab.com/Kwoth/NadekoBot || {
    echo "${_RED}Failed to download NadekoBot$_NC" >&2
    clean_up "true"
}

# If $_DISTRO isn't Darwin and '/tmp/NuGetScratch' exists...
if [[ -d /tmp/NuGetScratch && $_DISTRO != "Darwin" ]]; then
    echo "Modifying ownership of '/tmp/NuGetScratch' and '/home/$USER/.nuget'"
    # Due to permission errors cropping up every now and then, especially when the
    # installer is executed with root privileges, it's neccessary to make sure that 
    # '/tmp/NuGetScratch' and '/home/$USER/.nuget' are owned by the user that the
    # installer is currently being run under.
    sudo chown -R "$USER":"$USER" /tmp/NuGetScratch /home/"$USER"/.nuget || {
        echo "${_RED}Failed to to modify the ownership of '/tmp/NuGetScratch' and/or" \
            "'/home/$USER/.nuget'..." >&2
        # NOTE: Unsure if this echo is applicable or not. May be removed in a future PR.
        echo "${_CYAN}You can ignore this if you were not prompted about locked" \
            "files/permission errors while attempting to download dependencies$_NC"
    }
fi

echo "Building NadekoBot..."
cd NadekoBot || {
    echo "${_RED}Failed to change working directory$_NC" >&2
    clean_up "true"
}
dotnet build --configuration Release || {
    echo "${_RED}Failed to build NadekoBot$_NC" >&2
    clean_up "true"
}
cd "$_WORKING_DIR" || {
    echo "${_RED}Failed to return to the project's root directory$_NC" >&2
    clean_up "true"
}

## Move credentials, database, and other data to the new version of NadekoBot.
if [[ -d NadekoBot.old && -d NadekoBot.bak || ! -d NadekoBot.old && -d NadekoBot.bak ]]; then
    echo "Copping 'credentials.json' to new version..."
    cp -f "$bak_credentials" "$new_credentials" &>/dev/null
    echo "Copping database to the new version..."
    cp -RT "$bak_database" "$new_database" &>/dev/null
    
    ## Check if an old netcoreapp version exists, then moves the database within it, to
    ## the new netcorapp version.
    while read -r netcoreapp; do
        if [[ $netcoreapp != "$notcoreapp_version" &&
                # Make sure that there is a database to even move.
                -f "$new_database"/Release/"$netcoreapp"/data/NadekoBot.db ]]; then
            echo "${_YELLOW}WARNING: Old netcoreapp version detected$_NC"
            echo "Moving database to new netcoreapp version..."

            ## NOTE: This code will be removed in the future, since the netcoreapp3.1
            ## directory will be created when building NadekoBot.
            if [[ ! -d $new_database/Release/$notcoreapp_version ]]; then
                mkdir "$new_database"/Release/"$notcoreapp_version"
                mkdir "$new_database"/Release/"$notcoreapp_version"/data/
            fi

            cp -RT "$new_database"/Release/"$netcoreapp"/data/NadekoBot.db \
                    "$new_database"/Release/"$notcoreapp_version"/data/NadekoBot.db || {
                echo "${_RED}Failed to move database$_NC" >&2
                clean_up "true"
            }
            ## Since NadekoBot still currently relies on netcoreapp2.1, it'll be left
            ## untouched for now.
            #echo "Removing '$netcoreapp'..."
            #rm -rf "$new_database"/Release/"$netcoreapp" || {
            #    echo "${_RED}Failed to remove '$netcoreapp'" >&2
            #    echo -e "${_CYAN}Please manually remove '$netcoreapp' before continuing" \
            #        "\nLocation: $_WORKING_DIR/$new_database/Release/$netcoreapp$_NC"
            #}
        fi
    done < <(ls "$_WORKING_DIR"/"$new_database"/Release/)

    echo "Copping other data to the new version..."
    cp -RT NadekoBot.bak/src/NadekoBot/data/ NadekoBot/src/NadekoBot/data/
    rm -rf NadekoBot.old && mv -f NadekoBot.bak NadekoBot.old  # TODO: Add error handling???
fi


######## End of [ Create Backup, Then Update ]
####################################################################################
######## [ Clean Up and Present Results ]


echo -e "\n${_GREEN}Finished downloading/updating NadekoBot$_NC"

if [[ $nadeko_service_active ]]; then
    echo "${_CYAN}NOTE: '$_NADEKO_SERVICE_NAME' was stopped to update NadekoBot and has" \
        "to be started using the run modes in the installer menu$_NC"
fi

read -rp "Press [Enter] to apply any existing changes to the installers"


######## End of [ Clean Up and Present Results ]
####################################################################################

#### End of [ Main ]
########################################################################################

