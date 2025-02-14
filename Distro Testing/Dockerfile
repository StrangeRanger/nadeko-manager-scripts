# syntax=docker/dockerfile:1
##############################
# This Dockerfile is parameterized via build-args.
# It expects:
#   - BASE_IMAGE: the base Docker image (e.g. ubuntu:24.04)
#   - PKG_MANAGER: one of "apt", "dnf", "zypper", or "pacman"
##############################

ARG BASE_IMAGE
FROM ${BASE_IMAGE}

# Re-declare the BASE_IMAGE build argument so it’s available in the next stages.
ARG BASE_IMAGE
ARG PKG_MANAGER

LABEL org.opencontainers.image.source="https://github.com/StrangeRanger/nadeko-manager-scripts"
LABEL org.opencontainers.image.authors="strangeranger@hthompson.dev"
LABEL org.opencontainers.image.description="A Docker image to test NadekoBot's Manager scripts on ${BASE_IMAGE} image."

ENV container=docker
ENV DEBIAN_FRONTEND=noninteractive

COPY install-deps.bash /usr/local/sbin/install-deps.bash
RUN chmod +x /usr/local/sbin/install-deps.bash \
    && /usr/local/sbin/install-deps.bash "$PKG_MANAGER" \
    && rm /usr/local/sbin/install-deps.bash

WORKDIR /root/NadekoBot

COPY setup.bash /usr/local/sbin/setup.bash
RUN chmod +x /usr/local/sbin/setup.bash \
    && /usr/local/sbin/setup.bash \
    && rm /usr/local/sbin/setup.bash

CMD ["/sbin/init"]
