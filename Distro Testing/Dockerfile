# syntax=docker/dockerfile:1
##############################
# This Dockerfile is parameterized via build-args.
# It expects:
#   - BASE_IMAGE: the base Docker image (e.g. ubuntu:22.04)
#   - PKG_MANAGER: one of "apt", "dnf", or "zypper"
##############################

ARG BASE_IMAGE
FROM ${BASE_IMAGE}

# Allow build-time selection of package manager commands.
ARG PKG_MANAGER

# (For apt-based images, disable interactive prompts.)
ENV DEBIAN_FRONTEND=noninteractive

# Install required packages based on the package manager.
RUN if [ "$PKG_MANAGER" = "apt" ]; then \
        apt update && apt upgrade -y && apt install -y curl sudo vim && rm -rf /var/lib/apt/lists/*; \
    elif [ "$PKG_MANAGER" = "dnf" ]; then \
        dnf update -y && dnf -y install --allowerasing curl sudo vim ncurses; \
    elif [ "$PKG_MANAGER" = "zypper" ]; then \
        zypper refresh && zypper --non-interactive update && zypper --non-interactive install curl sudo vim; \
    else \
        echo "Unsupported package manager: $PKG_MANAGER" && exit 1; \
    fi

# Create a shared folder (this can be overlaid with a volume when running).
RUN mkdir -p /shared

# Set working directory.
WORKDIR /shared

# Default command: run an interactive shell.
CMD ["/bin/bash"]

