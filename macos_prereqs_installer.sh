#!/bin/bash

################################################################################
#
# Installs all of the packages and dependencies required for NadekoBot to run,
# on macOS.
#
# Note: All variables not defined in this script, are exported from
# 'linuxPMI.sh', 'installer_prep.sh', and 'nadeko_master_installer.sh'.
#
################################################################################
#
# [ Functions ]
#
################################################################################
#
    dot_net_install() {
        echo "Installing prerequisites..."
        brew install opus opus-tools opusfile libsodium libffi ffmpeg openssl \
            redis git jq python python3 wget youtube-dl
        echo "Starting redis..."
        brew services start redis
        echo "Casking Dotnet..."
        brew cask install dotnet-sdk
        echo "Brew doctor..."
        brew doctor
    }

#
################################################################################
#
# [ Main ]
#
################################################################################
#   
    echo "${cyan}IMPORTANT: If Homebrew is currently not installed, it will" \
        "automatically installed. If you do not want this, the exit the program" \
        "immediatly.${nc}"
    read -p "We will now install Nadeko's prerequisites. Press [Enter] to continue."

    if ! hash brew &>/dev/null; then
        echo "${yellow}Homebrew is not installed${cyan}"
        echo "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)" || {
            echo "${red}Failed to to install Homebrew" >&2
            echo "${cyan}Homebrew must be installed to install prerequisites${nc}"
            read -p "Press [Enter] to return to the installer menu"
            exit 1
        }
    fi

    case "$sver" in
        10.15) dot_net_install ;;
        *) 
            # TODO: Maybe modify message
            echo "${red}The installer does not support the automatic" \
                "installation and setup of NadekoBot's prerequisites, for your" \
                "version of macOS${nc}"
            read -p "Press [Enter] to return to the installer menu"
            ;;
    esac

    echo "${green}Finished installing prerequisites${nc}"
    read -p "Press [Enter] to return to the installer menu"
