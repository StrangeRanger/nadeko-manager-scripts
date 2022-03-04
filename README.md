# NadekoBot-BashScript

[![Project Tracker](https://img.shields.io/badge/repo%20status-Project%20Tracker-lightgrey)](https://randomserver.xyz/project-tracker.html#nadekobot-bashscript)
[![Style Guide](https://img.shields.io/badge/code%20style-Style%20Guide-blueviolet)](https://github.com/StrangeRanger/bash-style-guide)
[![Codacy Badge](https://app.codacy.com/project/badge/Grade/63b063408cea4065a5dbe8e7ba8fdfd2)](https://www.codacy.com/gh/StrangeRanger/NadekoBot-BashScript/dashboard?utm_source=github.com&amp;utm_medium=referral&amp;utm_content=StrangeRanger/NadekoBot-BashScript&amp;utm_campaign=Badge_Grade)

This is the unofficial installer for NadekoBot v4 on Linux distributions.

For information on setting up NadekoBot using this installer, visit the repository's [wiki](https://github.com/StrangeRanger/NadekoBot-BashScript/wiki).

## Getting Started

### Downloading linuxAIO.sh

The only script that needs to be manually downloaded to your system is `linuxAIO.sh`. To do this, execute the following set of commands:

`curl -O https://raw.githubusercontent.com/StrangeRanger/NadekoBot-BashScript/master/linuxAIO.sh && sudo chmod +x linuxAIO.sh`

### Usage

To use the installer, execute the following command: `./linuxAIO.sh`

If the following command was successfully executed, a menu with the following options (or something very similar) should be displayed:

``` txt
1. Download NadekoBot
2. Run NadekoBot in the background
3. Run NadekoBot in the background with auto restart
4. Stop NadekoBot
5. Display 'nadeko.service' logs in follow mode
6. Install prerequisites
7. Back up important files
8. Exit
```

Note that by default, the installer doesn't allow its execution with root privilege. For information on how to configure the installer's behavior, refer to [this section of the wiki](https://github.com/StrangeRanger/NadekoBot-BashScript/wiki/Installer-Info)

## Officially Supported Distributions

The following is a list of all the Linux distributions and macOS versions that the installer has been tested and are officially support on:

| Distro/OS  | Version Number      |
| ---------- | ------------------- |
| Ubuntu     | 20.04, 18.04, 16.04 |
| Linux Mint | 20, 19, 18          |
| Debian     | 10, 9               |
