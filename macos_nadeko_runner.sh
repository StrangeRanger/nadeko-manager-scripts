#!/bin/bash
#
# Start NadekoBot in the specified run mode.
#
# COMMENT '[letter].[number].' KEY INFO:
#   A.1. - Return to prevent further code execution.
#
########################################################################################
#### [ Variables ]


timer=60
nadeko_service_content="<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">
<plist version=\"1.0\">
<dict>
	<key>Disabled</key>
	<false/>
	<key>Label</key>
	<string>$_NADEKO_SERVICE_NAME</string>
	<key>ProgramArguments</key>
	<array>
		<string>/bin/bash</string>
		<string>$_WORKING_DIR/NadekoRun.sh</string>
	</array>
	<key>RunAtLoad</key>
	<false/>
</dict>
</plist>"


#### End of [ Variables ]
########################################################################################
#### [ Main ]


echo "${_CYAN}NOTE: Due to limiations on macOS, NadekoBots's startup  logs will not" \
    "be displayed$_NC"

## Create '$_NADEKO_SERVICE_NAME', if it does not already exist.
if [[ ! -f $_NADEKO_SERVICE ]]; then
    echo "Creating '$_NADEKO_SERVICE_NAME'..."
    ## If running on macOS, create '/Users/"$USER"/Library/LaunchAgents' if
    ## 'LaunchAgents' doesn't already exist.
    if [[ ! -d /Users/$USER/Library/LaunchAgents/ ]]; then
        # TODO: Add error catching???
        mkdir /Users/"$USER"/Library/LaunchAgents
    fi
    echo "$nadeko_service_content" | sudo tee "$_NADEKO_SERVICE" &>/dev/null && (
            sudo chown "$USER":staff "$_NADEKO_SERVICE"
            launchctl enable gui/"$UID"/"$_NADEKO_SERVICE_NAME"
            launchctl load "$_NADEKO_SERVICE") || {
        echo "${_RED}Failed to create '$_NADEKO_SERVICE_NAME'" >&2
        echo "${_CYAN}This service must exist for NadekoBot to work$_NC"
        _CLEAN_EXIT "1" "Exiting"
    }
else
    ecno "Updating '$_NADEKO_SERVICE_NAME'..."
fi

# Check if 'NadekoRun.sh' exists.
if [[ -f NadekoRun.sh ]]; then
    echo "Updating 'NadekoRun.sh'..."
else
    echo "Creating 'NadekoRun.sh'..."
    touch NadekoRun.sh
    sudo chmod +x NadekoRun.sh
fi

## Add code to 'NadekoRun.sh' required to run NadekoBot in the background.
if [[ $_CODENAME = "NadekoRun" ]]; then 
    echo -e "#!/bin/bash \
        \n \
        \nexport DOTNET_CLI_HOME=/tmp \
        \n_code_name_=\"NadekoRun\" \
        \n \
        \nadd_date() { \
        \n    while IFS= read -r line; do \
        \n        echo -e \"\$(date +\"%F %H:%M:%S\") \$line\" \
        \n    done \
        \n} \
        \n \
        \n( \
        \n    echo \"\" \
        \n    echo \"Running NadekoBot in the background\" \
        \n    brew upgrade youtube-dl \
        \n) | add_date >> $_WORKING_DIR/bot.nadeko.Nadeko.log \
        \n \
        \n( \
        \n    cd $_WORKING_DIR/NadekoBot \
        \n    $(which dotnet) build -c Release \
        \n    cd $_WORKING_DIR/NadekoBot/src/NadekoBot \
        \n    echo \"Running NadekoBot...\" \
        \n    $(which dotnet) run -c Release \
        \n    echo \"Done\" \
        \n    cd $_WORKING_DIR \
        \n) | add_date >> $_WORKING_DIR/bot.nadeko.Nadeko.log" > NadekoRun.sh
    echo -e "<?xml version=\"1.0\" encoding=\"UTF-8\"?> \
        \n<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\"> \
        \n<plist version=\"1.0\"> \
        \n<dict> \
        \n    <key>Disabled</key> \
        \n    <false/> \
        \n    <key>Label</key> \
        \n    <string>$_NADEKO_SERVICE_NAME</string> \
        \n    <key>ProgramArguments</key> \
        \n    <array> \
        \n        <string>$(which bash)</string> \
        \n        <string>$_WORKING_DIR/NadekoRun.sh</string> \
        \n    </array> \
        \n    <key>RunAtLoad</key> \
        \n    <false/> \
        \n</dict> \
        \n</plist>" > "$_NADEKO_SERVICE"
