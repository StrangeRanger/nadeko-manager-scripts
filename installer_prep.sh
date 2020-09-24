#!/bin/bash

################################################################################
#
# TODO: Add a file description
#
# Note: All variables not defined in this script, are exported from
# 'linuxAIO.sh'.
#
################################################################################
#
# Exported and/or globally used [ variables ]
#
################################################################################
#
    yellow=$'\033[1;33m'
    green=$'\033[0;32m'
    cyan=$'\033[0;36m'
    red=$'\033[1;31m'
    nc=$'\033[0m'
    clrln=$'\r\033[K'

#
################################################################################
#
# Exported only [ variables ]
#
################################################################################
#
    clean_exit() {
        local installer_files=("credentials_setup.sh" "installer_prep.sh"
            "nadeko_installer_latest.sh" "nadeko_master_installer.sh" "NadekoARB.sh"
            "NadekoARBU.sh" "NadekoB.sh" "prereqs_installer.sh")

        if [[ $3 = "true" ]]; then echo "Cleaning up..."; else echo -e "\nCleaning up..."; fi
        for file in "${installer_files[@]}"; do
            if [[ -f $file ]]; then rm "$file"; fi
        done

        echo "${2}..."
        exit "$1"
    }

    trap "echo -e \"\n\nScript forcefully stopped\"
        clean_exit \"1\" \"Exiting\" \"true\"" \
        SIGINT SIGTSTP SIGTERM

#
################################################################################
#
# Checks for root privilege and working directory
#
################################################################################
#
    # Changes the working directory to that of where the executed script is
    # located
    cd "$(dirname "$0")" || {
        echo "${red}Failed to change working directories" >&2
        echo "${cyan}Change your working directory to the same directory of" \
            "the executed script${nc}"
        clean_exit "1" "Exiting" "true"
    }

    export root_dir="$PWD"

#
################################################################################
#
# [ Functions ]
#
################################################################################
#
    # Identify the operating system, version number, architecture, bit type (32
    # or 64), etc.
    detect_sys_info() {
        arch=$(uname -m | sed 's/x86_//;s/i[3-6]86/32/')
        
        if [[ -f /etc/os-release ]]; then
            . /etc/os-release
            distro="$ID"
            # Version: x.x.x...
            ver="$VERSION_ID"
            # Version: x (short handed version)
            sver=${ver//.*/}
            pname="$PRETTY_NAME"
            codename="$VERSION_CODENAME"
        else
            distro=$(uname -s)
                if [[ $distro = "Darwin" ]]; then
                    ver=$(sw_vers -productVersion)
                else
                    ver=$(uname -r)
                fi
        fi

        # Identifying bit type
        case $(uname -m) in
            x86_64) bits="64" ;;
            i*86) bits="32" ;;
            armv*) bits="32" ;;
            *) bits="?" ;;
        esac

        # Identifying architecture type
        case $(uname -m) in
            x86_64) arch="x64" ;;
            i*86) arch="x86" ;;
            *) arch="?" ;;
        esac
    }

    execute_master_installer(){
        supported="true"
        while true; do
            wget -qN https://raw.githubusercontent.com/"$installer_repo"/"$installer_branch"/nadeko_master_installer.sh || {
                failed_download "nadeko_master_installer.sh"
            }
            break
        done

        sudo chmod +x nadeko_master_installer.sh && ./nadeko_master_installer.sh || {
            echo "${red}Failed to execute 'nadeko_master_installer.sh'${nc}" >&2
            clean_exit "1" "Exiting" "true"
        }
    }

#
################################################################################
#
# [ Main ]
#
################################################################################
#
    clear -x

    detect_sys_info
    export distro sver ver arch bits codename
    export yellow green cyan red nc clrln
    export -f clean_exit

    echo "SYSTEM INFO"
    echo "Bit Type: $bits"
    echo "Architecture: $arch"
    echo -n "OS/Distro: "
    if [[ -n $pname ]]; then echo "$pname"; else echo "$distro"; fi
    echo "OS/Distro Version: $ver"
    echo ""

    if [[ $distro = "ubuntu" ]]; then
        # B.1. Forcing 64 bit architecture
        if [[ $bits = 64 ]]; then 
            case "$ver" in
                16.04) execute_master_installer ;;
                18.04) execute_master_installer ;;
                20.04) execute_master_installer ;;
                *) supported="false" ;;
            esac
        else
            supported="false"
        fi
    elif [[ $distro = "debian" ]]; then
        if [[ $bits = 64 ]]; then # B.1.
            case "$sver" in
                8) execute_master_installer ;;
                9) execute_master_installer ;;
                10) execute_master_installer ;;
                *) supported="false" ;;
            esac
        else
            supported="false"
        fi

    elif [[ $distro = "linuxmint" ]]; then
        if [[ $bits = 64 ]]; then # B.1.
            case "$sver" in
                18) execute_master_installer ;;
                19) execute_master_installer ;;
                20) execute_master_installer ;;
                *) supported="false" ;;
            esac
        fi
    else
        supported="false"
    fi
        
    if [[ $supported = "false" ]]; then
        echo "${red}Your OS is not an officially supported macOS/Linux Distribtuion${nc}" >&2
        read -p "Would you like to continue with the installation? [y|N]" choice
        choice=$(echo "$choice" | tr '[A-Z]' '[a-z]')
        case "$choice" in
            y|yes) execute_master_installer ;;
            n|no) clean_exit "0" "Exiting" ;;
            *) clean_exit "0" "Exiting" ;;
        esac
    fi
