#!/bin/bash
#
# NadekoBot Prerequisites Installer Script
#
# This script automates the installation of NadekoBot's prerequisites on supported Linux
# distributions. It detects the system's OS and version, validates compatibility against a
# predefined list, and then executes distro-specific pre-installation checks, package list
# updates, and installation commands.
#
# Key tasks include installing required packages (e.g., Python, ffmpeg, jq, ccze, yt-dlp),
# handling special configuration steps (such as enabling extra repositories or creating
# symlinks), and performing post-installation adjustments. If the OS is unsupported, the
# script notifies the user and exits gracefully.
#
############################################################################################
####[ Global Variables ]####################################################################


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

# NOTE:
#   The update command for arch is empty because running 'pacman -Sy' without '-u' is
#   discouraged; this avoids unintentionally upgrading the system or existing packages.
declare -A -r C_UPDATE_CMD_MAPPING=(
    ["ubuntu"]="sudo apt-get update"
    ["debian"]="sudo apt-get update"
    ["linuxmint"]="sudo apt-get update"
    ["fedora"]="sudo dnf makecache"
    ["almalinux"]="sudo dnf makecache"
    ["rocky"]="sudo dnf makecache"
    ["opensuse-leap"]="sudo zypper refresh"
    ["opensuse-tumbleweed"]="sudo zypper refresh"
    ["arch"]=""
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
    ["ubuntu"]="ccze jq"
    ["debian"]="ccze jq"
    ["linuxmint"]="ccze jq"
    ["fedora"]="ccze jq"
    ["almalinux"]="ccze jq"
    ["rocky"]="ccze jq"
    ["opensuse-leap"]="ccze jq tar"  # TODO: Check if 'tar' is installed by default.
    ["opensuse-tumbleweed"]="ccze jq"
    ["arch"]="jq"  # 'ccze' gets installed separately via AUR.
)

# NOTE:
#   - The script requires Python 3.9+ for proper operation.
#   - almalinux 8: 'python3' installs Python 3.6, so 'python311' is explicitly installed.
#   - rocky 8: 'python3' installs Python 3.6, so 'python311' is explicitly installed.
#   - opensuse-tumbleweed: Installing 'yt-dlp' automatically installs 'ffmpeg' (ffmpeg-7)
#     and 'python3' (python311-yt-dlp) packages (as of 2025-02-07).
#   - opensuse-leap: Installing 'yt-dlp' auto-installs 'ffmpeg' (ffmpeg-4) and 'python3'
#     (python311-yt-dlp) packages (as of 2025-02-07).
#       - 'python311' is still explicitly installed to ensure the expected version, allowing
#         a reliable symlink from 'python3' to 'python311'.
#   - arch: Installing 'yt-dlp' auto-installs the 'python3' package.
#     NOTE: Installing 'ffmpeg' will also install 'jack2'. If you prefer 'pipewire-jack' for
#     better PipeWire integration, consider replacing 'jack2' with 'pipewire-jack' in the
#     package list. More info at https://wiki.archlinux.org/title/JACK_Audio_Connection_Kit.
declare -A -r C_MUSIC_PKG_MAPPING=(
    ["ubuntu"]="python3 ffmpeg"
    ["debian"]="python3 ffmpeg"
    ["linuxmint"]="python3 ffmpeg"
    ["fedora"]="python3 ffmpeg-free"
    ["almalinux"]="python311 ffmpeg"
    ["rocky"]="python311 ffmpeg"
    ["opensuse-leap"]="python311 ffmpeg"
    ["opensuse-tumbleweed"]="python311 ffmpeg"
    ["arch"]="ffmpeg yt-dlp"
)


####[ Functions ]###########################################################################


####
# Identify the system's distribution and version number.
#
# NEW GLOBALS:
#   - C_DISTRO: The distribution name (or kernel name if '/etc/os-release' is absent).
#   - C_VER: The full distribution version (or kernel version when falling back).
#   - C_SVER: The major version number extracted from $C_VER.
detect_sys_info() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        C_DISTRO="$ID"
        C_VER="$VERSION_ID"  # Format: x.y.z...
        C_SVER=${C_VER%%.*}  # Major version: x
    else
        C_DISTRO=$(uname -s)
        C_VER=$(uname -r)
        C_SVER=${C_VER%%.*}
    fi
}

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
    local exit_now=false

    # Remove the exit and sigint trap to prevent re-entry after exiting and repeated sigint
    # signals.
    # Remove the other traps, as they are no longer needed.
    trap - EXIT SIGINT SIGHUP SIGTERM
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

    if [[ $exit_now == false ]]; then
        read -rp "${E_NOTE}Press [Enter] to return to the Manager menu"
    fi

    exit "$exit_code"
}

