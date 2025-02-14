#!/bin/bash
#
# NadekoBot Update Utility
#
# This script automates the process of updating NadekoBot to a user-selected version.
#
# NOTE:
#   After each update, any custom modifications to strings and aliases must be
#   re-applied manually. However, backups of the previous versions are saved as
#   'strings.old' and 'aliases.old.yml' respectively.
#
########################################################################################
####[ Variables ]#######################################################################


C_NADEKOBOT_TMP=$(mktemp -d -p /tmp nadekobot-XXXXXXXXXX)
readonly C_NADEKOBOT_TMP

## File paths.
readonly C_BOT_DIR_TMP="$C_NADEKOBOT_TMP/$E_BOT_DIR"
readonly C_BOT_DIR_OLD="$E_BOT_DIR.old"
readonly C_BOT_DIR_OLD_OLD="$E_BOT_DIR.old.old"
readonly C_EXAMPLE_CREDS_PATH="$C_BOT_DIR_TMP/$E_CREDS_EXAMPLE"
readonly C_NEW_CREDS_PATH="$C_NADEKOBOT_TMP/$E_CREDS_PATH"
readonly C_CURRENT_DB_PATH="$E_BOT_DIR/data/NadekoBot.db"
readonly C_NEW_DB_PATH="$C_BOT_DIR_TMP/data/NadekoBot.db"
readonly C_CURRENT_DATA_PATH="$E_BOT_DIR/data"
readonly C_NEW_DATA_PATH="$C_BOT_DIR_TMP/data"

## GitLab project details.
readonly PROJECT_ID="9321079"
readonly API_URL="https://gitlab.com/api/v4/projects/${PROJECT_ID}"

## Non-constant variables.
service_is_active=false


####[ Functions ]#######################################################################


####
# Cleans up temporary files and directories, and attempts to restore the original
# $E_BOT_DIR if an error or premature exit is detected.
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
#   - $exit_code: The final exit code.
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
    [[ -d "$C_NADEKOBOT_TMP" ]] && rm -rf "$C_NADEKOBOT_TMP" &>/dev/null

    ## Attempts to restore the original $E_BOT_DIR if necessary.
    {
        if [[ -d $E_BOT_DIR && ! -d $C_BOT_DIR_OLD && -d $C_BOT_DIR_OLD_OLD ]]; then
            echo "${E_WARN}Unable to complete installation"
            echo "${E_INFO}Attempting to restore original version of '$E_BOT_DIR'..."
            mv "$C_BOT_DIR_OLD_OLD" "$C_BOT_DIR_OLD" || exit 1
        elif [[ ! -d $E_BOT_DIR && -d $C_BOT_DIR_OLD ]]; then
            echo "${E_WARN}Unable to complete installation"
            echo "${E_INFO}Attempting to restore original version of '$E_BOT_DIR'..."
            mv "$C_BOT_DIR_OLD" "$E_BOT_DIR" || exit 1

            if [[ -d $C_BOT_DIR_OLD_OLD ]]; then
                mv "$C_BOT_DIR_OLD_OLD" "$C_BOT_DIR_OLD" \
                    || E_STDERR \
                        "Failed to rename '$C_BOT_DIR_OLD_OLD' as '$C_BOT_DIR_OLD'" \
                        "" "${E_NOTE}Please rename it manually"
            fi
        elif [[ -d $E_BOT_DIR && -d $C_BOT_DIR_OLD && -d $C_BOT_DIR_OLD_OLD ]]; then
            rm -rf "$C_BOT_DIR_OLD_OLD" \
                || E_STDERR "Failed to remove '$C_BOT_DIR_OLD_OLD'" "" \
                    "${E_NOTE}Please remove '$C_BOT_DIR_OLD_OLD' manually"
        fi
    } || E_STDERR "Failed to restore '$E_BOT_DIR'" "$?" \
        "${E_NOTE}We will exit completely to prevent data loss"

    if [[ $exit_now == false ]]; then
        read -rp "${E_NOTE}Press [Enter] to return to the main menu"
    fi

    exit "$exit_code"
}

