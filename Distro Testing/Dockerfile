# syntax=docker/dockerfile:1
##############################
# This Dockerfile is parameterized via build-args.
# It expects:
#   - BASE_IMAGE: the base Docker image (e.g. ubuntu:24.04)
#   - PKG_MANAGER: one of "apt", "dnf", "zypper", or "pacman"
##############################

## There is no default image on purpose. The user MUST specify one.
ARG BASE_IMAGE
FROM ${BASE_IMAGE}

# Allow build-time selection of package manager commands.
ARG PKG_MANAGER

# Tell systemd (and various packages) that we are in a container.
ENV container=docker

ENV DEBIAN_FRONTEND=noninteractive

## Install systemd, curl, sudo, vim, and other dependencies.
RUN if [ "$PKG_MANAGER" = "apt" ]; then \
        apt-get update && \
        apt-get upgrade -y && \
        apt-get install -y systemd systemd-sysv curl sudo vim && \
        rm -rf /var/lib/apt/lists/*; \
    elif [ "$PKG_MANAGER" = "dnf" ]; then \
        dnf update -y && \
        dnf install  -y --allowerasing systemd curl sudo vim python3 ncurses libicu; \
    elif [ "$PKG_MANAGER" = "zypper" ]; then \
        zypper refresh && \
        zypper --non-interactive update && \
        zypper --non-interactive install systemd curl sudo vim python3-base libicu && \
        zypper clean --all; \
    elif [ "$PKG_MANAGER" = "pacman" ]; then \
        pacman -Syu --noconfirm systemd curl sudo vim base-devel git go && \
        if ! command -v yay >/dev/null 2>&1; then \
            useradd -m builder && \
            echo "builder ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/builder && \
            git clone https://aur.archlinux.org/yay.git /home/builder/yay && \
            chown -R builder:builder /home/builder/yay && \
            su builder -c "cd /home/builder/yay && makepkg -si --noconfirm" && \
            rm -rf /home/builder/yay && \
            userdel -r builder && \
            rm -f /etc/sudoers.d/builder; \
        fi \
    else \
        echo "Unsupported package manager: $PKG_MANAGER" && exit 1; \
    fi

RUN echo 'root:password' | chpasswd

RUN mkdir -p /root/NadekoBot

# Run systemd as the init process.
CMD ["/sbin/init"]
