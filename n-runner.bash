#!/bin/bash
#
# NadekoBot Service Runner Configuration Script
#
# This script configures the systemd service for NadekoBot and prepares the runner script
# (NadekoRun) based on the chosen run mode. Depending on the value of E_RUNNER_CODENAME, it
# either creates a standard or an auto-restart version of the runner script, writes or
# updates the service file accordingly, and then starts or restarts the service. Finally, it
# displays the service logs to provide immediate feedback on the operation.
#
############################################################################################
####[ Global Variables ]####################################################################


## Determine the action to be performed on the NadekoBot service based on its code name.
if [[ $E_RUNNER_CODENAME == "NadekoRun" ]]; then
    readonly C_ACTION_LOWER="disable"    # Used with 'systemctl'.
    readonly C_ACTION_UPPER="Disabling"  # Used for text output.
else
    readonly C_ACTION_LOWER="enable"    # Used with 'systemctl'.
    readonly C_ACTION_UPPER="Enabling"  # Used for text output.
fi

readonly C_BOT_SERVICE_CONTENT="[Unit]
Description=NadekoBot service
After=network.target
StartLimitIntervalSec=60
StartLimitBurst=2

[Service]
Type=simple
User=$USER
WorkingDirectory=$E_ROOT_DIR
ExecStart=/bin/bash NadekoRun
Restart=on-failure
RestartSec=5
StandardOutput=journal
StandardError=journal
SyslogIdentifier=NadekoBot

[Install]
WantedBy=multi-user.target"

# Used to skip the 'read' command if an immediate script exit is required.
exit_now=false


####[ Functions ]###########################################################################


####
# Display an exit message based on the provided exit code, and exit the script with the
# specified code.
#
# PARAMETERS:
#   - $1: exit_code (Required)
#       - The initial exit code passed by the caller. Under certain conditions, it may be
#         modified to 50 to allow the calling script to continue.
#   - $2: use_extra_newline (Optional, Default: false)
#       - Whether to output an extra newline before the exit message.
#       - Acceptable values: true, false
#
# EXITS:
#   - $exit_code: The final exit code.
clean_exit() {
    local exit_code="$1"
    local use_extra_newline="${2:-false}"

    # Remove the exit and sigint trap to prevent re-entry after exiting and repeated sigint
    # signals.
    # Remove the other traps, as they are no longer needed.
    trap - EXIT SIGINT SIGHUP SIGTERM
    [[ $use_extra_newline == true ]] && echo ""

    case "$exit_code" in
        0|3) ;;
        1)
            exit_code=50
            ;;
        130)
            echo -e "\n${E_WARN}User interrupt detected (SIGINT)"
            exit_code=50
            ;;
        *)
            exit_now=true
            ;;
    esac

    if [[ $exit_now == false ]]; then
        read -rp "${E_NOTE}Press [Enter] to return to the Manager menu"
    fi

    exit "$exit_code"
}


####[ Trapping Logic ]######################################################################


trap 'clean_exit "129" "true"' SIGHUP
trap 'clean_exit "130" "true"' SIGINT
trap 'clean_exit "143" "true"' SIGTERM
trap 'clean_exit "$?" "true"'  EXIT


####[ Main ]################################################################################


if [[ -f $E_BOT_SERVICE_PATH ]]; then
    echo "${E_INFO}Updating '$E_BOT_SERVICE'..."
else
    echo "${E_INFO}Creating '$E_BOT_SERVICE'..."
fi

# shellcheck disable=SC2015
#   E_STDERR should be executed if either command fails.
echo "$C_BOT_SERVICE_CONTENT" | sudo tee "$E_BOT_SERVICE_PATH" &>/dev/null \
    && sudo systemctl daemon-reload \
    || E_STDERR "Failed to create '$E_BOT_SERVICE'" "3" \
        "${E_NOTE}This service must exist for NadekoBot to work"

