# NadekoBot-BashScript

[![Project Tracker](https://img.shields.io/badge/repo%20status-Project%20Tracker-lightgrey)](https://wiki.hthompson.dev/en/project-tracker)
[![Style Guide](https://img.shields.io/badge/code%20style-Style%20Guide-blueviolet)](https://github.com/StrangeRanger/bash-style-guide)
[![Codacy Badge](https://app.codacy.com/project/badge/Grade/63b063408cea4065a5dbe8e7ba8fdfd2)](https://www.codacy.com/gh/StrangeRanger/NadekoBot-BashScript/dashboard?utm_source=github.com&utm_medium=referral&utm_content=StrangeRanger/NadekoBot-BashScript&utm_campaign=Badge_Grade)

This is the unofficial installer for NadekoBot v5 on Linux distributions.

## Getting Started

### Downloading linuxAIO

The only script that needs to be manually downloaded to your system is `linuxAIO`. To do this, execute the following set of commands:

`curl -O https://raw.githubusercontent.com/StrangeRanger/NadekoBot-BashScript/NadekoV5/linuxAIO && chmod +x linuxAIO`

### Usage

To use the installer, execute the following command: `./linuxAIO`

If the following command was successfully executed, a menu with the following options (or something very similar) should be displayed:

```txt
1. Download NadekoBot
2. Run NadekoBot in the background
3. Run NadekoBot in the background with auto restart
4. Stop NadekoBot
5. Display 'nadeko.service' logs in follow mode
6. Install prerequisites
7. Back up important files
8. Exit
```

## Officially Supported Distributions

The following is a list of all the Linux distributions that the installer has been tested and are officially support on:

| Distro/OS  | Version Number |
| ---------- | -------------- |
| Ubuntu     | 24.04, 22.04   |
| Linux Mint | 22, 21         |
| Debian     | 12, 11         |
