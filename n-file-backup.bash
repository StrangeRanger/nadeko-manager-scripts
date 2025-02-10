#!/bin/bash
#
# Backs up files deemed important to the user. These files are specified by the
# $E_FILES_TO_BACK_UP variable in 'm-bridge.bash'.
#
########################################################################################
####[ Global Variables ]################################################################


readonly C_CURRENT_BACKUP="important-files-backup"
readonly C_OLD_BACKUP="important-files-backup.old"

C_TMP_BACKUP=$(mktemp -d -p /tmp important-nadeko-files-XXXXXXXXXX)
readonly C_TMP_BACKUP

# shellcheck disable=SC2206
#   The variable $E_FILES_TO_BACK_UP is intentionally left unquoted so that word
#   splitting occurs. This converts its contents into an array, with each word becoming
#   an individual element in $C_FILES_TO_BACK_UP.
readonly C_FILES_TO_BACK_UP=($E_FILES_TO_BACK_UP)


####[ Functions ]#######################################################################


####
# Cleans up temporary files and directories, and attempts to restore original backup
# files in case of an error or premature exit. This helps prevent data loss by ensuring
# that backup files are restored if the backup process could not be completed
# successfully.
#
# PARAMETERS:
#   - $1: exit_code (Required)
#       - The initial exit code passed by the caller. Under certain conditions, it may
#         be modified to 50 to allow the calling script to continue.
#   - $2: use_extra_newline (Optional, Default: false)
#       - If "true", outputs an extra blank line to distinguish previous output from the
#         exit messages.
#       - Acceptable values: true, false.
#
# EXITS:
#   - $exit_code: The final exit code, which may be 50 if conditions for continuation
#     are met.
clean_exit() {
    local exit_code="$1"
    local use_extra_newline="${2:-false}"
    local exit_now=false

    trap - EXIT SIGINT
    [[ $use_extra_newline == true ]] && echo ""

    case "$exit_code" in
        0|5) ;;
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

    echo "${E_INFO}Cleaning up..."
    [[ -d "$C_TMP_BACKUP" ]] && rm -rf "$C_TMP_BACKUP" &>/dev/null

    ## Attempt to restore original backups if necessary.
    (
        if [[ ! -d $C_CURRENT_BACKUP && -d $C_OLD_BACKUP ]]; then
            echo "${E_WARN}Unable to complete backup"
            echo "${E_INFO}Attempting to restore original backups..."
            mv "$C_OLD_BACKUP" "$C_CURRENT_BACKUP" || exit 1
        elif [[ -d $C_CURRENT_BACKUP && -d $C_OLD_BACKUP ]]; then
            rm -rf "$C_OLD_BACKUP" \
                || E_STDERR "Failed to remove '$C_OLD_BACKUP'" "" \
                    "${E_NOTE}Please remove '$C_OLD_BACKUP' manually"
        fi
    ) || E_STDERR "Failed to restore original backup" "$?" \
        "${E_NOTE}We will exit completely to prevent data loss"

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


echo "${E_NOTE}We will now back up the following files:"
for file in "${C_FILES_TO_BACK_UP[@]}";
    do echo "  ${E_CYAN}|${E_NC}    $file"
done
read -rp "${E_NOTE}Press [Enter] to continue"
cd "$E_ROOT_DIR" || E_STDERR "Failed to change working directory to '$E_ROOT_DIR'" "1"

echo "${E_INFO}Backing up files into '$C_TMP_BACKUP'..."
for file in "${C_FILES_TO_BACK_UP[@]}"; do
    if [[ -f $file ]]; then
        cp -f "$file" "$C_TMP_BACKUP" || E_STDERR "Failed to back up '$file'" "1"
    else
        echo "${E_WARN}'$file' could not be found"
    fi
done

if [[ -d $C_CURRENT_BACKUP ]]; then
    ## If a current backup directory exists, copy its files into the temporary backup
    ## directory and append ".old" to their names. This effectively stages the files
    ## to become the new "old" backups.
    echo "${E_INFO}Copying previously backed up files into '$C_TMP_BACKUP'..."
    for file in "$C_CURRENT_BACKUP"/*; do
        basefile="${file##*/}"

        # Only copy files that do not already end with '.old'.
        if [[ ! $basefile =~ ^.*\.old$ ]]; then
            cp "$file" "$C_TMP_BACKUP/$basefile.old" \
                || E_STDERR "Failed to copy '$basefile'" "1"
        fi
    done

    ## Move the current backup folder to $C_OLD_BACKUP, and then move the temporary
    ## backup folder to $C_CURRENT_BACKUP. This creates a safe fallback: if an
    ## unexpected error occurs, reverting to $C_OLD_BACKUP is simpler.
    echo "${E_INFO}Replacing '$C_CURRENT_BACKUP' with '$C_TMP_BACKUP'..."
    (
        mv "$C_CURRENT_BACKUP" "$C_OLD_BACKUP" || exit 1
        mv "$C_TMP_BACKUP" "$C_CURRENT_BACKUP" || exit 1
        rm -rf "$C_OLD_BACKUP" \
            || E_STDERR "Failed to remove '$C_OLD_BACKUP'" "" \
                "${E_NOTE}Please remove '$C_OLD_BACKUP' manually"
     ) || E_STDERR "An error occurred while replacing old backups" "1"
else
    ## If no current backup directory exists, simply move the temporary backup folder to
    ## become the new current backup directory.
    echo "${E_INFO}Moving '$C_TMP_BACKUP' to '$C_CURRENT_BACKUP'..."
    mv "$C_TMP_BACKUP" "$C_CURRENT_BACKUP" \
        || E_STDERR "Failed to move '$C_TMP_BACKUP' to '$C_CURRENT_BACKUP'" "1"
fi

echo ""
echo "${E_SUCCESS}Finished backing up files"
clean_exit 0
