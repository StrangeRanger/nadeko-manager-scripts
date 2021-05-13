#!/bin/bash
#
# Installs all of the packages and dependencies required for NadekoBot to run on macOS.
#
########################################################################################
#### [ Functions ]


dot_net_install() {
    ####
    # FUNCTION INFO:
    #
    # Install required package and dependencies needed by NadekoBot.
    ####

    echo "Updating and upgrading Homebrew formulas and casks..."
    brew update && brew upgrade
    echo "Installing prerequisites..."
    brew install opus opus-tools opusfile libsodium libffi ffmpeg openssl redis git jq \
        python python3 wget youtube-dl
    echo "Starting redis..."
    brew services start redis
    echo "Casking Dotnet..."
    brew install --cask dotnet
    echo "Brew doctor..."
    brew doctor
}


#### End of [ Functions ]
########################################################################################
#### [ Main ]


echo -e "${_CYAN}Note: It may take up to 10 minutes for all the prerequisites to be" \
    "installed.$_NC"
read -rp "We will now install NadekoBot's prerequisites. Press [Enter] to continue."

if ! hash brew &>/dev/null; then
    echo "${_YELLOW}Homebrew is not installed${_CYAN}"
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || {
        echo "${_RED}Failed to install Homebrew" >&2
        echo "${_CYAN}Homebrew must be installed to install prerequisites$_NC"
        read -rp "Press [Enter] to return to the installer menu"
        exit 1
    }
fi

case "$_SVER" in
    10.14) dot_net_install ;;
    10.15) dot_net_install ;;
    11.*)  dot_net_install ;;
    *)
        echo "${_RED}The installer does not support the automatic installation and" \
            "setup of NadekoBot's prerequisites for your version of macOS$_NC"
        read -rp "Press [Enter] to return to the installer menu"
        exit 1
        ;;
esac

echo -e "\n${_GREEN}Finished installing prerequisites$_NC"
read -rp "Press [Enter] to return to the installer menu"


#### End of [ Main ]
########################################################################################
