#!/usr/bin/env bash
#
# This script installs necessary dependencies that would otherwise be installed by
# default on a fresh installation of the supported distributions. The dependencies
# only include the bare minimum required to run both the bot and the Manager, but aren't
# installed by the Manager itself.
#
########################################################################################

# Enable strict error handling.
set -euxo pipefail


# Retrieve the package manager from arguments.
C_PKG_MANAGER="$1"
C_ROOT_PASSWORD="password"


if [[ "$C_PKG_MANAGER" = "apt" ]]; then
    apt-get update
    apt-get upgrade -y
    apt-get install -y --no-install-recommends ca-certificates curl sudo systemd \
        systemd-sysv vim
    apt-get autoremove -y
    apt-get clean -y
    rm -rf /var/lib/apt/lists/*
elif [[ "$C_PKG_MANAGER" = "dnf" ]]; then
    dnf update -y
    dnf install -y --allowerasing --setopt=install_weak_deps=False \
        curl libicu findutils ncurses procps-ng python3 sudo systemd vim
    dnf clean all
elif [[ "$C_PKG_MANAGER" = "zypper" ]]; then
    zypper refresh
    zypper --non-interactive update
    zypper --non-interactive install curl libicu python3-base sudo systemd vim
    zypper clean --all
elif [[ "$C_PKG_MANAGER" = "pacman" ]]; then
    pacman -Syu --noconfirm base-devel curl git go sudo systemd vim
    # If 'yay' (an AUR helper) is not installed, build it.
    if ! command -v yay &>/dev/null; then
        useradd -m builder
        echo "builder ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/builder
        git clone https://aur.archlinux.org/yay.git /home/builder/yay
        chown -R builder:builder /home/builder/yay
        su builder -c "cd /home/builder/yay && makepkg -si --noconfirm"
        rm -rf /home/builder/yay
        userdel -r builder
        rm -f /etc/sudoers.d/builder
    fi
    pacman -Scc --noconfirm
else
    echo "Unsupported package manager: $C_PKG_MANAGER"
    exit 1
fi

# Set the root password.
echo "root:$C_ROOT_PASSWORD" | chpasswd

# Create the working directory.
mkdir -p /root/NadekoBot

# Remove temporary files that are no longer needed.
rm -rf /tmp/* /var/tmp/*

# Optionally, clear log files to reduce image size.
if [ -d /var/log ]; then
    find /var/log -type f -exec truncate -s 0 {} \;
fi

echo "Done"
