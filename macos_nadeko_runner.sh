#!/bin/bash
#
# Start NadekoBot in the specified run mode.
#
########################################################################################
#### [ Variables ]


# Number of seconds to wait, in order to give NadekoBot enough time to start.
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


echo "${_CYAN}NOTE: Due to limiations on macOS, NadekoBot's startup logs will not be" \
    "displayed$_NC"

## Create '$_NADEKO_SERVICE_NAME', if it does not already exist.
if [[ ! -f $_NADEKO_SERVICE ]]; then
    echo "Creating '$_NADEKO_SERVICE_NAME'..."
    ## Create '/Users/"$USER"/Library/LaunchAgents' if 'LaunchAgents' doesn't already
    ## exist.
    if [[ ! -d /Users/$USER/Library/LaunchAgents/ ]]; then
        mkdir /Users/"$USER"/Library/LaunchAgents
    fi
    echo "$nadeko_service_content" | sudo tee "$_NADEKO_SERVICE" &>/dev/null \
        && {
            sudo chown "$USER":staff "$_NADEKO_SERVICE"
            launchctl enable gui/"$UID"/"$_NADEKO_SERVICE_NAME"
            launchctl load "$_NADEKO_SERVICE"
        } || {
            echo "${_RED}Failed to create '$_NADEKO_SERVICE_NAME'" >&2
            echo "${_CYAN}This service must exist for NadekoBot to work$_NC"
            read -rp "Press [Enter] to return to the installer menu"
            exit 4
        }
else
    echo "Updating '$_NADEKO_SERVICE_NAME'..."
fi

# Check if 'NadekoRun.sh' exists.
if [[ -f NadekoRun.sh ]]; then
    echo "Updating 'NadekoRun.sh'..."
## Create 'NadekoRun.sh' if it doesn't exist.
else
    echo "Creating 'NadekoRun.sh'..."
    touch NadekoRun.sh
    sudo chmod +x NadekoRun.sh
fi

## Add the code required to run NadekoBot in the background, to 'NadekoRun.sh'.
## Additionally update the service with the information needed to run NadekoBot in this
## run mode.
if [[ $_CODENAME = "NadekoRun" ]]; then
    printf '%s\n' \
        "#!/bin/bash" \
        "" \
        "export DOTNET_CLI_HOME=/tmp" \
        "_code_name_=\"NadekoRun\"" \
        "" \
        "add_date() {" \
        "    while IFS= read -r line; do" \
        "        echo -e \"\$(date +\"%F %H:%M:%S\") \$line\"" \
        "    done" \
        "}" \
        "" \
        "{" \
        "    echo \"\"" \
        "    echo \"Running NadekoBot in the background\"" \
        "    brew upgrade youtube-dl" \
        "} | add_date >> $_WORKING_DIR/bot.nadeko.Nadeko.log" \
        "" \
        "{" \
        "    cd $_WORKING_DIR/NadekoBot" \
        "    $(which dotnet) build -c Release" \
        "    cd $_WORKING_DIR/NadekoBot/src/NadekoBot" \
        "    echo \"Running NadekoBot...\"" \
        "    $(which dotnet) run -c Release" \
        "    echo \"Done\"" \
        "    cd $_WORKING_DIR" \
        "} | add_date >> $_WORKING_DIR/bot.nadeko.Nadeko.log" > NadekoRun.sh
    printf '%s\n' \
        "<?xml version=\"1.0\" encoding=\"UTF-8\"?>" \
        "<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">" \
        "<plist version=\"1.0\">" \
        "<dict>" \
        "    <key>Disabled</key>" \
        "    <false/>" \
        "    <key>Label</key>" \
        "    <string>$_NADEKO_SERVICE_NAME</string>" \
        "    <key>ProgramArguments</key>" \
        "    <array>" \
        "        <string>/bin/bash</string>" \
        "        <string>$_WORKING_DIR/NadekoRun.sh</string>" \
        "    </array>" \
        "    <key>RunAtLoad</key>" \
        "    <false/>" \
        "</dict>" \
        "</plist>" > "$_NADEKO_SERVICE"
