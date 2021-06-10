#!/bin/bash
#
# Start NadekoBot in the specified run mode.
#
########################################################################################
#### [ Variables ]


# Number of seconds to wait, in order to give NadekoBot enough time to start.
timer=60
# Save the current time and date, which will be used in conjunction with 'journalctl'.
start_time=$(date +"%F %H:%M:%S")
nadeko_service_content="[Unit]
Description=NadekoBot service

[Service]
ExecStart=/bin/bash $_WORKING_DIR/NadekoRun.sh
User=$USER
Type=simple
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=NadekoBot

[Install]
WantedBy=multi-user.target"

### Decide whether we need to use 'disable' or 'enable'.
if [[ $_CODENAME = "NadekoRun" ]]; then
    dis_en_lower="disable"    # Used in conjunction with the 'systemctl' command.
    dis_en_upper="Disabling"  # Used in the text output.
else
    dis_en_lower="enable"    # Used in conjunction with the 'systemctl' command.
    dis_en_upper="Enabling"  # Used in the text output.
fi


#### End of [ Variables ]
########################################################################################
#### [ Main ]


# Check if the service exists.
if [[ -f $_NADEKO_SERVICE ]]; then echo "Updating '$_NADEKO_SERVICE_NAME'..."
else                               echo "Creating '$_NADEKO_SERVICE_NAME'..."
fi

# Create/update '$_NADEKO_SERVICE_NAME'.
echo "$nadeko_service_content" | sudo tee "$_NADEKO_SERVICE" &>/dev/null \
        && sudo systemctl daemon-reload || {
    echo "${_RED}Failed to create '$_NADEKO_SERVICE_NAME'" >&2
    echo "${_CYAN}This service must exist for NadekoBot to work$_NC"
    read -rp "Press [Enter] to return to the installer menu"
    exit 4
}

## Disable or enable '$_NADEKO_SERVICE_NAME'.
echo "$dis_en_upper '$_NADEKO_SERVICE_NAME'..."
sudo systemctl "$dis_en_lower" "$_NADEKO_SERVICE_NAME" || {
    echo "${_RED}Failed to $dis_en_lower '$_NADEKO_SERVICE_NAME'" >&2
    echo "${_CYAN}This service must be ${dis_en_lower}d in order to use this run mode$_NC"
    read -rp "Press [Enter] to return to the installer menu"
    exit 4
}

# Check if 'NadekoRun.sh' exists.
if [[ -f NadekoRun.sh ]]; then echo "Updating 'NadekoRun.sh'..."
## Create 'NadekoRun.sh' if it doesn't exist.
else
    echo "Creating 'NadekoRun.sh'..."
    touch NadekoRun.sh
    sudo chmod +x NadekoRun.sh
fi

## Add the code required to run NadekoBot in the background, to 'NadekoRun.sh'.
if [[ $_CODENAME = "NadekoRun" ]]; then
    printf '%s\n' \
        "#!bin/bash" \
        "" \
        "_code_name_=\"NadekoRun\"" \
        "" \
        "echo \"Running NadekoBot in the background\"" \
        "youtube-dl -U" \
        "" \
        "cd $_WORKING_DIR/NadekoBot" \
        "dotnet build -c Release" \
        "cd $_WORKING_DIR/NadekoBot/src/NadekoBot" \
        "echo \"Running NadekoBot...\"" \
        "dotnet run -c Release" \
        "echo \"Done\"" \
        "cd $_WORKING_DIR" \
        "" > NadekoRun.sh
## Add code required to run NadekoBot in the background with auto restart, to
## 'NadekoRun.sh'.
else
    printf '%s\n' \
        "#!/bin/bash" \
        "" \
        "_code_name_=\"NadekoRunAR\"" \
        "" \
        "echo \"\"" \
        "echo \"Running NadekoBot in the background with auto restart\"" \
        "youtube-dl -U" \
        "" \
        "sleep 5" \
        "cd $_WORKING_DIR/NadekoBot" \
        "dotnet build -c Release" \
        "" \
        "while true; do" \
        "    cd $_WORKING_DIR/NadekoBot/src/NadekoBot &&" \
        "        dotnet run -c Release" \
        "" \
        "    youtube-dl -U" \
        "    sleep 10" \
        "done" \
        "" \
        "echo \"Stopping NadekoBot\"" \
        "" > NadekoRun.sh
fi

## Restart $_NADEKO_SERVICE_NAME if it is currently running.
if [[ $_NADEKO_SERVICE_STATUS = "active" ]]; then
    echo "Restarting '$_NADEKO_SERVICE_NAME'..."
    sudo systemctl restart "$_NADEKO_SERVICE_NAME" || {
        echo "${_RED}Failed to restart '$_NADEKO_SERVICE_NAME'$_NC" >&2
        read -rp "Press [Enter] to return to the installer menu"
        exit 4
    }
    echo "Waiting $timer seconds for '$_NADEKO_SERVICE_NAME' to restart..."
## Start $_NADEKO_SERVICE_NAME if it is NOT currently running.
else
    echo "Starting '$_NADEKO_SERVICE_NAME'..."
    sudo systemctl start "$_NADEKO_SERVICE_NAME" || {
        echo "${_RED}Failed to start '$_NADEKO_SERVICE_NAME'$_NC" >&2
        read -rp "Press [Enter] to return to the installer menu"
        exit 4
    }
    echo "Waiting $timer seconds for '$_NADEKO_SERVICE_NAME' to start..."
fi

## Wait in order to give $_NADEKO_SERVICE_NAME enough time to (re)start.
while ((timer > 0)); do
    echo -en "$_CLRLN$timer seconds left"
    sleep 1
    ((timer-=1))
done

# NOTE: $_NO_HOSTNAME is purposefully unquoted. Do not quote it!
echo -e "\n\n-------- $_NADEKO_SERVICE_NAME startup logs ---------"            \
    "\n$(journalctl -q -u nadeko -b $_NO_HOSTNAME -S "$start_time" 2>/dev/null \
         || sudo journalctl -q -u nadeko -b $_NO_HOSTNAME -S "$start_time")"   \
    "\n--------- End of $_NADEKO_SERVICE_NAME startup logs --------\n"

echo -e "${_CYAN}Please check the logs above to make sure that there aren't any" \
    "errors, and if there are, to resolve whatever issue is causing them\n"

echo "${_GREEN}NadekoBot is now running in the background$_NC"
read -rp "Press [Enter] to return to the installer menu"


#### End of [ Variables ]
########################################################################################
