# syntax=docker/dockerfile:1
##############################
# This Dockerfile is parameterized via build-args.
# It expects:
#   - BASE_IMAGE: the base Docker image (e.g. ubuntu:22.04)
#   - PKG_MANAGER: one of "apt", "dnf", "zypper", "pacman"
##############################

# Default to Ubuntu 22.04 if no base image is specified.
ARG BASE_IMAGE=ubuntu:22.04
FROM ${BASE_IMAGE}

# Allow build-time selection of package manager commands.
ARG PKG_MANAGER

# Tell systemd (and various packages) that we are in a container.
ENV container=docker

# For apt-based images, disable interactive prompts.
ENV DEBIAN_FRONTEND=noninteractive

# Install required packages, including systemd.
RUN if [ "$PKG_MANAGER" = "apt" ]; then \
        apt-get update && \
        apt-get upgrade -y && \
        apt-get install -y systemd systemd-sysv curl sudo vim && \
        rm -rf /var/lib/apt/lists/*; \
    elif [ "$PKG_MANAGER" = "dnf" ]; then \
        dnf update -y && \
        dnf install  -y --allowerasing systemd curl sudo vim ncurses; \
    elif [ "$PKG_MANAGER" = "zypper" ]; then \
        zypper refresh && \
        zypper --non-interactive update && \
        zypper --non-interactive install systemd curl sudo vim; \
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

# Set the root password.
RUN echo 'root:password' | chpasswd

# Run systemd as the init process.
CMD ["/sbin/init"]
