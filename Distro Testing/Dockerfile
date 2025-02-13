# syntax=docker/dockerfile:1
##############################
# This Dockerfile is parameterized via build-args.
# It expects:
#   - BASE_IMAGE: the base Docker image (e.g. ubuntu:24.04)
#   - PKG_MANAGER: one of "apt", "dnf", "zypper", or "pacman"
##############################

# Declare the build argument for use in FROM.
ARG BASE_IMAGE
FROM ${BASE_IMAGE}

# Re-declare the build argument so it’s available in the next stages.
ARG BASE_IMAGE

# Allow build-time selection of package manager commands.
ARG PKG_MANAGER

## OCI annotation labels.
LABEL org.opencontainers.image.source="https://github.com/StrangeRanger/nadeko-manager-scripts"
LABEL org.opencontainers.image.authors="strangeranger@hthompson.dev"
LABEL org.opencontainers.image.description="A Docker image to test NadekoBot's Manager scripts on ${BASE_IMAGE} image."

# Tell systemd (and various packages) that we are in a container.
ENV container=docker

# Set non-interactive mode for package installations and upgrades on Debian-based systems.
ENV DEBIAN_FRONTEND=noninteractive

## Copy the 'install-deps.bash' script into the image and run it, then remove it.
COPY install-deps.bash /usr/local/sbin/install-deps.bash
RUN chmod +x /usr/local/sbin/install-deps.bash \
    && /usr/local/sbin/install-deps.bash "$PKG_MANAGER" \
    && rm /usr/local/sbin/install-deps.bash

# Set the working directory to the location of the NadekoBot Manager scripts.
WORKDIR /root/NadekoBot

## Copy the 'setup.bash' script into the image and run it, then remove it.
COPY setup.bash /usr/local/sbin/setup.bash
RUN chmod +x /usr/local/sbin/setup.bash \
    && /usr/local/sbin/setup.bash \
    && rm /usr/local/sbin/setup.bash

# Run systemd as the init process.
CMD ["/sbin/init"]
