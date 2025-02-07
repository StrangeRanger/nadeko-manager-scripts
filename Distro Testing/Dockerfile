# syntax=docker/dockerfile:1
##############################
# This Dockerfile is parameterized via build-args.
# It expects:
#   - BASE_IMAGE: the base Docker image (e.g. ubuntu:22.04)
#   - PKG_MANAGER: one of "apt", "dnf", or "zypper"
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
    else \
        echo "Unsupported package manager: $PKG_MANAGER" && exit 1; \
    fi

# Set the root password.
RUN echo 'root:password' | chpasswd

# Run systemd as the init process.
CMD ["/sbin/init"]