## Disable/enable the NadekoBot service.
echo "${E_INFO}$C_ACTION_UPPER '$E_BOT_SERVICE'..."
sudo systemctl "$C_ACTION_LOWER" "$E_BOT_SERVICE" \
    || E_STDERR "Failed to $C_ACTION_LOWER '$E_BOT_SERVICE'" "3" \
        "${E_NOTE}This service must be ${C_ACTION_LOWER}d in order to use this run mode"

if [[ -f NadekoRun ]]; then
    echo "${E_INFO}Updating 'NadekoRun'..."
else
    echo "${E_INFO}Creating 'NadekoRun'..."
    touch NadekoRun
    chmod +x NadekoRun
fi

if [[ $E_RUNNER_CODENAME == "NadekoRun" ]]; then
    cat << EOF > NadekoRun
#!/bin/bash

_code_name_="NadekoRun"
export PATH="$E_LOCAL_BIN:$PATH"

echo "[INFO] python3 path: $(which python3)"
echo "[INFO] python3 version: $(python3 --version)"
echo "[INFO] yt-dlp path: $(which yt-dlp)"

echo "[INFO] Running NadekoBot in the background"
yt-dlp -U || echo "[ERROR] Failed to update 'yt-dlp'" >&2

echo "[INFO] Starting NadekoBot..."
pushd "$E_ROOT_DIR/$E_BOT_DIR" >/dev/null
./"$E_BOT_EXE" || {
    echo "[ERROR] Failed to start NadekoBot" >&2
    echo "[INFO] Exiting..."
    exit 1
}

echo "[INFO] Stopping NadekoBot..."
popd >/dev/null
EOF
else
    cat << EOF > NadekoRun
#!/bin/bash

_code_name_="NadekoRunAR"
export PATH="$E_LOCAL_BIN:$PATH"

echo "[INFO] python3 path: $(which python3)"
echo "[INFO] python3 version: $(python3 --version)"
echo "[INFO] yt-dlp path: $(which yt-dlp)"

echo "[INFO] Running NadekoBot in the background with auto restart"
yt-dlp -U || echo "[ERROR] Failed to update 'yt-dlp'" >&2

echo "[INFO] Starting NadekoBot..."

while true; do
    if [[ -d $E_ROOT_DIR/$E_BOT_DIR ]]; then
        cd "$E_ROOT_DIR/$E_BOT_DIR" || {
            echo "[ERROR] Failed to change working directory to '$E_ROOT_DIR/$E_BOT_DIR'" >&2
            echo "[INFO] Exiting..."
            exit 1
        }
    else
        echo "[WARN] '$E_ROOT_DIR/$E_BOT_DIR' doesn't exist" >&2
        echo "[INFO] Exiting..."
        exit 1
    fi

    ./"$E_BOT_EXE" || {
        echo "[ERROR] An error occurred when trying to start NadekoBot" >&2
        echo "[INFO] Exiting..."
        exit 1
    }

    echo "[INFO] Waiting 5 seconds..."
    sleep 5
    yt-dlp -U || echo "[ERROR] Failed to update 'yt-dlp'" >&2
    echo "[INFO] Restarting NadekoBot..."
done

echo "[INFO] Stopping NadekoBot..."
EOF
fi

if [[ $E_BOT_SERVICE_STATUS == "active" ]]; then
    echo "${E_INFO}Restarting '$E_BOT_SERVICE'..."
    sudo systemctl restart "$E_BOT_SERVICE" || E_STDERR "Failed to restart '$E_BOT_SERVICE'" "3"
else
    echo "${E_INFO}Starting '$E_BOT_SERVICE'..."
    sudo systemctl start "$E_BOT_SERVICE" || E_STDERR "Failed to start '$E_BOT_SERVICE'" "3"
fi

trap - SIGINT
# Since 'E_WATCH_SERVICE_LOGS' already contains a 'read' command, we skip the one in
# 'clean_exit'.
exit_now=true

E_WATCH_SERVICE_LOGS "runner"
