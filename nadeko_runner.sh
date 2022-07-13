#!/bin/bash
#
# Start NadekoBot in the specified run mode, on Linux distributions.
#
# Comment key:
#   A.1. - Used in conjunction with the 'systemctl' command.
#   B.1. - Used in the text output.
#
########################################################################################
#### [ Variables ]


### Indicate which actions ('disable' or 'enable') to be performed on NadekoBot's
### service.
if [[ $_CODENAME = "NadekoRun" ]]; then
    dis_en_lower="disable"    # A.1.
    dis_en_upper="Disabling"  # B.1.
else
    dis_en_lower="enable"    # A.1.
    dis_en_upper="Enabling"  # B.1.
fi

## PURPOSE: 'StandardOutput' and 'StandardError' no longer support 'syslog', starting in
##          version 246 of systemd.
## The contents of NadekoBot's service.
if ((_SYSTEMD_VERSION >= 246)); then
    nadeko_service_content="[Unit]
Description=NadekoBot service
After=network.target
StartLimitIntervalSec=60
StartLimitBurst=2

[Service]
Type=simple
User=$USER
WorkingDirectory=$_WORKING_DIR
ExecStart=/bin/bash NadekoRun.sh
Restart=on-failure
RestartSec=5
StandardOutput=journal
StandardError=journal
SyslogIdentifier=NadekoBot

[Install]
WantedBy=multi-user.target"
else
    # The contents of NadekoBot's service.
    nadeko_service_content="[Unit]
Description=NadekoBot service
After=network.target
StartLimitIntervalSec=60
StartLimitBurst=2

[Service]
Type=simple
User=$USER
WorkingDirectory=$_WORKING_DIR
ExecStart=/bin/bash NadekoRun.sh
Restart=on-failure
RestartSec=5
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=NadekoBot

[Install]
WantedBy=multi-user.target"
fi


#### End of [ Variables ]
########################################################################################
#### [ Main ]


# Check if the service exists.
if [[ -f $_NADEKO_SERVICE ]]; then echo "Updating '$_NADEKO_SERVICE_NAME'..."
else                               echo "Creating '$_NADEKO_SERVICE_NAME'..."
fi

{
    # Create/update the service.
    echo "$nadeko_service_content" | sudo tee "$_NADEKO_SERVICE" &>/dev/null \
    && sudo systemctl daemon-reload
} || {
    echo "${_RED}Failed to create '$_NADEKO_SERVICE_NAME'" >&2
    echo "${_CYAN}This service must exist for NadekoBot to work${_NC}"
    read -rp "Press [Enter] to return to the installer menu"
    exit 4
}

## Disable/enable the service.
echo "$dis_en_upper '$_NADEKO_SERVICE_NAME'..."
sudo systemctl "$dis_en_lower" "$_NADEKO_SERVICE_NAME" || {
    echo "${_RED}Failed to $dis_en_lower '$_NADEKO_SERVICE_NAME'" >&2
    echo "${_CYAN}This service must be ${dis_en_lower}d in order to use this run mode${_NC}"
    read -rp "Press [Enter] to return to the installer menu"
    exit 4
}

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
if [[ $_CODENAME = "NadekoRun" ]]; then
    printf '%s\n' \
        "#!/bin/bash" \
        "" \
        "_code_name_=\"NadekoRun\"" \
        "" \
        "echo \"Running NadekoBot in the background\"" \
        "youtube-dl -U" \
        "" \
        "echo \"Starting NadekoBot...\"" \
        "cd $_WORKING_DIR/nadekobot/output" \
        "dotnet NadekoBot.dll || {" \
        "    echo \"An error occurred when trying to start Mewdeko\"" \
        "    echo \"Exiting...\"" \
        "    exit 1" \
        "}" \
        "echo \"Stopping NadekoBot...\"" \
        "cd $_WORKING_DIR" > NadekoRun.sh
## Add code required to run NadekoBot in the background with auto restart, to
## 'NadekoRun.sh'.
else
    printf '%s\n' \
        "#!/bin/bash" \
        "" \
        "_code_name_=\"NadekoRunAR\"" \
        "" \
        "echo \"Running NadekoBot in the background with auto restart\"" \
        "youtube-dl -U" \
        "" \
        "echo \"Starting NadekoBot...\"" \
        "" \
        "while true; do" \
        "    if [[ -d $_WORKING_DIR/nadekobot/output ]]; then" \
        "        cd $_WORKING_DIR/nadekobot/output || {" \
        "            echo \"Failed to change working directory to '$_WORKING_DIR/nadekobot/output'\" >&2" \
        "            echo \"Ensure that the working directory inside of '/etc/systemd/system/nadeko.service' is correct\"" \
        "            echo \"Exiting...\"" \
        "            exit 1" \
        "        }" \
        "    else" \
        "        echo \"'$_WORKING_DIR/nadekobot/output' doesn't exist\"" \
        "        exit 1" \
        "    fi" \
        "" \
        "    dotnet NadekoBot.dll || {" \
        "        echo \"An error occurred when trying to start NadekBot\"" \
        "        echo \"Exiting...\"" \
        "        exit 1" \
        "    }" \
        "" \
        "    echo \"Waiting for 5 seconds...\"" \
        "    sleep 5" \
        "    youtube-dl -U" \
        "    echo \"Restarting NadekoBot...\"" \
        "done" \
        "" \
        "echo \"Stopping NadekoBot...\"" > NadekoRun.sh
fi

## Restart the service if it is currently running.
if [[ $_NADEKO_SERVICE_STATUS = "active" ]]; then
    echo "Restarting '$_NADEKO_SERVICE_NAME'..."
    sudo systemctl restart "$_NADEKO_SERVICE_NAME" || {
        echo "${_RED}Failed to restart '$_NADEKO_SERVICE_NAME'${_NC}" >&2
        read -rp "Press [Enter] to return to the installer menu"
        exit 4
    }
## Start the service if it is NOT currently running.
else
    echo "Starting '$_NADEKO_SERVICE_NAME'..."
    sudo systemctl start "$_NADEKO_SERVICE_NAME" || {
        echo "${_RED}Failed to start '$_NADEKO_SERVICE_NAME'${_NC}" >&2
        read -rp "Press [Enter] to return to the installer menu"
        exit 4
    }
fi

_WATCH_SERVICE_LOGS "runner"


#### End of [ Variables ]
########################################################################################
