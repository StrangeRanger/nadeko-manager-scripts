# nadeko-manager-scripts

[![Project Tracker](https://img.shields.io/badge/repo%20status-Project%20Tracker-lightgrey)](https://wiki.hthompson.dev/en/project-tracker)
[![Style Guide](https://img.shields.io/badge/code%20style-Style%20Guide-blueviolet)](https://bsg.hthompson.dev/)
[![Codacy Badge](https://app.codacy.com/project/badge/Grade/63b063408cea4065a5dbe8e7ba8fdfd2)](https://www.codacy.com/gh/StrangeRanger/nadeko-manager-scripts/dashboard?utm_source=github.com&utm_medium=referral&utm_content=StrangeRanger/nadeko-manager-scripts&utm_campaign=Badge_Grade)

This is the unofficial installer and manager for NadekoBot v5 on Linux.

## Getting Started

### Downloading linuxAIO

The only script that needs to be downloaded to your system is `m-bridge.bash`. To do this, execute the following set of commands:

```bash
curl -O https://raw.githubusercontent.com/StrangeRanger/nadeko-manager-scripts/main/m-bridge.bash
chmod +x m-bridge.bash
```

### Usage

To use the manager, execute the following command: `./m-bridge.bash`

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

1. **Pulling Pre-built Images from Docker Hub**: You can pull the pre-built images for each distribution using the appropriate tags. For detailed instructions on how to run and interact with these images, refer to the [Docker Hub repository](https://hub.docker.com/repository/docker/strangeranger/nadeko-manager-testing/).

2. **Building Images Locally**: If you prefer to build the images on your machine, you can execute the provided script that builds all of the images locally. Simply run:

   ```bash
   cd "Distro Testing"
   ./build-docker-images.bash
   ```

   This script will construct the Docker images for all supported Linux distributions. Once the build process completes, you can run the images using the same instructions as for the pre-built versions.

For more information on how to interact with and run the images, see the instructions on the [Docker Hub repository](https://hub.docker.com/repository/docker/strangeranger/nadeko-manager-testing/).
