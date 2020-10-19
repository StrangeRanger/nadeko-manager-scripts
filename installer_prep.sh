#!/bin/bash

################################################################################
#
# This installer looks at the operating system, architecture, bit type,
# etc., to determine whether or not the system is supported by Nadeko. Once the
# system is deemed as supported, the master installer will be downloaded and
# executed.
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
    current_linuxAIO_revision="3"

#
################################################################################
#
# [ Error traps ]
#
################################################################################
#
    # Makes it possible to cleanly exit the installer by cleaning up files that
    # don't need to stay on the system unless currently being run
    clean_exit() {
        local installer_files=("credentials_setup.sh" "installer_prep.sh"
            "nadeko_latest_installer.sh" "nadeko_master_installer.sh" "NadekoARB.sh"
            "NadekoARBU.sh" "NadekoB.sh" "prereqs_installer.sh")

        if [[ $3 = true ]]; then echo "Cleaning up..."; else echo -e "\nCleaning up..."; fi
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
# Makes sure that linuxAIO.sh is up to date
#
################################################################################
#
    if [[ $linuxAIO_revision != $current_linuxAIO_revision ]]; then
        echo "${yellow}'linuxAIO.sh' is not up to date${nc}"
        echo "Downloading latest 'linuxAIO.sh'..."
        curl https://raw.githubusercontent.com/"$installer_repo"/"$installer_branch"/linuxAIO.sh \
                -o linuxAIO.sh || {
            echo "${red}Failed to download latest 'linuxAIO.sh'...${nc}" >&2
            clean_exit "1" "Exiting" "true"
        }
        chmod +x linuxAIO.sh
        echo "${cyan}Re-execute 'linuxAIO.sh' to continue${nc}"
        clean_exit "0" "Exiting" "true"
        # TODO: Figure out a way to get exec to work
fi

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
    export installer_prep="$root_dir/installer_prep.sh"
    export installer_prep_pid=$$
    
    # The '--no-hostname' flag for journalctl only works with systemd 230 and
    # later
    if (($(journalctl --version | grep -oP "[0-9]+" | head -1) >= 230)); then
        export no_hostname="--no-hostname"
    fi

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
            # Version: x
            sver=${ver//.*/}
            pname="$PRETTY_NAME"
            codename="$VERSION_CODENAME"
        else
            distro=$(uname -s)
            if [[ $distro = "Darwin" ]]; then
                # Version: x.x.x
                ver=$(sw_vers -productVersion)
                # Version: x.x
                sver=${ver%.*}
                pname="Mac OS X"
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

    execute_master_installer() {
        supported=true
        curl -s https://raw.githubusercontent.com/"$installer_repo"/"$installer_branch"/nadeko_master_installer.sh \
                -o nadeko_master_installer.sh || {
            echo "${red}Failed to download 'nadeko_master_installer.sh'" >&2
            clean_exit "1" "Exiting" "true"
        }
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
    echo -n "Distro: "
    if [[ -n $pname ]]; then echo "$pname"; else echo "$distro"; fi
    echo "Distro Version: $ver"
    echo ""

    if [[ $distro = "ubuntu" ]]; then
        # B.1. Forcing 64 bit architecture
        if [[ $bits = 64 ]]; then
            case "$ver" in
                16.04) export nadeko_service_content="nadeko.service"; execute_master_installer ;;
                18.04) export nadeko_service_content="nadeko.service"; execute_master_installer ;;
                20.04) export nadeko_service_content="nadeko.service"; execute_master_installer ;;
                *) supported=false ;;
            esac
        else
            supported=false
        fi
    elif [[ $distro = "debian" ]]; then
        if [[ $bits = 64 ]]; then # B.1.
            case "$sver" in
                9) export nadeko_service_content="nadeko.service"; execute_master_installer ;;
                10) export nadeko_service_content="nadeko.service"; execute_master_installer ;;
                *) supported=false ;;
            esac
        else
            supported=false
        fi

    elif [[ $distro = "linuxmint" ]]; then
        if [[ $bits = 64 ]]; then # B.1.
            case "$sver" in
                18) export nadeko_service_content="nadeko.service"; execute_master_installer ;;
                19) export nadeko_service_content="nadeko.service"; execute_master_installer ;;
                20) export nadeko_service_content="nadeko.service"; execute_master_installer ;;
                *) supported=false ;;
            esac
        fi
    elif [[ $distro = "Darwin" ]]; then
        case "$sver" in
            10.15) export nadeko_service_content="bot.nadeko.Nadeko"; execute_master_installer ;;
            *) supported=false ;;
        esac
    else
        supported=false
    fi

    if [[ $supported = false ]]; then
        echo "${red}Your operating system/Linux Distribution is not OFFICIALLY" \
            "supported by the installation, setup, and/or use of Nadeko${nc}" >&2
        read -p "Would you like to continue with the installation? [y|N]" choice
        choice=$(echo "$choice" | tr '[A-Z]' '[a-z]')
        case "$choice" in
            y|yes) execute_master_installer ;;
            n|no) clean_exit "0" "Exiting" ;;
            *) clean_exit "0" "Exiting" ;;
        esac
    fi
