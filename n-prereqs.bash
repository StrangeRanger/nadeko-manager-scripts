#!/bin/bash
#
# Installs the prerequisites required by NadekoBot on Linux distributions.
#
########################################################################################
####[ Global Variables ]################################################################


declare -A -r C_SUPPORTED_DISTROS=(
    ["ubuntu"]="22.04 24.04"
    ["debian"]="12"
    ["linuxmint"]="21 22"
    ["fedora"]="40 41"
    ["almalinux"]="8 9"
    ["rocky"]="8 9"
    ["opensuse-leap"]="15.6"
    ["opensuse-tumbleweed"]="any"
    ["arch"]="any"
)

declare -A -r C_UPDATE_CMD_MAPPING=(
    ["ubuntu"]="sudo apt-get update"
    ["debian"]="sudo apt-get update"
    ["linuxmint"]="sudo apt-get update"
    ["fedora"]="sudo dnf makecache"
    ["almalinux"]="sudo dnf makecache"
    ["rocky"]="sudo dnf makecache"
    ["opensuse-leap"]="sudo zypper refresh"
    ["opensuse-tumbleweed"]="sudo zypper refresh"
    ["arch"]="sudo pacman -Sy"
)

declare -A -r C_INSTALL_CMD_MAPPING=(
    ["ubuntu"]="sudo apt-get install -y"
    ["debian"]="sudo apt-get install -y"
    ["linuxmint"]="sudo apt-get install -y"
    ["fedora"]="sudo dnf install -y"
    ["almalinux"]="sudo dnf install -y"
    ["rocky"]="sudo dnf install -y"
    ["opensuse-leap"]="sudo zypper install -y"
    ["opensuse-tumbleweed"]="sudo zypper install -y"
    ["arch"]="sudo pacman -S --noconfirm"
)

declare -A -r C_MANAGER_PKG_MAPPING=(
    ["ubuntu"]="wget curl ccze jq"
    ["debian"]="wget curl ccze jq"
    ["linuxmint"]="wget curl ccze jq"
    ["fedora"]="wget curl ccze jq"
    ["almalinux"]="wget curl ccze jq"
    ["rocky"]="wget curl ccze jq"
    ["opensuse-leap"]="wget curl ccze jq tar awk"
    ["opensuse-tumbleweed"]="wget curl ccze jq tar awk"
    ["arch"]="wget curl jq"  # 'ccze' gets installed separately.
)

declare -A -r C_MUSIC_PKG_MAPPING=(
    ["ubuntu"]="python3 ffmpeg"
    ["debian"]="python3 ffmpeg"
    ["linuxmint"]="python3 ffmpeg"
    ["fedora"]="python3 ffmpeg"
    ["almalinux"]="python3 ffmpeg"
    ["rocky"]="python3 ffmpeg"
    ["opensuse-leap"]="python3 ffmpeg yt-dlp"
    ["opensuse-tumbleweed"]="python3 ffmpeg yt-dlp"
    ["arch"]="python3 ffmpeg yt-dlp"
)


####[ Functions ]#######################################################################


####
# Identify the system's distribution, version, and architecture.
#
# NOTE:
#   The 'os-release' file is used to determine the distribution and version. This file
#   is present on almost every distributions running systemd.
#
# NEW GLOBALS:
#   - C_DISTRO: The distribution name.
#   - C_VER: The distribution version.
#   - C_SVER: The distribution version without the minor version.
detect_sys_info() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        C_DISTRO="$ID"
        C_VER="$VERSION_ID"  # Version: x.x.x...
        C_SVER=${C_VER//.*/}  # Version: x
    else
        C_DISTRO=$(uname -s)
        C_VER=$(uname -r)
    fi
}


####
# Cleanly exits the script by removing traps and displaying an exit message.
#
# PARAMETERS:
#   - $1: exit_code (Required)
#       - The exit code passed by the caller. This may be changed to 50 in certain cases
#         (e.g., exit codes 1 or 130) to allow a parent manager script to continue.
#   - $2: use_extra_newline (Optional, Default: false)
#       - If "true", outputs an extra blank line to separate previous output from the
#         exit message.
#       - Valid values:
#           - true
#           - false
#
# EXITS:
#   - $exit_code: The final exit code, which may be 50 if conditions for continuing are
#     met.
clean_exit() {
    local exit_code="$1"
    local use_extra_newline="${2:-false}"
    local exit_now=false

    trap - EXIT SIGINT
    [[ $use_extra_newline == true ]] && echo ""

    ## The exit code may become 50 if 'n-update.bash' should continue despite
    ## an error. See 'exit_code_actions' for more details.
    case "$exit_code" in
        1) exit_code=50 ;;
        0|5) ;;
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

####
# Installs 'yt-dlp' to '~/.local/bin/yt-dlp', creating the directory if needed.
#
# EXITS:
#   - 1: If 'yt-dlp' fails to download.
install_yt_dlp() {
    local yt_dlp_url="https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp"
    local yt_dpl_dir="${E_YT_DLP_PATH%/*}"

    [[ -d $yt_dpl_dir ]] || mkdir -p "$yt_dpl_dir"

    if [[ ! -f $E_YT_DLP_PATH ]]; then
        echo "${E_INFO}Installing 'yt-dlp'..."
        curl -L "$yt_dlp_url" -o "$E_YT_DLP_PATH" \
            || E_STDERR "Failed to download 'yt-dlp'" "1"
    fi

    echo "${E_INFO}Modifying permissions for 'yt-dlp'..."
    chmod a+rx "$E_YT_DLP_PATH"
}

