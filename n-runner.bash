#!/bin/bash
#
# This script starts NadekoBot in one of two modes:
#   - NadekoRun: Runs NadekoBot in the background.
#   - NadekoRunAR: Runs NadekoBot in the background with an automatic restart.
#
# Comment Key:
#   - A.1.: Used with 'systemctl'.
#   - B.1.: Used for text output.
#
########################################################################################
####[ Global Variables ]################################################################


## Determine the action to be performed on the NadekoBot service based on its code name.
if [[ $E_RUNNER_CODENAME == "NadekoRun" ]]; then
    readonly C_ACTION_LOWER="disable"    # A.1.
    readonly C_ACTION_UPPER="Disabling"  # B.1.
else
    readonly C_ACTION_LOWER="enable"    # A.1.
    readonly C_ACTION_UPPER="Enabling"  # B.1.
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


####[ Functions ]#######################################################################


####
# Exits the script cleanly by displaying an exit message and returning an appropriate
# exit code. This version is simpler than the 'clean_exit' functions found in other
# scripts.
#
# PARAMETERS:
#   - $1: exit_code (Required)
#       - The initial exit code passed to the function. Under certain conditions, it may
#         be changed to 50 to allow the calling script to continue execution.
#   - $2: use_extra_newline (Optional, Default: false)
#       - If set to "true", an extra blank line is output to separate any prior output
#         from the exit message.
#       - Acceptable values:
#           - true
#           - false
#
# EXITS:
#   - $exit_code: Uses the code provided by the caller, or 50 if the conditions for
#     continuing (exit code 1 or 130) are met.
clean_exit() {
    local exit_code="$1"
    local use_extra_newline="${2:-false}"

    trap - EXIT SIGINT
    [[ $use_extra_newline == true ]] && echo ""

    ## The exit code may be changed to 50 if 'n-update.bash' should continue
    ## despite an error. Refer to 'exit_code_actions' for further details.
    case "$exit_code" in
        1)   exit_code=50 ;;
        0|3) ;;
        129)
            echo -e "\n${E_WARN}Hangup signal detected (SIGHUP)"
            exit_now=true
            ;;
        130)
            echo -e "\n${E_WARN}User interrupt detected (SIGINT)"
            exit_code=50
            ;;
        143)
            echo -e "\n${E_WARN}Termination signal detected (SIGTERM)"
            exit_now=true
            ;;
        *)
            echo -e "\n${E_WARN}Exiting with exit code: $exit_code"
            exit_now=true
            ;;
    esac

    if [[ $exit_now == false ]]; then
        read -rp "${E_NOTE}Press [Enter] to return to the main menu"
    fi

    exit "$exit_code"
}


####[ Trapping Logic ]##################################################################


trap 'clean_exit "129" "true"' SIGHUP
trap 'clean_exit "130" "true"' SIGINT
trap 'clean_exit "143" "true"' SIGTERM
trap 'clean_exit "$?" "true"'  EXIT


####[ Main ]############################################################################


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

## Disable/enable the service.
echo "${E_INFO}$C_ACTION_UPPER '$E_BOT_SERVICE'..."
sudo systemctl "$C_ACTION_LOWER" "$E_BOT_SERVICE" \
    || E_STDERR "Failed to $C_ACTION_LOWER '$E_BOT_SERVICE'" "3" \
        "${E_NOTE}This service must be ${C_ACTION_LOWER}d in order to use this run mode"

if [[ -f NadekoRun ]]; then
    echo "${E_INFO}Updating 'NadekoRun'..."
else
    echo "${E_INFO}Creating 'NadekoRun'..."
    touch NadekoRun
    sudo chmod +x NadekoRun
fi

if [[ $E_RUNNER_CODENAME == "NadekoRun" ]]; then
    echo "#!/bin/bash

_code_name_=\"NadekoRun\"
export PATH=\"$E_LOCAL_BIN:$PATH\"  # Ensure anything in 'E_LOCAL_BIN' is accessible.

echo \"[INFO] python3 path: \$(which python3)\"
echo \"[INFO] python3 version: \$(python3 --version)\"
echo \"[INFO] yt-dlp path: \$(which yt-dlp)\"

echo \"[INFO] Running NadekoBot in the background\"
yt-dlp -U || echo \"[ERROR] Failed to update 'yt-dlp'\" >&2

echo \"[INFO] Starting NadekoBot...\"
cd \"$E_ROOT_DIR/$E_BOT_DIR\"
./\"$E_BOT_EXE\" || {
    echo \"[ERROR] Failed to start NadekoBot\" >&2
    echo \"[INFO] Exiting...\"
    exit 1
}

echo \"[INFO] Stopping NadekoBot...\"
cd \"$E_ROOT_DIR\"" > NadekoRun
else
    echo "#!/bin/bash

_code_name_=\"NadekoRunAR\"
export PATH=\"$E_LOCAL_BIN:$PATH\"  # Ensure anything in 'E_LOCAL_BIN' is accessible.

echo \"[INFO] python3 path: \$(which python3)\"
echo \"[INFO] python3 version: \$(python3 --version)\"
echo \"[INFO] yt-dlp path: \$(which yt-dlp)\"

echo \"[INFO] Running NadekoBot in the background with auto restart\"
yt-dlp -U || echo \"[ERROR] Failed to update 'yt-dlp'\" >&2

echo \"[INFO] Starting NadekoBot...\"

while true; do
    if [[ -d $E_ROOT_DIR/$E_BOT_DIR ]]; then
        cd \"$E_ROOT_DIR/$E_BOT_DIR\" || {
            echo \"[ERROR] Failed to change working directory to '$E_ROOT_DIR/$E_BOT_DIR'\" >&2
            echo \"[NOTE] Ensure the working directory in '/etc/systemd/system/nadeko.service' is correct\"
            echo \"[INFO] Exiting...\"
            exit 1
        }
    else
        echo \"[WARN] '$E_ROOT_DIR/$E_BOT_DIR' doesn't exist\" >&2
        echo \"[INFO] Exiting...\"
        exit 1
    fi

    ./\"$E_BOT_EXE\" || {
        echo \"[ERROR] An error occurred when trying to start NadekoBot\" >&2
        echo \"[INFO] Exiting...\"
        exit 1
    }

    echo \"[INFO] Waiting 5 seconds...\"
    sleep 5
    yt-dlp -U || echo \"[ERROR] Failed to update 'yt-dlp'\" >&2
    echo \"[INFO] Restarting NadekoBot...\"
done

echo \"[INFO] Stopping NadekoBot...\"" > NadekoRun
fi

if [[ $E_BOT_SERVICE_STATUS == "active" ]]; then
    echo "${E_INFO}Restarting '$E_BOT_SERVICE'..."
    sudo systemctl restart "$E_BOT_SERVICE" \
        || E_STDERR "Failed to restart '$E_BOT_SERVICE'" "3"
else
    echo "${E_INFO}Starting '$E_BOT_SERVICE'..."
    sudo systemctl start "$E_BOT_SERVICE" \
        || E_STDERR "Failed to start '$E_BOT_SERVICE'" "3"
fi

trap - SIGINT
# Since 'E_WATCH_SERVICE_LOGS' already contains a 'read' command, we skip the one in
# 'clean_exit' by setting:
exit_now=true

E_WATCH_SERVICE_LOGS "runner"