####
# Display a message indicating that the current OS is unsupported for the automatic
# installation of NadekoBot's prerequisites.
#
# EXITS:
#   - 4: The current OS is unsupported.
unsupported() {
    echo "${E_ERROR}The Manager does not support the automatic installation and setup of" \
        "NadekoBot's prerequisites for your OS" >&2
    read -rp "${E_NOTE}Press [Enter] to return to the main menu"
    exit 4
}

####
# Create the local bin directory if it doesn't exist.
create_local_bin() {
    if [[ ! -d $E_LOCAL_BIN ]]; then
        echo "${E_INFO}Creating '$E_LOCAL_BIN'..."
        mkdir -p "$E_LOCAL_BIN"
    fi
}

###
### [ Install-based Functions ]
###

####
# Install 'yt-dlp' to '~/.local/bin/yt-dlp' and modify its permissions.
#
# EXITS:
#   - 1: If 'yt-dlp' fails to download.
install_yt_dlp() {
    local yt_dlp_url="https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp"

    create_local_bin

    if [[ ! -f $E_YT_DLP_PATH ]]; then
        echo "${E_INFO}Installing 'yt-dlp'..."
        curl -L "$yt_dlp_url" -o "$E_YT_DLP_PATH" \
            || E_STDERR "Failed to download 'yt-dlp'" "1"
    fi

    echo "${E_INFO}Modifying permissions for 'yt-dlp'..."
    chmod a+rx "$E_YT_DLP_PATH"
}

####
# Install 'ccze' for Arch Linux from the AUR, using an AUR helper if available.
#
# EXITS:
#   - Non-zero exit code: If any installation step fails.
install_ccze_arch() {
    if command -v ccze &>/dev/null; then
        echo "${E_INFO}'ccze' is already installed, skipping..."
        return
    fi

    echo "${E_INFO}Installing 'ccze' for Arch Linux from the AUR..."

    if command -v yay &>/dev/null; then
        yay -S --noconfirm --mflags "--rmdeps" ccze \
            || E_STDERR "Failed to install 'ccze' from the AUR" "$?"
    elif command -v paru &>/dev/null; then
        paru -S --noconfirm --mflags "--rmdeps" ccze \
            || E_STDERR "Failed to install 'ccze' from the AUR" "$?"
    else
        local ccze_tmp_dir="/tmp/ccze"

        echo "${E_WARN}AUR helper not found, continuing with manual installation..."
        echo "${E_NOTE}We need to install additional build tools and clone the AUR package"
        echo "${E_NOTE}  'base-devel' and 'git' will be installed"
        read -rp "${E_NOTE}Would you like to continue? [y/N] " confirm

        confirm=${confirm,,}
        if [[ ! $confirm =~ ^y ]]; then
            echo "${E_WARN}Installation of 'ccze' and its build tools aborted by user"
            echo "${E_WARN}'ccze' is required to colorize NadekoBot's logs"
            return 1
        fi

        echo "${E_INFO}Installing necessary build tools..."
        sudo pacman -S --needed base-devel git

        echo "${E_INFO}Cloning the AUR package..."
        git clone https://aur.archlinux.org/ccze.git "$ccze_tmp_dir"

        pushd "$ccze_tmp_dir" >/dev/null || E_STDERR "Failed to change to '$ccze_tmp_dir'" "1"
        echo "${E_INFO}Building and installing 'ccze'..."
        makepkg -si || E_STDERR "Failed to build and install 'ccze'" "$?"
        popd >/dev/null || E_STDERR "Failed to change back to the previous directory" "1"

        echo "${E_INFO}Cleaning up..."
        rm -rf "$ccze_tmp_dir" &>/dev/null
    fi
}

####
# Install all prerequisites required by NadekoBot using the provided package manager
# commands.
#
# PARAMETERS:
#   - $1: install_cmd (Required)
#       - The command used to install packages.
#   - $2: update_cmd (Required)
#       - The command used to update package lists.
#   - $3: music_pkg_list (Required)
#       - A list of packages required for music playback.
#   - $4: manager_pkg_list (Required)
#       - A list of other packages required by the Manager.
#
# EXITS:
#   - $?: If any of the installation steps fail.
install_prereqs() {
    local install_cmd="$1"
    local update_cmd="$2"
    local music_pkg_list="$3"
    local manager_pkg_list="$4"
    local yt_dlp_found=false

    echo "${E_INFO}Checking for 'yt-dlp'..."
    # If 'yt-dlp' is NOT in the music package list, mark it for separate installation.
    for pkg in $music_pkg_list; do
        if [[ "$pkg" == "yt-dlp" ]]; then
            yt_dlp_found=true
            break
        fi
    done

    # shellcheck disable=SC2086
    #   We want to expand the package lists into individual arguments.
    {
        if [[ -z $update_cmd ]]; then
            echo "${E_WARN}No update command provided, skipping package list update..."
        else
            echo "${E_INFO}Updating package lists..."
            $update_cmd || E_STDERR "Failed to update package lists" "$?"
        fi

        echo "${E_INFO}Installing music prerequisites..."
        $install_cmd $music_pkg_list || E_STDERR "Failed to install music prerequisites" "$?"

        echo "${E_INFO}Installing other prerequisites..."
        $install_cmd $manager_pkg_list || E_STDERR "Failed to install other prerequisites" "$?"

        # While this reduces the dynamic nature of the script, it's a necessary evil.
        [[ $C_DISTRO == "arch" ]] && install_ccze_arch
    }

    [[ $yt_dlp_found == false ]] && install_yt_dlp
}

