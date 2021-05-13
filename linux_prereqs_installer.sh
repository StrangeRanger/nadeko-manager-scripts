#!/bin/bash
#
# Installs all of the packages and dependencies required for NadekoBot to run on Linux
# Distributions.
#
########################################################################################
#### [ Functions ]


dot_net_install() {
    ####
    # FUNCTION INFO:
    #
    # Installs required packages and dependencies needed by NadekoBot, on all compatable
    # Linux Distributions, besides Debian 9.
    #
    # @param $1 Distribution name.
    # @param $2 Distribution version.
    ####

    echo "Installing .NET Core..."
    ## Microsoft package signing key.
    curl https://packages.microsoft.com/config/"$1"/"$2"/packages-microsoft-prod.deb \
        -o packages-microsoft-prod.deb
    sudo dpkg -i packages-microsoft-prod.deb && sudo rm -f packages-microsoft-prod.deb

    ## Install the SDK.
    sudo apt-get update
    sudo apt-get install -y apt-transport-https &&
        sudo apt-get update &&
        sudo apt-get install -y dotnet-sdk-3.1
        # Will be used to install dotnet-sdk-5.0 in the future. For now it will continue
        # to install dotnet-sdk-3.1
        #sudo apt-get install -y dotnet-sdk-5.0

    echo "Installing other prerequisites..."
    sudo apt-get install libopus0 opus-tools libopus-dev libsodium-dev ffmpeg \
        redis-server git python python3 jq wget -y
    sudo curl -s -L https://yt-dl.org/downloads/latest/youtube-dl -o \
        /usr/local/bin/youtube-dl
    # Will always fail to update using 'youtube-dl -U', if command run as non-root user.
    # I'll find a way that hopefully doesn't require me to change permissions of the
    # program to 777.
    sudo chmod a+rx /usr/local/bin/youtube-dl
}


#### End of [ Functions ]
########################################################################################
#### [ Main ]


read -rp "We will now install NadekoBot's prerequisites. Press [Enter] to continue."

if [[ $_DISTRO = "ubuntu" ]]; then
    case "$_VER" in
        16.04) dot_net_install "ubuntu" "16.04" ;;
        18.04) dot_net_install "ubuntu" "18.04" ;;
        20.04) dot_net_install "ubuntu" "20.04" ;;
        *)
            echo "${_RED}The installer does not support the automatic installation" \
                "and setup of NadekoBot's prerequisites for your OS: $_DISTRO $_VER" \
                "$_ARCH$_NC"
            read -rp "Press [Enter] to return to the installer menu"
            ;;
    esac
elif [[ $_DISTRO = "debian" ]]; then
    case "$_SVER" in    
        9) 
            echo "Installing .NET Core..."
            ## Microsoft package signing key
            wget -O - https://packages.microsoft.com/keys/microsoft.asc | gpg \
                --dearmor > microsoft.asc.gpg
            sudo mv microsoft.asc.gpg /etc/apt/trusted.gpg.d/
            curl -s https://packages.microsoft.com/config/debian/9/prod.list -o prod.list
            sudo mv prod.list /etc/apt/sources.list.d/microsoft-prod.list
            sudo chown root:root /etc/apt/trusted.gpg.d/microsoft.asc.gpg
            sudo chown root:root /etc/apt/sources.list.d/microsoft-prod.list
            
            ## Install the SDK
            sudo apt-get update
            sudo apt-get install -y apt-transport-https &&
                sudo apt-get update &&
                sudo apt-get install -y dotnet-sdk-3.1
                # Will be used to install dotnet-sdk-5.0 in the future. For now, it will
                # continue to install dotnet-sdk-3.1.
                #sudo apt-get install -y dotnet-sdk-5.0

            echo "Installing other prerequisites..."
            sudo apt-get install libopus0 opus-tools libopus-dev libsodium-dev ffmpeg \
                redis-server git jq python python3 -y
            sudo curl -s -L https://yt-dl.org/downloads/latest/youtube-dl -o \
                /usr/local/bin/youtube-dl
            sudo chmod a+rx /usr/local/bin/youtube-dl
            ;;
        10)
            dot_net_install "debian" "10"
            ;;
        *)
            echo "${_RED}The installer does not support the automatic installation" \
                "and setup of NadekoBot's prerequisites for your OS: $_DISTRO $_VER" \
                "$_ARCH$_NC"
            read -rp "Press [Enter] to return to the installer menu"
            ;;
    esac
elif [[ $_DISTRO = "linuxmint" ]]; then
    case "$_SVER" in
        18) dot_net_install "ubuntu" "16.04" ;;
        19) dot_net_install "ubuntu" "18.04" ;;
        20) dot_net_install "ubuntu" "20.04" ;;
        *)
            echo "${_RED}The installer does not support the automatic installation" \
                "and setup of NadekoBot's prerequisites for your OS: $_DISTRO $_VER" \
                "$_ARCH$_NC"
            read -rp "Press [Enter] to return to the installer menu"
            ;;
    esac
fi

echo -e "\n${_GREEN}Finished installing prerequisites$_NC"
read -rp "Press [Enter] to return to the installer menu"


#### End of [ Main ]
########################################################################################
