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
        echo ""
    }

#
################################################################################
#
# [ Main ]
#
################################################################################
#
    read -p "We will now install Nadeko's prerequisites. Press [Enter] to continue."

    
    case "$sver" in
        10.15) dot_net_install ;;
        *) ;;
    esac

    echo "${green}Finished installing prerequisites${nc}"
    read -p "Press [Enter] to return to the installer menu"
