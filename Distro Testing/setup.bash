#!/usr/bin/env bash
#
# Create a shared directory to be used by all the docker containers, and download the
# linuxAIO script.
#
########################################################################################

C_LINUXAIO_BRANCH="dev"
C_LINUXAIO_URL="https://raw.githubusercontent.com/StrangeRanger/NadekoBot-BashScript/refs/heads/$C_LINUXAIO_BRANCH/linuxAIO"

if [[ ! -d shared ]]; then
    echo "Creating shared directory..."
    mkdir shared
else
    echo "Shared directory already exists"
fi

if [[ ! -f shared/linuxAIO ]]; then
    echo "Downloading linuxAIO..."
    curl -L "$C_LINUXAIO_URL" -o shared/linuxAIO
else
    echo "linuxAIO already exists"
fi

echo "Setting linuxAIO as executable..."
chmod +x shared/linuxAIO

echo "Setup complete"
