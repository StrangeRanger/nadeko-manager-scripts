#!/bin/bash
#
# Install all of the packages and dependencies required for NadekoBot to run on macOS.
#
########################################################################################
#### [ Functions ]


install_prereqs() {
    ####
    # Function Info: Install required package and dependencies needed by NadekoBot.
    ####

    echo "Updating and upgrading Homebrew formulas and casks..."
    brew update && brew upgrade
    echo "Installing prerequisites..."
    brew install opus opus-tools opusfile libsodium libffi ffmpeg openssl redis git jq \
        mono-libgdiplus python3 youtube-dl
    echo "Starting redis..."
    brew services start redis
    echo "Casking Dotnet..."
    brew install --cask dotnet-sdk
    echo "Brew doctor..."
    brew doctor
}


#### End of [ Functions ]
########################################################################################
#### [ Main ]


echo "${_CYAN}NOTE: It may take up to 10 minutes for all the prerequisites to be" \
    "installed$_NC"
echo "${_CYAN}NOTE 2: If Homebrew is not currently installed on your system, it will" \
    "be installed now$_NC"
read -rp "We will now install NadekoBot's prerequisites. Press [Enter] to continue."

if ! hash brew &>/dev/null; then
    echo "${_YELLOW}Homebrew is not installed$_CYAN"
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || {
        echo "${_RED}Failed to install Homebrew" >&2
        echo "${_CYAN}Homebrew must be installed to install the prerequisites$_NC"
        read -rp "Press [Enter] to return to the installer menu"
        exit 4
    }
fi

case "$_SVER" in
	# macOS:
    #   10.14
    #   10.15
    #   11.*
    10.14|10.15) install_prereqs ;;
    11|11.*)     install_prereqs ;;
    *)
        echo "${_RED}The installer does not support the automatic installation and" \
            "setup of NadekoBot's prerequisites for your version of macOS$_NC"
        read -rp "Press [Enter] to return to the installer menu"
        exit 4
        ;;
esac

echo -e "\n${_GREEN}Finished installing prerequisites$_NC"
read -rp "Press [Enter] to return to the installer menu"


#### End of [ Main ]
########################################################################################