## Add code to 'NadekoRun.sh' required to run NadekoBot in the background with auto restart.
else
    echo -e "#!/bin/bash \
        \n \
        \nexport DOTNET_CLI_HOME=/tmp \
        \n_code_name_=\"NadekoRunAR\" \
        \n \
        \nadd_date() { \
        \n    while IFS= read -r line; do \
        \n        echo -e \"\$(date +\"%F %H:%M:%S\") \$line\" \
        \n    done \
        \n} \
        \n \
        \n( \
        \n    echo \"\" \
        \n    echo \"Running NadekoBot in the background with auto restart\" \
        \n    brew upgrade youtube-dl \
        \n \
        \n    sleep 5 \
        \n    cd $_WORKING_DIR/NadekoBot \
        \n    $(which dotnet) build -c Release \
        \n) | add_date >> $_WORKING_DIR/bot.nadeko.Nadeko.log \
        \n \
        \n( \
        \n    while true; do \
        \n        cd $_WORKING_DIR/NadekoBot/src/NadekoBot && \
        \n            $(which dotnet) run -c Release \
        \n \
        \n        brew upgrade youtube-dl \
        \n        sleep 10 \
        \n    done \
        \n    echo \"Stopping NadekoBot\" \
        \n) | add_date >> $_WORKING_DIR/bot.nadeko.Nadeko.log" > NadekoRun.sh
    echo -e "<?xml version=\"1.0\" encoding=\"UTF-8\"?> \
        \n<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\"> \
        \n<plist version=\"1.0\"> \
        \n<dict> \
        \n    <key>Disabled</key> \
        \n    <false/> \
        \n    <key>Label</key> \
        \n    <string>$_NADEKO_SERVICE_NAME</string> \
        \n    <key>ProgramArguments</key> \
        \n    <array> \
        \n        <string>$(which bash)</string> \
        \n        <string>$_WORKING_DIR/NadekoRun.sh</string> \
        \n    </array> \
        \n    <key>RunAtLoad</key> \
        \n    <true/> \
        \n</dict> \
        \n</plist>" > "$_NADEKO_SERVICE"
fi

## Restart '$_NADEKO_SERVICE_NAME' if it is currently running.
if [[ $_NADEKO_SERVICE_STATUS = "running" ]]; then
    echo "Restarting '$_NADEKO_SERVICE_NAME'..."
    launchctl kickstart -k gui/"$UID"/"$_NADEKO_SERVICE_NAME" || {
        error_code=$(launchctl error "$?")
        echo "${_RED}Failed to restart '$_NADEKO_SERVICE_NAME'$_NC" >&2
        echo "Error code: $error_code"
        read -rp "Press [Enter] to return to the installer menu"
        return 1  # A.1.
    }
    echo "Waiting 60 seconds for '$_NADEKO_SERVICE_NAME' to restart..."
## Start '$_NADEKO_SERVICE_NAME' if it is NOT currently running.
else
    echo "Starting '$_NADEKO_SERVICE_NAME'..."
    launchctl start $_NADEKO_SERVICE_NAME || {
        error_code=$(launchctl error "$?")
        echo "${_RED}Failed to start '$_NADEKO_SERVICE_NAME'$_NC" >&2
        echo "Error code: $error_code"
        read -rp "Press [Enter] to return to the installer menu"
        return 1  # A.1.
    }
    echo "Waiting 60 seconds for '$_NADEKO_SERVICE_NAME' to start..."
fi

## Wait in order to give '$_NADEKO_SERVICE_NAME' enough time to (re)start.
while ((timer > 0)); do
    echo -en "${_CLRLN}${timer} seconds left"
    sleep 1
    ((timer-=1))
done

echo -e "\n\n${_CYAN}It's recommended to inspect 'bot.nadeko.Nadeko.log'" \
    "to confirm that there were no errors during NadekoBot's startup$_NC"
read -rp "Press [Enter] to return to the installer menu"