####
# Perform pre-installation checks and configurations before installing the main packages.
#
# PARAMETERS:
#   - $1: distro (Required)
pre_install() {
    local distro="$1"

    echo "${E_INFO}Performing pre install checks for '$distro'..."

    case "$distro" in
        rocky|almalinux)
            local el_ver; el_ver=$(rpm -E %rhel)
            local rmpfusion_key_path="/usr/share/distribution-gpg-keys/rpmfusion/RPM-GPG-KEY-rpmfusion-free-el-$el_ver"
            local rmpfusion_url="https://mirrors.rpmfusion.org/free/el/rpmfusion-free-release-$el_ver.noarch.rpm"

            echo "${E_INFO}Updating package lists..."
            sudo dnf update -y

            echo "${E_INFO}Installing EPEL repository..."
            sudo dnf install -y epel-release

            if [[ $el_ver == "8" ]]; then
                echo "${E_INFO}Enabling PowerTools repository..."
                sudo dnf config-manager --set-enabled powertools \
                    || echo "${E_WARN}PowerTools repository could not be enabled" >&2
            elif [[ $el_ver == "9" ]]; then
                echo "${E_INFO}Enabling CRB repository..."
                sudo dnf config-manager --set-enabled crb \
                    || echo "${E_WARN}CRB repository could not be enabled" >&2
            fi

            (
                echo "${E_INFO}Installing distribution-gpg-keys..."
                sudo dnf install -y distribution-gpg-keys || exit "$?"

                echo "${E_INFO}Importing RPM Fusion key..."
                sudo rpmkeys --import "$rmpfusion_key_path" || exit "$?"

                echo "${E_INFO}Installing RPM Fusion for EL $el_ver..."
                sudo dnf --setopt=localpkg_gpgcheck=1 install -y "$rmpfusion_url" || exit "$?"
            ) || E_STDERR "Failed to install RPM Fusion for EL $el_ver" "$?"

            [[ $el_ver == "8" ]] && create_local_bin
            ;;
        opensuse-leap)
            create_local_bin
            ;;
    esac
}

####
# Perform post-installation checks and configurations after installing the main packages.
#
# PARAMETERS:
#   - $1: distro (Required)
post_install() {
    local distro="$1"

    echo "${E_INFO}Performing post install checks for '$distro'..."

    case "$distro" in
        almalinux|rocky)
            local el_ver; el_ver=$(rpm -E %rhel)

            if [[ ! -L $E_LOCAL_BIN/python3 && $el_ver == "8" ]]; then
                echo "${E_INFO}Creating symlink for 'python3' to 'python3.11' in" \
                    "'$E_LOCAL_BIN'..."
                ln -s /usr/bin/python3.11 "$E_LOCAL_BIN/python3"
            fi
            ;;
        opensuse-leap)
            if [[ ! -L $E_LOCAL_BIN/python3 ]]; then
                echo "${E_INFO}Creating symlink for 'python3' to 'python3.11' in" \
                    "'$E_LOCAL_BIN'..."
                ln -s /usr/bin/python3.11 "$E_LOCAL_BIN/python3"
            fi
            ;;
    esac
}


####[ Trapping Logic ]######################################################################


trap 'clean_exit "129"' SIGHUP
trap 'clean_exit "130"' SIGINT
trap 'clean_exit "143"' SIGTERM
trap 'clean_exit "$?"'  EXIT


####[ Main ]################################################################################


printf "%sWe will now install NadekoBot's prerequisites. " "$E_NOTE"
read -rp "Press [Enter] to continue."

detect_sys_info

for version in ${C_SUPPORTED_DISTROS[$C_DISTRO]}; do
    if [[ $version == "$C_VER" || $version == "$C_SVER" || $version == "any" ]]; then
        pre_install "$C_DISTRO"
        install_prereqs "${C_INSTALL_CMD_MAPPING[$C_DISTRO]}" \
            "${C_UPDATE_CMD_MAPPING[$C_DISTRO]}" \
            "${C_MUSIC_PKG_MAPPING[$C_DISTRO]}" \
            "${C_MANAGER_PKG_MAPPING[$C_DISTRO]}"
        post_install "$C_DISTRO"
        echo -en "\n${E_SUCCESS}Finished installing prerequisites"
        clean_exit 0 "true"
    fi
done

unsupported
