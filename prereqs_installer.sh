#!/bin/bash
#
# Install all of the packages and dependencies required for NadekoBot to run on Linux
# distributions.
#
# Comment key:
#   A.1. - NOTE: If the write perms are not applied to all users for this tool, attempts
#                to update 'youtube-dl' by a non-root user will always fail.
#   B.1. - FIXME: Find a better solution than modifying the perms in such a way that I
#                 have.
#
########################################################################################
#### [ Functions ]


install_prereqs() {
    ####
    # Function Info: Install required packages and dependencies needed by NadekoBot, on
	#                all compatible Linux distributions, besides Debian 9.
	#
    # Parameters:
    # 	$1 - required
    #       Distribution name.
    # 	$2 - required
    #       Distribution version.
    #   $3 - required
    #       'python' or 'python-is-python3' (dependent on the distro version).
    ####

    echo "Installing .NET Core..."
    ## Microsoft package signing key.
    curl -O https://packages.microsoft.com/config/"$1"/"$2"/packages-microsoft-prod.deb
    sudo dpkg -i packages-microsoft-prod.deb
    sudo rm -f packages-microsoft-prod.deb

    ## Install the SDK.
    sudo apt-get update
    sudo apt-get install -y apt-transport-https \
        && sudo apt-get update \
        && sudo apt-get install -y dotnet-sdk-6.0

    ## Install music prerequisites.
    echo "Installing music prerequisites..."
    sudo apt-get install libopus0 opus-tools libopus-dev libsodium-dev -y

    ## Other prerequisites.
    echo "Installing other prerequisites..."
    sudo apt-get install ffmpeg redis-server git python3 "$3" ccze -y
    sudo curl -s -L https://yt-dl.org/downloads/latest/youtube-dl -o \
        /usr/local/bin/youtube-dl
    # A.1. & B.1.
    sudo chmod a+rwx /usr/local/bin/youtube-dl
}

unsupported() {
    ####
    # Function Info: Informs the end-user that their system is not supported by the
	#				 automatic installation of the prerequisites.
    ####

    echo "${_RED}The installer does not support the automatic installation and setup" \
        "of NadekoBot's prerequisites for your OS: $_DISTRO $_VER ${_ARCH}${_NC}"
    read -rp "Press [Enter] to return to the installer menu"
    exit 3
}


#### End of [ Functions ]
########################################################################################
#### [ Main ]


read -rp "We will now install NadekoBot's prerequisites. Press [Enter] to continue."

# Ubuntu:
#   22.04
#   20.04
#   18.04
#   16.04
if [[ $_DISTRO = "ubuntu" ]]; then
    case "$_VER" in
        20.04|22.04) install_prereqs "ubuntu" "$_VER" "python-is-python3" ;;
        18.04|16.04) install_prereqs "ubuntu" "$_VER" "python" ;;
        *)           unsupported ;;
    esac
# Debian:
#   11
#   10
#   9
elif [[ $_DISTRO = "debian" ]]; then
    case "$_SVER" in
        11) install_prereqs "debian" "11" "python-is-python3" ;;
        10) install_prereqs "debian" "10" "python" ;;
        9)
            echo "Installing .NET Core..."
            ## Microsoft package signing key.
            curl https://packages.microsoft.com/keys/microsoft.asc | gpg \
                --dearmor > microsoft.asc.gpg
            sudo mv microsoft.asc.gpg /etc/apt/trusted.gpg.d/
            curl -sO https://packages.microsoft.com/config/debian/9/prod.list
            sudo mv prod.list /etc/apt/sources.list.d/microsoft-prod.list
            sudo chown root:root /etc/apt/trusted.gpg.d/microsoft.asc.gpg
            sudo chown root:root /etc/apt/sources.list.d/microsoft-prod.list

            ## Install the SDK.
            sudo apt-get update
            sudo apt-get install -y apt-transport-https \
                && sudo apt-get update \
                && sudo apt-get install -y dotnet-sdk-6.0

            ## Install music prerequisites.
            echo "Installing music prerequisites..."
            sudo apt-get install libopus0 opus-tools libopus-dev libsodium-dev -y

            ## Other prerequisites.
            echo "Installing other prerequisites..."
            sudo apt-get install ffmpeg redis-server git python3 python ccze -y

            sudo curl -s -L https://yt-dl.org/downloads/latest/youtube-dl -o \
                /usr/local/bin/youtube-dl
            # A.1. & B.1.
            sudo chmod a+rwx /usr/local/bin/youtube-dl
            ;;
        *)  unsupported ;;
    esac
# Linux Mint:
#   20
#   19
elif [[ $_DISTRO = "linuxmint" ]]; then
    case "$_SVER" in
        20) install_prereqs "ubuntu" "20.04" "python-is-python3" ;;
        19) install_prereqs "ubuntu" "18.04" "python" ;;
        *)  unsupported ;;
    esac
fi

echo -e "\n${_GREEN}Finished installing prerequisites${_NC}"
read -rp "Press [Enter] to return to the installer menu"


#### End of [ Main ]
########################################################################################
