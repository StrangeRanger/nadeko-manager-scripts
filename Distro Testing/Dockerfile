# syntax=docker/dockerfile:1
#
# This Dockerfile is parameterized via build-args.
# It expects:
#   - BASE_IMAGE: The base Docker image (e.g. ubuntu:24.04).
#   - PKG_MANAGER: One of "apt", "dnf", "zypper", or "pacman".
#
###############################

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

RUN groupadd --system nadeko \
    && useradd -m -g nadeko -s /bin/bash nadeko \
    && echo "nadeko:NadekoBot123!" | chpasswd \
    && mkdir -p /home/nadeko/NadekoBot \
    && mkdir -p /etc/sudoers.d \
    && echo "nadeko ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/nadeko \
    && chmod 0440 /etc/sudoers.d/nadeko

COPY install-deps.bash /usr/local/sbin/install-deps.bash
RUN chmod +x /usr/local/sbin/install-deps.bash \
    && /usr/local/sbin/install-deps.bash "$PKG_MANAGER" \
    && rm /usr/local/sbin/install-deps.bash

WORKDIR /home/nadeko/NadekoBot

COPY setup.bash /usr/local/sbin/setup.bash
RUN chmod +x /usr/local/sbin/setup.bash \
    && /usr/local/sbin/setup.bash \
    && rm /usr/local/sbin/setup.bash \
    && chown -R nadeko:nadeko /home/nadeko \
    && chmod 700 /home/nadeko

CMD ["/sbin/init"]
