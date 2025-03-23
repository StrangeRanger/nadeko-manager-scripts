#!/bin/bash
#
# NadekoBot Setup/Update Script
#
# This script automates the update process for NadekoBot (major version 5). It stops the
# NadekoBot service if it is active, retrieves available releases from the GitLab API,
# and prompts the user to select a version for installation. The script then downloads
# and extracts the chosen archive, migrates credentials, the database, and other data
# (backing up custom strings and aliases), and replaces the existing installation with
# the new version.
#
# NOTE:
#   After each update, any custom modifications to strings and aliases must be
#   re-applied manually. However, backups of the previous versions are saved as
#   'strings.old' and 'aliases.old.yml'.
#
########################################################################################
####[ Variables ]#######################################################################


C_NADEKOBOT_TMP=$(mktemp -d -p /tmp nadekobot-XXXXXXXXXX)
readonly C_NADEKOBOT_TMP
readonly C_NADEKO_MAJOR_VERSION="6"

## File paths.
readonly C_BOT_DIR_TMP="$C_NADEKOBOT_TMP/$E_BOT_DIR"
readonly C_BOT_DIR_OLD="$E_BOT_DIR.old"
readonly C_BOT_DIR_OLD_OLD="$E_BOT_DIR.old.old"
readonly C_EXAMPLE_CREDS_PATH="$C_BOT_DIR_TMP/data/$E_CREDS_EXAMPLE"
readonly C_NEW_CREDS_PATH="$C_NADEKOBOT_TMP/$E_CREDS_PATH"
readonly C_CURRENT_DB_PATH="$E_BOT_DIR/data/NadekoBot.db"
readonly C_NEW_DB_PATH="$C_BOT_DIR_TMP/data/NadekoBot.db"
readonly C_CURRENT_DATA_PATH="$E_BOT_DIR/data"
readonly C_NEW_DATA_PATH="$C_BOT_DIR_TMP/data"

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
#       - Whether to output an extra newline before the exit message.
#       - Acceptable values: true, false
#
# EXITS:
#   - $exit_code: The final exit code.
clean_exit() {
    local exit_code="$1"
    local use_extra_newline="${2:-false}"
    local exit_now=false

    # Remove the exit and sigint trap to prevent re-entry after exiting and repeated
    # sigint signals.
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

    ## Attempt to restore the original $E_BOT_DIR if necessary.
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
# Compare two version strings and determine if one is newer, older, or the same as the
# other. This is done by splitting the version strings into parts and comparing each
# part, starting from the major number to the patch number.
#
# PARAMETERS:
#   - $1: version_a (Required)
#       - The version that will be compared.
#   - $2: version_b (Required)
#       - The version to compare against.
#
# RETURNS:
#   - newer: If version_a is newer than version_b.
#   - older: If version_a is older than version_b.
#   - equal: If version_a is the same as version_b.
compare_versions() {
    local version_a="$1"
    local version_a_major version_a_minor version_a_patch
    local version_b="$2"
    local version_b_major version_b_minor version_b_patch
    local IFS='.'

    read -r version_a_major version_a_minor version_a_patch <<< "$version_a"
    read -r version_b_major version_b_minor version_b_patch <<< "$version_b"

    if (( version_a_major > version_b_major )); then
        echo "newer"
    elif (( version_a_major < version_b_major )); then
        echo "older"
    elif (( version_a_minor > version_b_minor )); then
        echo "newer"
    elif (( version_a_minor < version_b_minor )); then
        echo "older"
    elif (( version_a_patch > version_b_patch )); then
        echo "newer"
    elif (( version_a_patch < version_b_patch )); then
        echo "older"
    else
        echo "equal"
    fi
}

####
# Retrieves all available NadekoBot versions from the GitHub API and prompts the user to
# select one for installation.
#
# NEW GLOBALS:
#   - C_BOT_VERSION: The selected NadekoBot version to install.
#   - C_ARCHIVE_NAME: The filename of the archive to download.
#   - C_ARCHIVE_URL: The direct URL for downloading the archive.
#
# EXITS:
#   - 1: If an invalid comparison result is detected.
#   - 0: If the user declines to continue after selecting a version.
fetch_versions() {
    local -a available_versions displayable_versions
    local -A version_comparison_map
    local version_comparison_results current_version
    local IFS='.'
    local api_tag_url="https://api.github.com/repos/nadeko-bot/nadekobot/tags"
    local release_url="https://github.com/nadeko-bot/nadekobot/releases/download"
    # shellcheck disable=SC2016
    #   This is a jq filter string, not a shell command that needs to be expanded.
    local jq_filter='map(select(.name | startswith($major))) | .[].name'

    ## Retrieve available versions of NadekoBot from the GitHub API.
    mapfile -t available_versions < <(
        curl -sSf "$api_tag_url" \
            | jq -r --arg major "$C_NADEKO_MAJOR_VERSION" "$jq_filter"
    )

    ## Get current version of NadekoBot, if it's installed.
    if [[ -f $E_ROOT_DIR/$E_BOT_DIR/$E_BOT_EXE ]]; then
        current_version=$("$E_ROOT_DIR"/"$E_BOT_DIR"/"$E_BOT_EXE" --version)

        if [[ ! $current_version =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            echo "${E_WARN}Unable to determine the current version of NadekoBot"
            current_version=""
        fi
    fi

    ## Colorize each version based on its comparison to the current version.
    for version in "${available_versions[@]}"; do
        if [[ -n $current_version ]]; then
            ## Compare the two versions and save the results for later use.
            version_comparison_results=$(compare_versions "$version" "$current_version")
            version_comparison_map["$version"]=$version_comparison_results

            if [[ $version_comparison_results == "older" ]]; then
                displayable_versions+=("${E_RED}$version${E_NC}")
            elif [[ $version_comparison_results == "newer" ]]; then
                displayable_versions+=("${E_GREEN}$version${E_NC}")
            elif [[ $version_comparison_results == "equal" ]]; then
                displayable_versions+=("${E_BLUE}$version${E_NC}")
            else
                echo "${E_ERROR}INTERNAL: Invalid comparison result" >&2
                exit 1
            fi
        else
            displayable_versions+=("$version")
        fi
    done

    echo -e "${E_NOTE}Select version to install:"
    select version in "${displayable_versions[@]}"; do
        ## Ensure the non-color-coded version is selected/used.
        local version_index=$((REPLY - 1))
        local selected_version="${available_versions[$version_index]}"

        if [[ -n $selected_version ]]; then
            if [[ -n $current_version ]]; then
                local status=${version_comparison_map["$selected_version"]}

                if [[ $status == "older" ]]; then
                    echo -n "${E_WARN}Downgrading can result in data loss. "
                    read -rp "Are you sure you want to continue? [y/N]: " confirm
                elif [[ $status == "newer" ]]; then
                    echo -n "${E_NOTE}You are about to update to a newer version. "
                    read -rp "Continue? [y/N]: " confirm
                elif [[ $status == "equal" ]]; then
                    echo -n "${E_NOTE}You are about to reinstall the same version. "
                    read -rp "Continue? [y/N]: " confirm
                else
                    echo "${E_ERROR}INTERNAL: Invalid comparison result" >&2
                    exit 1
                fi

                echo ""
                confirm=${confirm,,}
                [[ ! $confirm =~ ^y ]] && exit 0
            fi

            C_BOT_VERSION="$selected_version"
            C_ARCHIVE_NAME="nadekobot-v${selected_version}.tar.gz"
            C_ARCHIVE_URL="$release_url/$selected_version/nadeko-linux-${E_ARCH}.tar.gz"
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

echo "${E_INFO}Downloading '${C_BOT_VERSION}' for 'linux-${E_ARCH}'..."
curl -L -o "$C_ARCHIVE_NAME" "$C_ARCHIVE_URL" \
    || E_STDERR "Failed to download '${C_BOT_VERSION}'" "1"

echo "${E_INFO}Extracting '${C_ARCHIVE_NAME}'..."
mkdir -p "$E_BOT_DIR"
tar -xzf "$C_ARCHIVE_NAME" -C "$E_BOT_DIR" --strip-components=1 \
    || E_STDERR "Failed to extract '${C_ARCHIVE_NAME}'" "1"
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
