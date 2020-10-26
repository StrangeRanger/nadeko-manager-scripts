#!/bin/bash

################################################################################
#
# TODO: Add a file description
#
################################################################################
#
# [ Functions ]
#
################################################################################
#
    dot_net_install() {
        echo "Installing .NET Core..."
        # Microsoft package signing key
        wget https://packages.microsoft.com/config/"$1"/"$2"/packages-microsoft-prod.deb \
            -O packages-microsoft-prod.deb
        sudo dpkg -i packages-microsoft-prod.deb && sudo rm -f packages-microsoft-prod.deb
        # Install the SDK
        sudo apt-get update
        sudo apt-get install -y apt-transport-https &&
            sudo apt-get update &&
            sudo apt-get install -y dotnet-sdk-3.1

        echo "Installing prerequisites..."
        sudo apt-get install libopus0 opus-tools libopus-dev libsodium-dev ffmpeg \
            redis-server git jq -y
        sudo curl -s https://yt-dl.org/downloads/latest/youtube-dl -o /usr/local/bin/youtube-dl
        sudo chmod a+rx /usr/local/bin/youtube-dl
    }

#
################################################################################
#
# [ Main ]
#
################################################################################
#
    echo "${cyan}Note: This installer will download all of the required packages" \
        "for NadekoBot. It will use about 350MB of space. This might take awhile" \
        "to download if you do not have a good internet connection.${nc}"
    read -p "We will now install Nadeko's prerequisites. Press [Enter] to continue."

    if [[ $distro = "ubuntu" ]]; then
        if [[ $ver = "16.04" ]]; then
            dot_net_install "ubuntu" "16.04"
        elif [[ $ver = "18.04" ]]; then
            dot_net_install "ubuntu" "18.04"
        elif [[ $ver = "20.04" ]]; then
            dot_net_install "ubuntu" "20.04"
        else
            echo "Your OS $OS $VER $ARCH probably can run Microsoft .NET Core."
            read -p "Contact NadekoBot's support on Discord with screenshot."
        fi
    elif [[ $distro = "debian" ]]; then
        if [[ $sver = "9" ]]; then
            echo "Installing .NET Core..."
            # Microsoft package signing key
            wget -O - https://packages.microsoft.com/keys/microsoft.asc | gpg \
                --dearmor >microsoft.asc.gpg
            sudo mv microsoft.asc.gpg /etc/apt/trusted.gpg.d/
            curl -s https://packages.microsoft.com/config/debian/9/prod.list
            sudo mv prod.list /etc/apt/sources.list.d/microsoft-prod.list
            sudo chown root:root /etc/apt/trusted.gpg.d/microsoft.asc.gpg
            sudo chown root:root /etc/apt/sources.list.d/microsoft-prod.list
            # Install the SDK
            sudo apt-get update
            sudo apt-get install -y apt-transport-https &&
                sudo apt-get update &&
                sudo apt-get install -y dotnet-sdk-3.1

            echo "Installing prerequisites..."
            sudo apt-get install libopus0 opus-tools libopus-dev libsodium-dev \
                ffmpeg redis-server git jq -y
            sudo curl -s https://yt-dl.org/downloads/latest/youtube-dl -o \
                /usr/local/bin/youtube-dl
            sudo chmod a+rx /usr/local/bin/youtube-dl
        elif [[ $sver = "10" ]]; then
            dot_net_install "debian" "10"
        else
            echo "Your OS $OS $VER $ARCH probably can run Microsoft .NET Core."
            read -p "Contact NadekoBot's support on Discord with screenshot."
        fi
    elif [ $distro = "LinuxMint" ]; then
        if [[ $sver = "18" ]]; then
            dot_net_install "ubuntu" "16.04"
        elif [[ $sver = "19" ]]; then
            dot_net_install "ubuntu" "18.04"
        elif [[ $sver = "20" ]]; then
            dot_net_install "ubuntu" "20.04"
        else
            echo "Your OS $OS $VER $ARCH probably can run Microsoft .NET Core."
            read -p "Contact NadekoBot's support on Discord with screenshot."
        fi
    fi

    echo -e "\n${green}Finished installing prerequisites${nc}"
    read -p "Press [Enter] to return to the installer menu"
