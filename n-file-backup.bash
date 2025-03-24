#!/bin/bash
#
# Important Files Backup Script
#
# This script creates a backup of user-designated important files, as specified by the
# $E_FILES_TO_BACK_UP variable defined in 'm-bridge.bash'.
#
############################################################################################
####[ Global Variables ]####################################################################


readonly C_CURRENT_BACKUP="important-files-backup"
readonly C_OLD_BACKUP="important-files-backup.old"

C_TMP_BACKUP=$(mktemp -d -p /tmp important-nadeko-files-XXXXXXXXXX)
readonly C_TMP_BACKUP

# shellcheck disable=SC2206
#   Left unquoted to allow word splitting for array assignment.
readonly C_FILES_TO_BACK_UP=($E_FILES_TO_BACK_UP)


####[ Functions ]###########################################################################


####
# Clean up temporary files and directories, and attempt to restore the original backup files
# in case of an error or premature exit.
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
    local exit_now=false

    # Remove the exit and sigint trap to prevent re-entry after exiting and repeated sigint
    # signals.
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


####[ Trapping Logic ]######################################################################


trap 'clean_exit "129" "true"' SIGHUP
trap 'clean_exit "130" "true"' SIGINT
trap 'clean_exit "143" "true"' SIGTERM
trap 'clean_exit "$?" "true"'  EXIT


####[ Main ]################################################################################


cd "$E_ROOT_DIR" || E_STDERR "Failed to change working directory to '$E_ROOT_DIR'" "1"
echo "${E_NOTE}We will now back up the following files:"
for file in "${C_FILES_TO_BACK_UP[@]}";
    do echo "  ${E_CYAN}|${E_NC}    $file"
done
read -rp "${E_NOTE}Press [Enter] to continue"

echo "${E_INFO}Backing up files into '$C_TMP_BACKUP'..."
for file in "${C_FILES_TO_BACK_UP[@]}"; do
    if [[ -f $file ]]; then
        cp -f "$file" "$C_TMP_BACKUP" || E_STDERR "Failed to back up '$file'" "1"
    else
        echo "${E_WARN}'$file' could not be found"
    fi
done

if [[ -d $C_CURRENT_BACKUP ]]; then
    ## If a current backup exists, copy its files to the temporary backup appending ".old"
    ## to mark them as previous versions.
    echo "${E_INFO}Copying previously backed up files into '$C_TMP_BACKUP'..."
    for file in "$C_CURRENT_BACKUP"/*; do
        basefile="${file##*/}"

        ## Only copy files that do not already end with '.old'.
        if [[ ! $basefile =~ ^.*\.old$ ]]; then
            cp "$file" "$C_TMP_BACKUP/$basefile.old" \
                || E_STDERR "Failed to copy '$basefile'" "1"
        fi
    done

    ## Replace the current backup with the temporary one, backing up the current version in
    ## $C_OLD_BACKUP.
    echo "${E_INFO}Replacing '$C_CURRENT_BACKUP' with '$C_TMP_BACKUP'..."
    (
        mv "$C_CURRENT_BACKUP" "$C_OLD_BACKUP" || exit 1
        mv "$C_TMP_BACKUP" "$C_CURRENT_BACKUP" || exit 1
        rm -rf "$C_OLD_BACKUP" \
            || E_STDERR "Failed to remove '$C_OLD_BACKUP'" "" \
                "${E_NOTE}Please remove '$C_OLD_BACKUP' manually"
     ) || E_STDERR "An error occurred while replacing old backups" "$?"
else
    echo "${E_INFO}Moving '$C_TMP_BACKUP' to '$C_CURRENT_BACKUP'..."
    mv "$C_TMP_BACKUP" "$C_CURRENT_BACKUP" \
        || E_STDERR "Failed to move '$C_TMP_BACKUP' to '$C_CURRENT_BACKUP'" "1"
fi

echo ""
echo "${E_SUCCESS}Finished backing up files"
clean_exit 0
