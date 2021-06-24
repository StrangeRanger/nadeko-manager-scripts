#!/bin/bash
#
# Downloads and updates NadekoBot.
#
# Comment key for '[letter].[number].'
# ------------------------------------
# A.1. - For reasons I'm unsure of, the installer MUST download the newest version of
#        NadekoBot into a directory seperate from the where the installer, or the
#        current version of NadekoBot, is located. Once NadekoBot has been built, it can
#        then be moved back to the installer directory.
#
########################################################################################
#### [ Variables ]


current_credentials="NadekoBot/src/NadekoBot/credentials.json"
new_credentials="NadekoTMPDir/NadekoBot/src/NadekoBot/credentials.json"
current_database="NadekoBot/src/NadekoBot/bin/"
new_database="NadekoTMPDir/NadekoBot/src/NadekoBot/bin/"
current_data="NadekoBot/src/NadekoBot/data"
new_data="NadekoTMPDir/NadekoBot/src/NadekoBot/data"
netcoreapp_version="netcoreapp2.1"
# To be implemented in a later version, when NadekoBot uses 'netcoreapp3.1' instead of
# 'netcoreapp2.1'.
#netcoreapp_version="netcoreapp3.1"

## NOTE: 'cp' on macOS doesn't have the flag option "T", while the Linux version does.
## Use the "RT" flags if the OS is NOT macOS.
if [[ $_DISTRO != "Darwin" ]]; then cp_flag="RT"
## If running on macOS, use the "r" flag. But if 'gcp' (GNU cp) is installed, then use
## the "RT" flags and make 'cp' an alias of 'gcp'.
else
    if hash gcp; then
        # Enable 'expand_aliases' inside of this script.
        # This makes it possible for the alias to take immediate effect.
        shopt -s expand_aliases
        alias cp="gcp"
        cp_flag="RT"
    else
        cp_flag="r"
    fi
fi


#### End of [ Variables ]
########################################################################################
#### [ Main ]


read -rp "We will now download/update NadekoBot. Press [Enter] to begin."

########################################################################################
#### [[ Stop service ]]


## Stop $_NADEKO_SERVICE_STATUS if it's currently running.
if [[ $_NADEKO_SERVICE_STATUS = "active" || $_NADEKO_SERVICE_STATUS = "running" ]]; then
    nadeko_service_active=true
    _SERVICE_ACTIONS "stop_service" "false"
fi


#### End of [[ Stop service ]]
########################################################################################
#### [[ Create Backup, Then Update ]]


## A.1.
## Create a temporary folder to download NadekoBot into.
mkdir NadekoTMPDir
cd NadekoTMPDir || {
    echo "${_RED}Failed to change working directory$_NC" >&2
    exit 1
}

echo "Downloading NadekoBot into 'NadekoTMPDir'..."
# Download NadekoBot from a specified branch/tag.
git clone -b "$_NADEKO_INSTALL_VERSION" --recursive --depth 1 \
        https://gitlab.com/Kwoth/NadekoBot || {
    echo "${_RED}Failed to download NadekoBot$_NC" >&2
    exit 1
}

# If $_DISTRO isn't Darwin and '/tmp/NuGetScratch' exists...
if [[ -d /tmp/NuGetScratch && $_DISTRO != "Darwin" ]]; then
    echo "Modifying ownership of '/tmp/NuGetScratch' and '/home/$USER/.nuget'"
    # Due to permission errors cropping up every now and then, especially when the
    # installer is executed with root privilege, it's neccessary to make sure that
    # '/tmp/NuGetScratch' and '/home/$USER/.nuget' are owned by the user that the
    # installer is currently being run under.
    sudo chown -R "$USER":"$USER" /tmp/NuGetScratch /home/"$USER"/.nuget || {
        echo "${_RED}Failed to to modify the ownership of '/tmp/NuGetScratch' and/or" \
            "'/home/$USER/.nuget'..." >&2
    }
fi

echo "Building NadekoBot..."
cd NadekoBot || {
    echo "${_RED}Failed to change working directory$_NC" >&2
    exit 1
}

dotnet build --configuration Release || {
    echo "${_RED}Failed to build NadekoBot$_NC" >&2
    exit 1
}
cd "$_WORKING_DIR" || {
    echo "${_RED}Failed to return to the project's root directory$_NC" >&2
    exit 1
}

## Move credentials, database, and other data to the new version of NadekoBot.
if [[ -d NadekoBot ]]; then
    echo "Copping 'credentials.json' to new version..."
    cp -f "$current_credentials" "$new_credentials" &>/dev/null
    echo "Copping database to the new version..."
    cp -"$cp_flag" "$current_database" "$new_database" &>/dev/null

    ## Check if an old netcoreapp version exists, then move the database within it, to
    ## the new netcorapp version.
    while read -r netcoreapp; do
        if [[ $netcoreapp != "$netcoreapp_version" \
                && -f "$new_database"/Release/"$netcoreapp"/data/NadekoBot.db ]]; then
            echo "${_YELLOW}WARNING: Old netcoreapp version detected$_NC"
            echo "Moving database to new netcoreapp version..."

            cp "$new_database"/Release/"$netcoreapp"/data/NadekoBot.db \
                    "$new_database"/Release/"$netcoreapp_version"/data/NadekoBot.db || {
                echo "${_RED}Failed to move database$_NC" >&2
                exit 1
            }

            echo "Removing '$netcoreapp'..."
            rm -rf "$new_database"/Release/"$netcoreapp" || {
                echo "${_RED}Failed to remove '$netcoreapp'" >&2
                echo "${_CYAN}Please manually remove '$netcoreapp' before continuing"
                echo "Location: $_WORKING_DIR/$new_database/Release/$netcoreapp$_NC"
            }
        fi
    done < <(ls "$_WORKING_DIR"/"$new_database"/Release/)

    echo "Copping other data to the new version..."
    ## 'alises.yml' and 'strings' are updated with every install, which could break the
    ## bot if not changed...
    if [[ -f "$current_data"/aliases.yml.old ]]; then
        rm -f "$current_data"/aliases.yml.old
    fi
    mv -f "$current_data"/aliases.yml "$current_data"/aliases.yml.old
    if [[ -d "$current_data"/strings.old ]]; then
        rm -rf "$current_data"/strings.old
    fi
    mv -f "$current_data"/strings "$current_data"/strings.old

    cp -"$cp_flag" "$current_data" "$new_data"
    rm -rf NadekoBot.old && mv -f NadekoBot NadekoBot.old
fi

mv NadekoTMPDir/NadekoBot . && rmdir NadekoTMPDir


#### End of [[ Create Backup, Then Update ]]
########################################################################################
#### [[ Clean Up and Present Results ]]


echo -e "\n${_GREEN}Finished downloading/updating NadekoBot$_NC"

if [[ $nadeko_service_active ]]; then
    echo "${_CYAN}NOTE: '$_NADEKO_SERVICE_NAME' was stopped to update NadekoBot and" \
        "needs to be started using one of the run modes in the installer menu$_NC"
fi

read -rp "Press [Enter] to apply any existing changes to the installers"


#### End of [[ Clean Up and Present Results ]]
########################################################################################

#### End of [ Main ]
########################################################################################
