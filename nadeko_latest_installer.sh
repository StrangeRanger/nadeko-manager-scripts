#!/bin/bash
#
# Downloads and updates NadekoBot.
#
# Comment key for '[letter].[number].':
#   A.1. - For reasons I'm unsure of, the installer MUST download the newest version of
#          NadekoBot into a directory separate from the where the installer, or the
#          current version of NadekoBot, is located. Once NadekoBot has been built, it
#          can then be moved back to the installer directory.
#
# TODO: Before exiting (exit 1), have this script remove the temporary directory.
#
########################################################################################
#### [ Variables ]


current_creds="nadekobot/output/creds.yml"
new_creds="NadekoTMPDir/nadekobot/output/creds.yml"
current_database="nadekobot/output/data"
new_database="NadekoTMPDir/nadekobot/output/data"
current_data="nadekobot/src/NadekoBot/data"
new_data="NadekoTMPDir/nadekobot/src/NadekoBot/data"
export DOTNET_CLI_TELEMETRY_OPTOUT=1  # Used when compiling code.


#### End of [ Variables ]
########################################################################################
#### [ Main ]


read -rp "We will now download/update NadekoBot. Press [Enter] to begin."

########################################################################################
#### [[ Stop service ]]


## Stop the service if it's currently running.
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
        https://gitlab.com/Kwoth/nadekobot || {
    echo "${_RED}Failed to download NadekoBot$_NC" >&2
    exit 1
}

# If '/tmp/NuGetScratch' exists...
if [[ -d /tmp/NuGetScratch ]]; then
    echo "Modifying ownership of '/tmp/NuGetScratch' and '/home/$USER/.nuget'"
    # Due to permission errors cropping up every now and then, especially when the
    # installer is executed with root privilege, it's necessary to make sure that
    # '/tmp/NuGetScratch' and '/home/$USER/.nuget' are owned by the user that the
    # installer is currently being run under.
    sudo chown -R "$USER":"$USER" /tmp/NuGetScratch /home/"$USER"/.nuget || {
        echo "${_RED}Failed to to modify the ownership of '/tmp/NuGetScratch' and/or" \
            "'/home/$USER/.nuget'...$_NC" >&2
        exit 1
    }
fi

echo "Building NadekoBot..."
{
    cd nadekobot
    dotnet build src/NadekoBot/NadekoBot.csproj -c Release -o output/
    cd "$_WORKING_DIR"
} || {
    echo "${_RED}Failed to build NadekoBot$_NC" >&2
    exit 1
}

## Move credentials, database, and other data to the new version of NadekoBot.
if [[ -d NadekoTMPDir/nadekobot && -d nadekobot ]]; then
    echo "Copying 'creds.yml' to new version..."
    cp -f "$current_creds" "$new_creds" &>/dev/null
    # Also copies 'credentials.json' for migration purposes.
    cp -f nadekobot/output/credentials.json \
        NadekoTMPDir/nadekobot/output/credentials.json &>/dev/null
    echo "Copying database to the new version..."
    cp -RT "$current_database" "$new_database" &>/dev/null

    echo "Copying other data to the new version..."
    ## On update, strings will be new version, user will have to manually re-add his
    ## strings after each update as updates may cause big number of strings to become
    ## obsolete, changed, etc. However, old user's strings will be backed up to
    ## strings_old.
    # Backup new strings to reverse rewrite.
    mv -fT "$new_data"/strings "$new_data"/strings_new
    # Backup new aliases to reverse rewrite.
    mv -f "$new_data"/aliases.yml "$new_data"/aliases_new.yml

    cp -RT "$current_data" "$new_data"
    rm -rf nadekobot_old && mv -f nadekobot nadekobot_old
fi

mv NadekoTMPDir/nadekobot . && rmdir NadekoTMPDir


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
