#!/usr/bin/env bash
#
# Build Docker images for various Linux distros. These will be used to manually test the
# NadekoBot setup script in different environments.
#
########################################################################################

set -e

# This associative array maps a distro key to the base image.
# (Use official images when available. For Linux Mint, we rely on community images.)
declare -A distros_base=(
    #[ubuntu-24.04]="ubuntu:24.04"
    #[ubuntu-22.04]="ubuntu:22.04"
    #[debian-12]="debian:12"
    #[debian-11]="debian:11"
    [linuxmint-22]="linuxmintd/mint22.1-amd64"  # Community image.
    [linuxmint-21]="linuxmintd/mint21.3-amd64"  # community image.
    #[fedora-41]="fedora:41"
    #[fedora-40]="fedora:40"
    #[almalinux-9]="almalinux:9"
    #[almalinux-8]="almalinux:8"
    #[rocky-9]="rockylinux:9"
    #[rocky-8]="rockylinux:8"
    #[opensuse-leap-15.6]="opensuse/leap:15.6"
    #[opensuse-tumbleweed]="opensuse/tumbleweed"
)

# This associative array maps the distro key to its package manager.
declare -A pkg_manager=(
    [ubuntu-24.04]="apt"
    [ubuntu-22.04]="apt"
    [debian-12]="apt"
    [debian-11]="apt"
    [linuxmint-22]="apt"
    [linuxmint-21]="apt"
    [fedora-41]="dnf"
    [fedora-40]="dnf"
    [almalinux-9]="dnf"
    [almalinux-8]="dnf"
    [rocky-9]="dnf"
    [rocky-8]="dnf"
    [opensuse-leap-15.6]="zypper"
    [opensuse-tumbleweed]="zypper"
)

# Build an image for each distro.
for distro in "${!distros_base[@]}"; do
    base_image="${distros_base[$distro]}"
    manager="${pkg_manager[$distro]}"
    image_tag="myimage-${distro}"

    echo "----------------------------------------"
    echo "Building image: $image_tag"
    echo "  Base image: $base_image"
    echo "  Package manager: $manager"
    docker build \
        --build-arg BASE_IMAGE="${base_image}" \
        --build-arg PKG_MANAGER="${manager}" \
        -t "${image_tag}" .
    echo "Built ${image_tag}"
done

echo "----------------------------------------"
echo "All images built successfully."
echo "You can now run the images with 'docker run -it --rm -v \"\$(pwd)/shared:/shared\" myimage-<distro>'"

