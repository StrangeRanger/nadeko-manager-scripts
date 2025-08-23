# Nadeko Manager Scripts

[![Project Tracker](https://img.shields.io/badge/repo%20status-Project%20Tracker-lightgrey)](https://hthompson.dev/project-tracker#project-297718786)
[![Style Guide](https://img.shields.io/badge/code%20style-Style%20Guide-blueviolet)](https://bsg.hthompson.dev/)
[![Codacy Badge](https://app.codacy.com/project/badge/Grade/63b063408cea4065a5dbe8e7ba8fdfd2)](https://www.codacy.com/gh/StrangeRanger/nadeko-manager-scripts/dashboard?utm_source=github.com&utm_medium=referral&utm_content=StrangeRanger/nadeko-manager-scripts&utm_campaign=Badge_Grade)

Nadeko Manager Scripts is a collection of Bash scripts that automates the complete lifecycle management of [NadekoBot](https://github.com/nadeko-bot/nadekobot) v6 on Linux systems. Designed for both beginners and experienced users, it eliminates the complexity of manual bot setup and maintenance through a simple, interactive interface.

<details>
<summary><strong>Table of Contents</strong></summary>

- [Nadeko Manager Scripts](#nadeko-manager-scripts)
  - [Demo](#demo)
  - [Features](#features)
  - [Getting Started](#getting-started)
    - [Prerequisites](#prerequisites)
    - [Download and Setup](#download-and-setup)
    - [Configurations](#configurations)
      - [Configurable Variables](#configurable-variables)
  - [Usage](#usage)
  - [Uninstallation](#uninstallation)
    - [Step 1: Stop and Remove the Service](#step-1-stop-and-remove-the-service)
    - [Step 2: Remove Manager Scripts](#step-2-remove-manager-scripts)
    - [Step 3: Remove NadekoBot Data (Optional)](#step-3-remove-nadekobot-data-optional)
  - [Supported Distributions](#supported-distributions)
  - [Testing](#testing)
  - [Support and Issues](#support-and-issues)
  - [License](#license)

</details>

## Demo

[![asciicast](https://asciinema.hthompson.dev/a/3.svg)](https://asciinema.hthompson.dev/a/3)

## Features

- **Easy Installation & Updates**: Download and update NadekoBot with a single command
- **Service Management**: Start, stop, and monitor NadekoBot as a systemd service with auto-restart capabilities
- **Automatic Prerequisites**: Install all required dependencies (Python, ffmpeg, yt-dlp, etc.) for supported distributions
- **Backups**: Back up important files (database, credentials, configuration)
- **Real-time Monitoring**: View live colorized service logs with easy controls
- **Self-Updating**: Automatically updates manager scripts while preserving your configurations
- **Distribution Support**: Tested and supported across 9+ Linux distributions (Ubuntu, Debian, Fedora, Arch, etc.)
- **Safe Configuration**: Preserves user settings during updates with automatic migration
- **Menu-Driven Interface**: Simple, interactive menu with context-aware option enabling/disabling
- **Multiple Run Modes**: Run NadekoBot normally or with automatic restart on failure

## Getting Started

### Prerequisites

Most prerequisites for running the Nadeko Manager Scripts are handled automatically by the `n-prereqs.bash` script, but you will need the following minimum requirements:

**System Requirements:**
- **Bash**: Version 4.0 or higher
- **curl**: For downloading scripts
- **systemd**: Required for service management
- **64-bit Linux system**: 32-bit systems are not supported

**Permissions:**
- **Root or sudo access**: Required for installing packages and managing systemd services

### Download and Setup

The only script that needs to be downloaded to your system is `m-bridge.bash`. To do this, execute the following commands:

```bash
curl -O https://raw.githubusercontent.com/StrangeRanger/nadeko-manager-scripts/main/m-bridge.bash
chmod +x m-bridge.bash
```

### Configurations

You can customize the behavior of the Nadeko Manager by editing a few variables at the top of the `m-bridge.bash` script.

> [!NOTE]
> When the Manager updates itself, your changes to these variables (except for `manager_repo` and `E_FILES_TO_BACK_UP`) will be automatically merged into the new version. Changes to `manager_repo` and `E_FILES_TO_BACK_UP` must be reapplied manually if needed. The previous version of `m-bridge.bash` is backed up as `m-bridge.bash.old` in the same directory for reference or recovery.

#### Configurable Variables

- **manager_repo**: The GitHub repository to fetch manager scripts from
  - Default: `"StrangeRanger/nadeko-manager-scripts"`

- **manager_branch**: The branch to use when downloading scripts
  - Options:
    - `main` (stable, recommended)
    - `dev` (development, may be unstable)
    - `NadekoV5` (for NadekoBot v5)
  - Default: `"main"`

- **E_SKIP_PREREQ_CHECK**: Skip the prerequisites check if set to `"true"`
  - Options:
    - `true`: Skip checking for required packages (not recommended unless you know what you’re doing)
    - `false`: Check for prerequisites (recommended)
  - Default: `"false"`

- **E_FILES_TO_BACK_UP**: List of files to back up when using the backup option
  - Paths must start from Nadeko's parent directory (e.g., `nadekobot/data/creds.yml`)
  - Separate multiple files with spaces or newlines
  - Do not use commas or paths with spaces
  - Default files:
    ```
    nadekobot/data/NadekoBot.db
    nadekobot/data/NadekoBot.db-shm
    nadekobot/data/NadekoBot.db-wal
    nadekobot/data/bot.yml
    nadekobot/data/creds.yml
    ```

## Usage

To start the Manager, execute the following command in the directory where you downloaded `m-bridge.bash`:

```bash
./m-bridge.bash
```

If successful, you'll see a menu with the following options:

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

**First-time setup:**
1. Start with option **6** to install prerequisites
2. Use option **1** to download NadekoBot
3. Configure your bot credentials (see [NadekoBot documentation](https://nadekobot.readthedocs.io/en/latest/creds-guide/))
4. Use option **2** or **3** to start your bot

## Uninstallation

> [!IMPORTANT]
> Only remove the `nadekobot` directory and backup folders if you are certain you no longer need your bot data or backups.

To completely remove the Nadeko Manager Scripts and related files from your system, follow the below steps.

### Step 1: Stop and Remove the Service
```bash
sudo systemctl stop nadeko.service
sudo systemctl disable nadeko.service
sudo rm -f /etc/systemd/system/nadeko.service
sudo systemctl daemon-reload
```

### Step 2: Remove Manager Scripts
```bash
rm -f m-bridge.bash
rm -f NadekoRun
```

### Step 3: Remove NadekoBot Data (Optional)
```bash
# Remove backup directories
rm -rf important-files-backup

# Remove NadekoBot installation and old versions
rm -rf nadekobot nadekobot.old
```

## Supported Distributions

The following is a list of all the Linux distributions that the Manager has been tested and are officially supported on:

| Distro/OS | Version Number | End of Life | EOL Information |
| --------- | -------------- | ----------- | --------------- |
| Ubuntu | 24.04<br>22.04 | April 25, 2029<br>April 01, 2027 | [endoflife.date](https://endoflife.date/ubuntu)<br>[ubuntu.com](https://ubuntu.com/about/release-cycle) |
| Linux Mint | 22<br>21 | April 30, 2029<br>April 30, 2027 | [endoflife.date](https://endoflife.date/linuxmint)<br>[linuxmint.com](https://linuxmint.com/download_all.php) |
| Debian | 12 | June 10, 2026 | [endoflife.date](https://endoflife.date/debian)<br>[wiki.debian.org](https://wiki.debian.org/DebianReleases) |
| Fedora | 41<br>40 | November 19, 2025<br>May 28, 2025 | [endoflife.date](https://endoflife.date/fedora)<br>[docs.fedoraproject.org](https://docs.fedoraproject.org/en-US/releases/lifecycle/)<br>[fedorapeople.org](https://fedorapeople.org/groups/schedule/) |
| Alma Linux | 9<br>8 | May 31, 2032<br>March 01, 2029 | [endoflife.date](https://endoflife.date/almalinux)<br>[wiki.almalinux.org](https://wiki.almalinux.org/release-notes/) |
| Rocky Linux | 9<br>8 | May 31, 2032<br>May 31, 2029 | [endoflife.date](https://endoflife.date/rockylinux)<br>[wiki.rockylinux.org](https://wiki.rockylinux.org/rocky/version/) |
| OpenSuse Leap | 15.6 | December 31, 2025 | [endoflife.date](https://endoflife.date/opensuse)<br>[en.opensuse.org](https://en.opensuse.org/Lifetime) |
| OpenSuse Tumbleweed | Rolling | N/A | N/A |
| Arch Linux | Rolling | N/A | N/A |

## Testing

The Manager has been tested across multiple Linux distributions using Docker containers. The testing infrastructure is located in the `Distro Testing` directory.

**Two testing methods are available:**

- **Pre-built Images from Docker Hub** (Recommended): Pull and run pre-built images for each distribution. For detailed instructions on how to run and interact with these images, refer to the [Docker Hub repository](https://hub.docker.com/r/strangeranger/nadeko-manager-testing).

- **Building Images Locally**: If you prefer to build the images on your machine, you can execute the provided script that builds all images locally:

  ```bash
  cd "Distro Testing"
  ./build-docker-images.bash
  ```

  Once built, you can run the images using the same instructions provided in the [Docker Hub repository](https://hub.docker.com/r/strangeranger/nadeko-manager-testing).

## Support and Issues

Please use [GitHub Issues](https://github.com/StrangeRanger/nadeko-manager-scripts/issues) for bug reports and feature requests.

## License

This project is licensed under the [MIT License](LICENSE).
