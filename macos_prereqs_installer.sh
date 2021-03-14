#!/bin/bash
#
# Installs all of the packages and dependencies required for NadekoBot to run
# on macOS.
#
# Note: All variables not defined in this script, are exported from
# 'linuxAIO.sh', 'installer_prep.sh', and 'nadeko_master_installer.sh'.
#
################################################################################
#### [ Functions ]


dot_net_install() {
    echo "Updating and upgrading Homebrew formulas and casks..."
    brew update && brew upgrade
    echo "Installing prerequisites..."
    brew install opus opus-tools opusfile libsodium libffi ffmpeg openssl \
        redis git jq python python3 wget youtube-dl
    echo "Starting redis..."
    brew services start redis
    echo "Casking Dotnet..."
    brew install dotnet
    echo "Brew doctor..."
    brew doctor
}


#### End of [ Functions ]
################################################################################
#### [ Main ]


echo -e "${cyan}Note: It may take up to 10 minutes for all the" \
    "prerequisites to be installed.${nc}"
read -p "We will now install NadekoBot's prerequisites. Press [Enter] to continue."

if ! hash brew &>/dev/null; then
    echo "${yellow}Homebrew is not installed${cyan}"
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || {
        echo "${red}Failed to install Homebrew" >&2
        echo "${cyan}Homebrew must be installed to install prerequisites${nc}"
        read -p "Press [Enter] to return to the installer menu"
        exit 1
    }
fi

case "$sver" in
    10.14) dot_net_install ;;
    10.15) dot_net_install ;;
    11.0)  dot_net_install ;;
    *)
        echo "${red}The installer does not support the automatic" \
            "installation and setup of NadekoBot's prerequisites for your" \
            "version of macOS${nc}"
        read -p "Press [Enter] to return to the installer menu"
        exit 1
        ;;
esac

echo -e "\n${green}Finished installing prerequisites${nc}"
read -p "Press [Enter] to return to the installer menu"


#### End of [ Main ]
################################################################################
