# Nadeko Manager Scripts

[![Project Tracker](https://img.shields.io/badge/repo%20status-Project%20Tracker-lightgrey)](https://hthompson.dev/project-tracker#project-297718786)
[![Style Guide](https://img.shields.io/badge/code%20style-Style%20Guide-blueviolet)](https://bsg.hthompson.dev/)
[![Codacy Badge](https://app.codacy.com/project/badge/Grade/63b063408cea4065a5dbe8e7ba8fdfd2)](https://www.codacy.com/gh/StrangeRanger/nadeko-manager-scripts/dashboard?utm_source=github.com&utm_medium=referral&utm_content=StrangeRanger/nadeko-manager-scripts&utm_campaign=Badge_Grade)

Nadeko Manager Scripts is a collection of Bash scripts designed to simplify the installation, management, and maintenance of [NadekoBot](https://github.com/nadeko-bot/nadekobot) v6 on Linux systems. This unofficial toolset provides an easy-to-use, menu-driven interface for downloading, running, updating, and backing up NadekoBot, as well as managing prerequisites and service logs. Whether you’re setting up NadekoBot for the first time or maintaining an existing installation, these scripts aim to streamline the process across a wide range of supported Linux distributions.

<details>
<summary><strong>Table of Contents</strong></summary>

- [Nadeko Manager Scripts](#nadeko-manager-scripts)
  - [Demo](#demo)
  - [Getting Started](#getting-started)
    - [Prerequisites](#prerequisites)
    - [Download and Setup](#download-and-setup)
    - [Configurations: Customizing `m-bridge.bash`](#configurations-customizing-m-bridgebash)
  - [Usage](#usage)
  - [Uninstallation](#uninstallation)
  - [Supported Distributions](#supported-distributions)
  - [Testing](#testing)
  - [Support](#support)
  - [License](#license)

</details>

## Demo

[![asciicast](https://asciinema.hthompson.dev/a/3.svg)](https://asciinema.hthompson.dev/a/3)

## Getting Started

### Prerequisites

Most of the prerequisites for running the Nadeko Manager Scripts are handled automatically by `n-preqeqs.bash`, but at minimum, you will need the following software:

- **Bash** 4.0 or higher
- **curl**

Permissions:

- Root or sudo access is required to install and use the scripts.

### Download and Setup

The only script that needs to be downloaded to your system is `m-bridge.bash`. To do this, execute the following commands:

```bash
curl -O https://raw.githubusercontent.com/StrangeRanger/nadeko-manager-scripts/main/m-bridge.bash
chmod +x m-bridge.bash
```

### Configurations: Customizing `m-bridge.bash`

You can customize the behavior of the Nadeko Manager by editing a few variables at the top of the `m-bridge.bash` script. These variables are safe to change and will be preserved when the script updates itself.

> [!NOTE]
> When the manager updates itself, your changes to the below variables (except for `manager_repo` and `E_FILES_TO_BACK_UP`) will be merged into the new version automatically. The two variables that are not reverted to their default values.

**Configurable Variables:**

- **manager_repo**: The GitHub repository to fetch manager scripts from.
  - Default: `"StrangeRanger/nadeko-manager-scripts"`

- **manager_branch**: The branch to use when downloading scripts.
  - Options:
    - `main` (stable, recommended)
    - `dev` (development, may be unstable)
    - `NadekoV5` (for NadekoBot v5)
  - Default: `"main"`

- **E_SKIP_PREREQ_CHECK**: Skip the prerequisites check if set to `"true"`.
  - Options:
    - `true`: Skip checking for required packages (not recommended unless you know what you’re doing)
    - `false`: Check for prerequisites (recommended)
  - Default: `"false"`

- **E_FILES_TO_BACK_UP**: List of files to back up when using the backup option.
  - Paths must start from Nadeko’s parent directory (e.g., `nadekobot/data/creds.yml`).
  - Separate files with spaces or newlines.
  - Do not use commas or paths with spaces.
  - Default:
    ```bash
    nadekobot/data/NadekoBot.db
    nadekobot/data/NadekoBot.db-shm
    nadekobot/data/NadekoBot.db-wal
    nadekobot/data/bot.yml
    nadekobot/data/creds.yml
    ```

## Usage

To use the Manager, execute the following command: `./m-bridge.bash`

If the command was successfully executed, a menu with the following options (or something very similar) should be displayed:

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

## Uninstallation

To completely remove the Nadeko Manager Scripts and related files from your system, follow these steps:

> [!IMPORTANT]
> Only remove the `nadekobot` directory and backup folders if you are sure you no longer need your bot or backups.

1. **Stop NadekoBot and Remove the Systemd Service**
   ```bash
   sudo systemctl stop nadeko.service
   sudo systemctl disable nadeko.service
   sudo rm -f /etc/systemd/system/nadeko.service
   sudo systemctl daemon-reload
   ```

2. **Remove the Manager and Runner Script**
   ```bash
   rm -f m-bridge.bash
   rm -f NadekoRun
   ```

3. **Remove NadekoBot Backup and Data Directories (Optional)**
   ```bash
   rm -rf important-files-backup
   rm -rf nadekobot nadekobot.old
   ```

## Supported Distributions

The following is a list of all the Linux distributions that the Manager has been tested and are officially support on:

| Distro/OS           | Version Number | End of Life                       | EOL Information                                                                                                                                                                                        |
| ------------------- | -------------- | --------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Ubuntu              | 24.04<br>22.04 | April 25, 2029<br>April 01, 2027  | [endoflife.date](https://endoflife.date/ubuntu)<br>[ubuntu.com](https://ubuntu.com/about/release-cycle)                                                                                                |
| Linux Mint          | 22<br>21       | April 30, 2029<br>April 30, 2027  | [endoflife.date](https://endoflife.date/linuxmint)<br>[linuxmint.com](https://linuxmint.com/download_all.php)                                                                                          |
| Debian              | 12             | June 10, 2026                     | [endoflife.date](https://endoflife.date/debian)<br>[wiki.debian.org](https://wiki.debian.org/DebianReleases)                                                                                           |
| Fedora              | 41<br>40       | November 19, 2025<br>May 28, 2025 | [endoflife.date](https://endoflife.date/fedora)<br>[docs.fedoraproject.org](https://docs.fedoraproject.org/en-US/releases/lifecycle/)<br>[fedorapeople.org](https://fedorapeople.org/groups/schedule/) |
| Alma Linux          | 9<br>8         | May 31, 2032<br>March 01, 2029    | [endoflife.date](https://endoflife.date/almalinux)<br>[wiki.almalinux.org](https://wiki.almalinux.org/release-notes/)                                                                                  |
| Rocky Linux         | 9<br>8         | May 31, 2032<br>May 31, 2029      | [endoflife.date](https://endoflife.date/rockylinux)<br>[wiki.rockylinux.org](https://wiki.rockylinux.org/rocky/version/)                                                                               |
| OpenSuse Leap       | 15.6           | December 31, 2025                 | [endoflife.date](https://endoflife.date/opensuse)<br>[en.opensuse.org](https://en.opensuse.org/Lifetime)                                                                                               |
| OpenSuse Tumbleweed | Rolling        | N/A                               | N/A                                                                                                                                                                                                    |
| Arch Linux          | Rolling        | N/A                               | N/A                                                                                                                                                                                                    |

## Testing

I've utilized Docker images to test the Manager on various Linux distributions. This is done via the Dockerfile and script located in the `Distro Testing` directory.

There are two methods to test the Manager scripts:

1. **Pulling Pre-built Images from Docker Hub**: You can pull the pre-built images for each distribution using the appropriate tags. For detailed instructions on how to run and interact with these images, refer to the [Docker Hub repository](https://hub.docker.com/r/strangeranger/nadeko-manager-testing).
2. **Building Images Locally**: If you prefer to build the images on your machine, you can execute the provided script that builds all of the images locally. Simply run:

   ```bash
   cd "Distro Testing"
   ./build-docker-images.bash
   ```

   This script will construct the Docker images for all supported Linux distributions. Once the build process completes, you can run the images using the same instructions as for the pre-built versions.

For more information on how to interact with and run the images, see the instructions on the [Docker Hub repository](https://hub.docker.com/r/strangeranger/nadeko-manager-testing).

## Support

For questions, suggestions, or bug reports, please open an issue on [GitHub](https://github.com/StrangeRanger/mass-git/issues).

## License

This project is licensed under the [MIT License](LICENSE).