## Add code required to run NadekoBot in the background with auto restart, to
## 'NadekoRun.sh'. Additionally update the service with the information needed to run
## NadekoBot in this run mode.
else
    printf '%s\n' \
        "#!/bin/bash" \
        "" \
        "export DOTNET_CLI_HOME=/tmp" \
        "_code_name_=\"NadekoRunAR\"" \
        "" \
        "add_date() {" \
        "    while IFS= read -r line; do" \
        "        echo -e \"\$(date +\"%F %H:%M:%S\") \$line\"" \
        "    done" \
        "}" \
        "" \
        "(" \
        "    echo \"\"" \
        "    echo \"Running NadekoBot in the background with auto restart\"" \
        "    brew upgrade youtube-dl" \
        "" \
        "    sleep 5" \
        "    cd $_WORKING_DIR/NadekoBot" \
        "    $(which dotnet) build -c Release" \
        ") | add_date >> $_WORKING_DIR/bot.nadeko.Nadeko.log" \
        "" \
        "(" \
        "    while true; do" \
        "        cd $_WORKING_DIR/NadekoBot/src/NadekoBot &&" \
        "            $(which dotnet) run -c Release" \
        "" \
        "        brew upgrade youtube-dl" \
        "        sleep 10" \
        "    done" \
        "    echo \"Stopping NadekoBot\"" \
        ") | add_date >> $_WORKING_DIR/bot.nadeko.Nadeko.log" > NadekoRun.sh
    printf '%s\n' \
        "<?xml version=\"1.0\" encoding=\"UTF-8\"?>" \
        "<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">" \
        "<plist version=\"1.0\">" \
        "<dict>" \
        "    <key>Disabled</key>" \
        "    <false/>" \
        "    <key>Label</key>" \
        "    <string>$_NADEKO_SERVICE_NAME</string>" \
        "    <key>ProgramArguments</key>" \
        "    <array>" \
        "        <string>/bin/bash</string>" \
        "        <string>$_WORKING_DIR/NadekoRun.sh</string>" \
        "    </array>" \
        "    <key>RunAtLoad</key>" \
        "    <true/>" \
        "</dict>" \
        "</plist>" > "$_NADEKO_SERVICE"
fi

## Restart '$_NADEKO_SERVICE_NAME' if it is currently running.
if [[ $_NADEKO_SERVICE_STATUS = "running" ]]; then
    echo "Restarting '$_NADEKO_SERVICE_NAME'..."
    launchctl kickstart -k gui/"$UID"/"$_NADEKO_SERVICE_NAME" || {
        error_code=$(launchctl error "$?")
        echo "${_RED}Failed to restart '$_NADEKO_SERVICE_NAME'$_NC" >&2
        echo "Error code: $error_code"
        read -rp "Press [Enter] to return to the installer menu"
        exit 4
    }
    echo "Waiting 60 seconds for '$_NADEKO_SERVICE_NAME' to restart..."
## Start '$_NADEKO_SERVICE_NAME' if it is NOT currently running.
else
    echo "Starting '$_NADEKO_SERVICE_NAME'..."
    launchctl start "$_NADEKO_SERVICE_NAME" || {
        error_code=$(launchctl error "$?")
        echo "${_RED}Failed to start '$_NADEKO_SERVICE_NAME'$_NC" >&2
        echo "Error code: $error_code"
        read -rp "Press [Enter] to return to the installer menu"
        exit 4
    }
    echo "Waiting 60 seconds for '$_NADEKO_SERVICE_NAME' to start..."
fi

## Wait in order to give '$_NADEKO_SERVICE_NAME' enough time to (re)start.
while ((timer > 0)); do
    echo -en "$_CLRLN$timer seconds left"
    sleep 1
    ((timer-=1))
done

echo -e "\n\n${_CYAN}It's recommended to inspect 'bot.nadeko.Nadeko.log' to confirm" \
    "that there were no errors during NadekoBot's startup$_NC"
read -rp "Press [Enter] to return to the installer menu"


#### End of [ Variables ]
########################################################################################