####
# Perform checks or other actions that might be necessary before installing packages.
#
# PARAMETERS:
#   - $1: distro (Required)
#       - The distribution name.
#   - $2: update_cmd (Required)
#       - The command used to update package lists.
initial_checks() {
    local distro="$1"
    local update_cmd="$2"

    echo "${E_INFO}Performing initial checks for '$distro'..."

    case "$distro" in
        rocky|almalinux)
            local el_ver; el_ver=$(rpm -E %rhel)
            echo "${E_INFO}Updating package lists"
            $update_cmd
            echo "${E_INFO}Installing EPEL and RPM Fusion for EL${el_ver} ($distro)..."
            dnf install -y epel-release
            dnf install -y "https://download1.rpmfusion.org/free/el/rpmfusion-free-release-${el_ver}.noarch.rpm"
            echo "${E_INFO}Enabling CRB repository..."
            # TODO: Verify if the CRB is enabled by default on non-docker installations.
            dnf config-manager --set-enabled crb || echo "${E_WARN}CRB repository could not be enabled, continuing..."
            ;;
        fedora)
            local fedora_ver; fedora_ver=$(rpm -E %fedora)
            echo "${E_INFO}Updating package lists"
            $update_cmd
            echo "${E_INFO}Installing RPM Fusion for Fedora $fedora_ver..."
            dnf install -y "https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-${fedora_ver}.noarch.rpm"
            ;;
    esac
}

install_ccze_arch() {
    echo "${E_INFO}Installing 'ccze' for Arch Linux from the AUR..."

    # Check if 'yay' is installed.
    if command -v yay &>/dev/null; then
        yay -S --noconfirm ccze || E_STDERR "Failed to install 'ccze' from the AUR" "$?"
    elif command -v paru &>/dev/null; then
        paru -S --noconfirm ccze || E_STDERR "Failed to install 'ccze' from the AUR" "$?"
    else
        echo "${E_ERROR}AUR helper not found. Please install 'yay' or 'paru' to" \
            "continue." >&2
        exit 1  # TODO: Determine if this is the correct exit code.
    fi
}

# TODO: Update description to reflect to use of different package managers.
####
# Installs all prerequisites required by NadekoBot. Runs 'apt' in the background so
# signals (e.g., SIGINT) can be caught, allowing the script to terminate 'apt' if
# needed.
#
# NEW GLOBALS:
#   - pkg_pid: The process ID of the package manager, killed if the script exits.
#
# PARAMETERS:
#   - $1: install_cmd (Required)
#       - The command used to install packages.
#   - $2: update_cmd (Required)
#       - The command used to update package lists.
#   - $3: music_pkg_list (Required)
#       - A list of packages required for music playback.
#   - $4: manager_pkg_list (Required)
#       - A list of other packages required by the manager.
#
# EXITS:
#   - 0: Successful installation of all prerequisites.
#   - $?: Failed to install prerequisites or remove existing .NET installation.
install_prereqs() {
    local install_cmd="$1"
    local update_cmd="$2"
    local music_pkg_list="$3"
    local manager_pkg_list="$4"
    local yt_dlp_found=false

    echo "${E_INFO}Checking for 'yt-dlp'..."
    # If 'yt-dlp' is NOT inside "${music_pkg_list[@]}", then we install it via
    # 'install_yt_dlp'.
    for pkg in $music_pkg_list; do
        if [[ "$pkg" == "yt-dlp" ]]; then
            yt_dlp_found=true
            break
        fi
    done

    # shellcheck disable=SC2086
    #   We want to expand the array into individual arguments (packages).
    {
        echo "${E_INFO}Updating package lists..."
        $update_cmd || E_STDERR "Failed to update package lists" "$?"

        echo "${E_INFO}Installing music prerequisites..."
        $install_cmd $music_pkg_list \
            || E_STDERR "Failed to install music prerequisites" "$?"

        echo "${E_INFO}Installing other prerequisites..."
        $install_cmd $manager_pkg_list \
            || E_STDERR "Failed to install other prerequisites" "$?"

        # While this reduces the dynamic nature of the script, it's a necessary evil.
        if [[ $C_DISTRO == "arch" ]]; then
            install_ccze_arch
        fi
    }

    if [[ $yt_dlp_found == false ]]; then
        install_yt_dlp
    fi

    echo -en "\n${E_SUCCESS}Finished installing prerequisites"
}

####
# Displays a message indicating that the current OS is unsupported for automatic
# NadekoBot prerequisite installation.
#
# EXITS:
#   - 4: The current OS is unsupported.
unsupported() {
    echo "${E_ERROR}The manager does not support the automatic installation and setup" \
        "of NadekoBot's prerequisites for your OS" >&2
    read -rp "${E_NOTE}Press [Enter] to return to the main menu"
    exit 4
}


####[ Trapping Logic ]##################################################################


trap 'clean_exit "129"' SIGHUP
trap 'clean_exit "130"' SIGINT
trap 'clean_exit "143"' SIGTERM
trap 'clean_exit "$?"'  EXIT


####[ Main ]############################################################################


printf "%sWe will now install NadekoBot's prerequisites. " "$E_NOTE"
read -rp "Press [Enter] to continue."

detect_sys_info

for version in ${C_SUPPORTED_DISTROS[$C_DISTRO]}; do
    if [[ $version == "$C_VER" || $version == "$C_SVER" || $version == "any" ]]; then
        initial_checks "$C_DISTRO" "${C_UPDATE_CMD_MAPPING[$C_DISTRO]}"
        install_prereqs "${C_INSTALL_CMD_MAPPING[$C_DISTRO]}" \
            "${C_UPDATE_CMD_MAPPING[$C_DISTRO]}" "${C_MUSIC_PKG_MAPPING[$C_DISTRO]}" \
            "${C_MANAGER_PKG_MAPPING[$C_DISTRO]}"
        clean_exit 0 "true"
    fi
done

unsupported