####
# Retrieves all available NadekoBot versions from the GitLab API and prompts the user to
# select one for installation.
#
# NEW GLOBALS:
#   - C_BOT_VERSION: The selected NadekoBot version to install.
#   - C_ARCHIVE_NAME: The filename of the archive to download.
#   - C_ARCHIVE_URL: The direct URL for downloading the archive.
#
# EXITS:
#   - 1: If fetching releases from the GitLab API fails or if no releases are found.
fetch_versions() {
    local response; response=$(curl -sS -w "%{http_code}" "${API_URL}/releases")
    local http_code="${response: -3}"
    local response_body="${response:0:${#response}-3}"
    local versions

    if (( http_code != 200 )); then
        E_STDERR "Failed to fetch releases from '${API_URL}'" "1"
    fi

    # TODO: Confirm that the '||' operator works as intended.
    # Convert the JSON response to an array of version tags, sorted in reverse order.
    mapfile -t versions < <(echo "$response_body" | jq -r '.[].tag_name' | sort -V -r) \
        || E_STDERR "Failed to parse releases" "1"

    if (( ${#versions[@]} == 0 )); then
        E_STDERR "No releases found" "1"
    fi

    echo "${E_NOTE}Select version to install:"
    select version in "${versions[@]}"; do
        if [[ -n $version ]]; then
            C_BOT_VERSION="$version"
            C_ARCHIVE_NAME="nadekobot-v${version}.tar"
            C_ARCHIVE_URL="$API_URL/packages/generic/NadekoBot-build/$C_BOT_VERSION/${C_BOT_VERSION}-linux-${E_ARCH}-build.tar"
            break
        else
            echo "${E_ERROR}Invalid selection"
        fi
    done
}


####[ Trapping Logic ]##################################################################


trap 'clean_exit "129" "true"' SIGHUP
trap 'clean_exit "130" "true"' SIGINT
trap 'clean_exit "143" "true"' SIGTERM
trap 'clean_exit "$?" "true"'  EXIT


####[ Main ]############################################################################


read -rp "${E_NOTE}We will now set up NadekoBot. Press [Enter] to begin."
pushd "$C_NADEKOBOT_TMP" >/dev/null \
    || E_STDERR "Failed to change working directory to '$C_NADEKOBOT_TMP'" "1"

if [[ $E_BOT_SERVICE_STATUS == "active" ]]; then
    service_is_active=true
    E_STOP_SERVICE
fi

fetch_versions

###
### [ Download NadekoBot Archive ]
###

echo "${E_INFO}Downloading '${C_BOT_VERSION}' for '${E_ARCH}'..."
curl -L -o "$C_ARCHIVE_NAME" "$C_ARCHIVE_URL" \
    || E_STDERR "Failed to download '${C_BOT_VERSION}'" "1"

echo "${E_INFO}Extracting '${C_ARCHIVE_NAME}'..."
tar -xf "$C_ARCHIVE_NAME" || E_STDERR "Failed to extract '${C_ARCHIVE_NAME}'" "1"

archive_dir_name=$(tar -tf "$C_ARCHIVE_NAME" | head -1 | cut -f1 -d "/")
mv "$archive_dir_name" "$E_BOT_DIR"
unset archive_dir_name
chmod +x "${E_BOT_DIR}/${E_BOT_EXE}"
popd >/dev/null || E_STDERR "Failed to change directory back to '$E_ROOT_DIR'" "1"


###
### [ Move Credentials, Database, and Other Data ]
###
### Moves the credentials, database, and other NadekoBot data to the new version
### directory. In case '$E_BOT_DIR' already exists, it is renamed to '$C_BOT_DIR_OLD'
### (with a further fallback of '$C_BOT_DIR_OLD_OLD'), making it easier to revert to a
### previous version if needed.
###

(
    if [[ ! -f $E_CREDS_PATH ]]; then
        echo "${E_INFO}Copying '${C_EXAMPLE_CREDS_PATH##*/}' as" \
            "'${C_NEW_CREDS_PATH##*/}' to '${C_NEW_CREDS_PATH%/*}'..."
        cp -f "$C_EXAMPLE_CREDS_PATH" "$C_NEW_CREDS_PATH" || exit 1
    else
        echo "${E_INFO}Copying '${C_NEW_CREDS_PATH##*/}' to '${C_NEW_CREDS_PATH%/*}'..."
        cp -f "$E_CREDS_PATH" "$C_NEW_CREDS_PATH" || exit 1
    fi
) || E_STDERR "Failed to copy credentials" "$?"


if [[ -d $E_BOT_DIR ]]; then
    if [[ ! -f $C_CURRENT_DB_PATH ]]; then
        echo "${E_WARN}'$C_CURRENT_DB_PATH' could not be found"
        echo "${E_NOTE}Skipping copying the database..."
    else
        echo "${E_INFO}Copying '${C_CURRENT_DB_PATH}' to the '${C_NEW_DB_PATH%/*}'..."
        cp -rT "$C_CURRENT_DB_PATH" "$C_NEW_DB_PATH" \
            || E_STDERR "Failed to copy database" "1"
    fi

    echo "${E_INFO}Copying other data to the new version..."
    (
        ## Temporarily rename the new version's strings and aliases so they won't be
        ## overwritten.
        mv -fT "$C_NEW_DATA_PATH"/strings "$C_NEW_DATA_PATH"/strings.new || exit 1
        mv -f "$C_NEW_DATA_PATH"/aliases.yml "$C_NEW_DATA_PATH"/aliases.new.yml || exit 1

        # Copy current data directory into the new one, overwriting matching
        # files/folders.
        cp -rT "$C_CURRENT_DATA_PATH" "$C_NEW_DATA_PATH" || exit 1

        # Remove any old backups of strings and aliases.
        rm -rf "$C_NEW_DATA_PATH"/strings.old "$C_NEW_DATA_PATH"/aliases.old.yml \
            2>/dev/null

        ## Back up the overwritten strings and aliases before restoring the new ones.
        mv -fT "$C_NEW_DATA_PATH"/strings "$C_NEW_DATA_PATH"/strings.old || exit 1
        mv -f "$C_NEW_DATA_PATH"/aliases.yml "$C_NEW_DATA_PATH"/aliases.old.yml || exit 1

        ## Restore the new version's strings and aliases.
        mv -fT "$C_NEW_DATA_PATH"/strings.new "$C_NEW_DATA_PATH"/strings || exit 1
        mv -f "$C_NEW_DATA_PATH"/aliases.new.yml "$C_NEW_DATA_PATH"/aliases.yml || exit 1
    ) || E_STDERR "An error occurred while copying other data" "$?"

    echo "${E_INFO}Replacing '$E_BOT_DIR' with '$C_NADEKOBOT_TMP/$E_BOT_DIR'..."
    (
        if [[ -d $C_BOT_DIR_OLD ]]; then
            mv "$C_BOT_DIR_OLD" "$C_BOT_DIR_OLD_OLD" || exit 5
        fi

        mv "$E_BOT_DIR" "$C_BOT_DIR_OLD" || exit 5
        mv "$C_NADEKOBOT_TMP/$E_BOT_DIR" "$E_BOT_DIR" || exit 5

        if [[ -d $C_BOT_DIR_OLD_OLD ]]; then
            rm -rf "$C_BOT_DIR_OLD_OLD" \
                || E_STDERR "Failed to remove '$C_BOT_DIR_OLD_OLD'" "" \
                    "${E_NOTE}Please remove '$C_BOT_DIR_OLD_OLD' manually"
        fi
    ) || E_STDERR "An error occurred while replacing '$E_BOT_DIR'" "$?"
else
    echo "${E_INFO}Moving '$C_NADEKOBOT_TMP/$E_BOT_DIR' to '$E_BOT_DIR'..."
    mv "$C_NADEKOBOT_TMP/$E_BOT_DIR" "$E_ROOT_DIR" \
        || E_STDERR "Failed to move '${C_NADEKOBOT_TMP}' to '$E_BOT_DIR'" "1"
    rmdir "$C_NADEKOBOT_TMP" &>/dev/null
fi

###
### [ Clean Up and Present Results ]
###

echo ""
echo "${E_SUCCESS}Finished setting up NadekoBot"

if [[ $service_is_active == true ]]; then
    echo "${E_NOTE}'$E_BOT_SERVICE' was stopped to update NadekoBot and needs to be" \
        "started using one of the run modes in the manager menu"
fi

clean_exit 0
