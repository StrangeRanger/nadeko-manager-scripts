# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [v6.1.0] - 2025-05-15

⚠️ This release removes support for NadekoBot v5 in favor of v6. ⚠️

### Added

- Colorize the release versions to easily identify the current version of NadekoBot and which ones are newer and older.

### Changed

- ⚠️ Remove support for NadekoBot v5 in favor of v6.
- Simplified and improved how NadekoBot release archives are handled and extracted.
- Improved how the Manager checks if certain steps or actions need to be reverted.

### Fixed

- Fixed incorrect usage of sub-shells to ensure proper error handling.
- Other small fixes and improvements.

## [v6.0.0] - 2025-02-16

Yes, it's another major release—but with good reason. Many long-awaited changes have been implemented since v5.0.0, including significant improvements and some breaking changes. All breaking changes continue to be handled automatically, so no manual intervention is required. Below is a summary of the most important updates to the installer, now rebranded as the Manager.

### Added

- **Support for New Linux Distributions:**
    - Fedora 41
    - Fedora 40
    - Alma Linux 9
    - Alma Linux 8
    - Rocky Linux 9
    - Rocky Linux 8
    - OpenSuse Leap 15.6
    - OpenSuse Tumbleweed
    - Arch Linux
- **Enhanced `NadekoRun` Script:**
    - Displays additional information, including the current paths for `python3` and `yt-dlp`, as well as the current version of `python3`.
- **New Configurable Variable in `m-bridge.bash`:**
    - `E_SKIP_PREREQ_CHECK`: Allows users to skip the prerequisite check when executing the script. This setting persists when a new version of `m-bridge.bash` is downloaded.
- **Distro Testing Directory:**
    - A new directory has been created to simplify Manager testing:
        - **`build-docker-images.bash`:** Uses the provided `Dockerfile` to build images for each supported distribution, enabling container-based testing of the Manager.
        - **Pre-built Docker Images:** If you prefer not to build images locally, pre-built Docker images for testing the Manager are available on [Docker Hub](https://hub.docker.com/r/strangeranger/nadeko-manager-testing/).
- **System Requirement:**
  - ⚠️ `systemd` is now a hard requirement for the Manager.

### Changed

- **Rebranding:**
  - The Installer is now called the Manager, reflecting its functionality beyond simply installing the bot and its prerequisites.
- **Script Renaming:**
  - `linuxAIO` → `m-bridge.bash`
  - `installer-prep` → `m-bridge-prep.bash`
  - `nadeko-latest-installer` → `m-update.bash`
  - `nadeko-main-installer` → `n-main.bash`
  - `file-backup` → `n-file-backup.bash`
  - `nadeko-runner` → `n-runner.bash`
  - `prereqs-installer` → `n-prereqs.bash`
  - `update-linuxAIO` → `n-update-bridge.bash`
- **Variable Modifications:**
  - Several variables in `m-bridge.bash` (formerly `linuxAIO`) have been updated.
- **Prerequisite Simplification:**
  - Streamlined the prerequisites for NadekoBot.
- **Compatibility Checks:**
  - The Manager now only verifies the system's bit-type and whether it uses `systemd`. Distribution and version checks are deferred to the prerequisite installation phase.
- **Reduced External Dependencies:**
  - Reduced reliance on external tools, such as `awk`.
- **Upgrade Transition:**
  - Repurposed the previous version of `installer-prep` to ensure a smooth transition from revision 47 to 48+ (i.e., from Manager v5.0.x to v6.0.0).
- **Improved Log Monitoring:**
  - The Manager now waits for the user to press the `Enter` key to stop monitoring service logs, instead of requiring `Ctrl` + `C`.

### Removed

- **Deprecated Distribution Support:**
  - ⚠️ Debian 11 — End-of-life.
  - ⚠️ Ubuntu 20.04 — Requires Python 3.9+, which is not available.
  - ⚠️ Linux Mint 20 — Requires Python 3.9+, which is not available.

## [v5.0.0] - 2025-02-01

### Added

- `jq` is now installed as a prerequisite on all supported distributions.

### Changed

- ⚠️ No longer downloads NadekoBot via `git clone`, and instead downloads them for pre-built releases.
    - As a result of this, the following changes have been made:
        - ⚠️ Several prerequisites have been removed, namely .NET SDK, as the release is self-contained and doesn't need to be built from source.
        - ⚠️ Structure of NadekoBot's directory has changed to only contain the compiled code and any other relevant files.
        - ⚠️ Configurations/structure for `E_FILES_TO_BACK_UP` in `linuxAIO` has been updated to reflect the changes made to NadekoBot's directory structure.
        - `E_BOT_INSTALL_VERSION` has been removed from `linuxAIO`, as it's no longer needed.
            - When installing NadekoBot, the installer will provide the user with the available releases you can download and install.
- Greatly improved comments and documentation.
- Greatly improved code clarity via variable naming and structure.
- Improve architecture and bit type detection.

## [v4.0.1] - 2024-12-19

### Changed

- Moved "changing working directory to that of executed script" code from `installer-prep` to `linuxAIO`.

### Removed

- Removed `testing` branch as an option to download NadekoBot from.

### Fixed

- The code mentioned in the "Changed" section, now ACTUALLY changes the working directory to that of the executed script. Previously it changed to the directory where `installer-prep` was located.

## [v4.0.0] - 2024-12-17

> [!IMPORTANT]
> This MAY be one of the final releases, as this project will enter a maintenance phase, or be archived in the future. This is primarily due to the fact that I don't often use NadekoBot anymore, and the NadekoBot team, a while back, decided not to merge this installer into the main installer repository, which is completely understandable.

This release introduces A LOT of changes to the installer, including some breaking changes. These are listed in the below changelog, but some of the main changes include the naming of specific files produced by the installer, supporting NadekoBot v5, and improved visuals and error handling. This means that you will need to manually change the names of several files, if you wish to keep them.

### Added

- Add support for NadekoBot v5.
- Added support for the following distributions and their versions:
    - Ubuntu 24.04
    - Linux Mint 22
    - Debian 12
- Users can now use `Ctrl` + `C` to safely cancel the installation of NadekoBot prerequisites.
    - I believe this is already available to the other options, but if not, this can also be done when:
        - backing up important files.
        - setting up or updating NadekoBot.
- The install checks if the `token` in `creds.yml` is set, before allowing the user to start NadekoBot.

### Changed

#### Braking Changes

- ⚠️ Old nadekobot versions are now stored in `nadekobot.old` instead of `nadekobot_old`.
- ⚠️ Old strings are now stored in `strings.old` instead of `strings_old`.
- ⚠️ Old aliases are now stored in `aliases.old` instead of `aliases_old`.
- ⚠️ Backed up files are now stored in `important-files-backup` instead of `important_file_backup`.
- ⚠️ Replace `youtube-dl` with `yt-dlp`.

#### Improvements

- Comments have been removed where they were unnecessary, added where they were needed, and improved where they were lacking.
- Colorization of output text has been modified to improve readability and indicate the type of information being displayed.
- Stronger and more robust error handling has been implemented.
- Error codes are better defined and do not interfere with standard/built-in exit codes.
- Temporary files are handled more efficiently and are removed when no longer needed.
- Previous version of NadekoBot is restored if an error occurs during the download or compilation of NadekoBot.
- Previous backups are restored if an error occurs during the backup process.
- Better output and reasons for why some options are disabled.

#### Programmatic-ish Changes

- Exported variables are now styled as `E_UPPER_CASE`.
- Constant variables are now styled as `C_UPPER_CASE`.

#### Other Changes

- Ownership of `$HOME/.nuget` is no longer modified.
- If `creds.yml` does not exist, the installer will create it.
- Option 4 is conditionally enabled/disabled based on the status of NadekoBot.

### Removed

- ⚠️ Removed support for NadekoBot v4.
- ⚠️ Removed support for distributions:
    - ⚠️ Ubuntu 20.04, due to end of life in about 3 months.
    - ⚠️ Ubuntu 18.04, due to end of life.
    - ⚠️ Linux Mint 20, due to end of life in about 4 months.
    - ⚠️ Debian 10, due to end of life.

### Fixed

- Fixed text displaying `Mewdeko` instead of `NadekoBot`.
- Fixed, what appeared to be, the installer catching signals multiple times.
- Removed unnecessary `exec` that resulted in duplicate output.

## [v3.2.5] - 2022-09-06

### Added

- Officially supports Linux Mint 21

### Changed

- ⚠️ Renamed all of the scripts and removed their extension `.sh`.
    - `installer_prep.sh` has been modified to easily transition between the change.
- Replaced the use of master with main.
- Revert some if statements to fix possible SC2015 problems.
- When new version of 'linuxAIO' is found, wait for user input before downloading the latest version.

### Removed

- ⚠️ Support for the following have been removed:
    - Debian 9      (due to end of life)
    - Ubuntu 16.04  (due to end of active support)
    - Linux Mint 19 (due to end of active support)
- Removed code that is no longer applicable, due to other changes.

### Fixed

- Fixed misspelling of `exit`
- Dotnet SDK not installing/being removed due to a [change made by Microsoft](https://github.com/dotnet/core/issues/7699).

## [v3.2.4] - 2022-07-19

### Changed

- Where possible, replaced commands with Parameter Expansion.
- Where applicable, refactored if statements to be more simplistic and functional.
- Changed how the variables used to change the color of output text, are formatted, in the hopes of increasing portability.
- Improve exit code functionality:
    - Modified traps to provide proper signal exit codes.
        - Example: 128+n where n is the signal number, such as 9 being SIGKILL.
    - Changed exit codes to non-reserved exit codes.
- NadekoBot daemon uses `journal` for `StandardOutput` and `StandardError`, instead of `syslog`, if systemd version is 246 or later.
- Checks if `/home/$USER/.nuget` exists before attempting to chown it.
- Small formatting and style changes.

### Fixed

- Not properly retrieving `systemd` version number.
- Bad formatting of some output.
- Incorrect text printed to terminal.

## [v3.2.3] - 2022-06-20

### Added

- Officially supports:
    - Ubuntu 22.04
    - Debian 11
- Shellcheck disable comments.

### Changed

- No longer outputs "Script forcefully stopped" when 'Ctrl' + 'C' or 'Ctrl' + 'Z' is issued.
- Ensures that dotnet is installed, before attempting to retrieve it's version number.
- Changed the default branch from master to main.
- Removed non-existing file from local variable `installer_files`.
- `nadeko_master_installer` has been renamed to `nadeko_main_installer`.

### Removed

- ⚠️ No longer supports Linux Mint 18, due to EOL.

### Fixed

- `python-is-python3` not installed in place of `python`.

## [v3.2.2] - 2022-03-04

⚠️ This version of the bash scripts, enables compatibility with the new version (v4) of NadekoBot, but also results in the loss of compatibility with NadekoBot v3.

### Added

- Checks the version number of the installed dotnet, to ensure the correct dotnet version is installed.
- Adds compatibility for NadekoBot v4.

### Changed

- ⚠️ Installs dotnet v6 instead of v5.
    - This will result in the loss of compatibility with Nadeko v3.
- ⚠️ Uses NadekoBot branch v4 by default instead of v3.
- `nadeko.service` restarts on failure.
- `NadekoRun.sh` does a better job at handling errors, etc.
- Modified `$_FILES_TO_BACK_UP`.

### Fixed

- `nadeko_latest_installer.sh` didn't save/back up files to `nadekobot/output/data`
- `nadeko_latest_installer.sh` copied the entire `nadekobot/output/data` when attempting to copy the database.

## [v3.2.0] - 2021-10-04

⚠️ One of the biggest take away's from this update, is that the installer no longer supports macOS.

### Added

- Using disabled options will now provide reason(s) for why it and other options are disabled.
- An option (option 7) that can be used to back up important Nadeko files. These files can be configured within `linuxAIO.sh`. Do note that the installer doesn't move the current configuration of this option to the new version of `linuxAIO.sh`, unlike the other configurable options.

### Changed

- ⚠️ No longer compatible with `linuxAIO.sh` revision 8 and earlier.
- No longer prevents the execution of the installer as root.
- Option 4 is always enabled.
- `jq` is no longer installed.

### Removed

- ⚠️ Removed support for macOS, since this installer will not be adopted by Kwoth.
- The option to create and edit credentials to coincide with the official linux installer documentation.

### Fixed

- Several small fixes.

## [v3.1.1] - 2021-??-??

### Fixed

- The installer tried to use `jq` when it shouldn't have, even when it wasn't installed.

## [v3.1.0] - 2021-07-05

### Changed

- ⚠️ Improved system exiting by using exit codes instead of just executing `_CLEAN_EXIT` (which is no longer exported and was renamed to `clean_up`):
    - 1: Some error occurred that required the installer to be exited.
    - 2: Produced when the end-user uses `CTRL + C` or `CTRL + Z`.
    - 3: Unexpected internal error.
    - 4: Some error occurred that required the installer to return the its main menu.
    - 5: The installer was executed with root perms when `linuxAIO.sh` was configured to prevent such action.
- ⚠️ `python-is-python3` is installed as a prerequisite instead of `python`, when running on Ubuntu 20.04 and Linux Mint 20.
- NadekoBot's startup logs are displayed in realtime, instead of waiting 60 seconds.
- NadekoBot's logs are displayed in color (only applicable when run on Linux).
- Used parameter substitution were possible.
- Refactored and modified coding style to allow for better readability.
- Replaced ALL instances of `wget` with `curl`.
- Improved error catching/trapping.

### Removed

- Unnecessary and redundant code.

### Fixed

- `NadekoRunner.sh` getting stuck in an infinite while loop.

## [v3.0.4] - 2021-05-24

### Changed

- Refactored code to allow for better flexibility for the [following fixes](https://github.com/StrangeRanger/nadeko-manager-scripts/commit/4092d925677ade7a8f1ce18dc9d1b94baa80d531).
- Slightly changed the way that the new version of NadekoBot is downloaded and built.

## [v3.0.3] - 2021-05-23

### Summary

The most notable change in this version is the refactoring of the code used to download NadekoBot. I've provided information on what and how exactly it was refactored down below in the changed portion of this changelog.

### Changed

- ⚠️ Installs `dotnet-sdk-5.0` instead of `dotnet-sdk-3.1`.
- Option four is disabled if NadekoBot is not currently running.
- Major refactoring:
    - Code used to download NadekoBot has been moved to two files. One file specific to Linux and the other macOS.
    - Moved duplicate code into new functions.
    - etc.
- No longer creates NadekoBot's service at the time of execution. The service is created after a run mode is chosen and during the bot's startup.
- Curl related error catching has been removed.
    - Will be re-implemented in the future.
- Updated and added more comments.

### Fixed

- Typos in the menu output.
- Some `cp` flags weren't compatible with macOS's version of `cp`.
- A strange problem where if NadekoBot wasn't downloaded a specific way, errors could occur when trying to start NadekoBot.

## [v3.0.0] - 2021-05-15

### Breaking Changes

Due to some breaking changes inside of `linuxAIO.sh`, all users who are currently using `linuxAIO.sh` revision 8 and earlier will receive a message the next time they execute the script. The notice will inform users that they will need to download the newest version of `linuxAIO.sh` manually. The appropriate command to do this will be provided by the installer, based on the current configurations of `linuxAIO.sh`.

Additionally, you'll need to delete `/lib/systemd/system/nadeko.service`, as the service will now be stored in `/etc/systemd/system/nadeko.service`. To do this, run the following command: `sudo systemctl stop nadeko.service && sudo rm /lib/systemd/system/nadeko.service && sudo systemctl daemon-reload`. From here, execute `linuxAIO.sh` as you always do.

### Added

- The branch/tag to download NadekoBot from (e.g., `1.9`, `2.39.1`, etc.) is now configurable via `linuxAIO.sh`.
- The current value of `$allow_run_as_root` and `$_NADEKO_INSTALL_VERSION` is set whenever downloading the latest version of `linuxAIO`.

### Changed

- ⚠️ Exported variables are now styled as `_UPPER_CASE`.
- ⚠️ `nadeko.service` is created in `/etc/systemd/system/`, instead of `/lib/systemd/system/`.
- Updated and added A LOT of comments.
- Minor refactoring.

### Fixed

- macOS version scheme did not include minor versions of macOS 11.
- Several shellcheck errors and warnings.
- A bug where the `NadekoBot` directory could be deleted when trying to restore NadekoBot after canceling a download, even if `NadekoBot.bak`/`NadekoBot.old` didn't exist.

## [v2.1.1] - 2021-03-26

### Added

- The current value of `$installer_branch` is set whenever downloading the latest version of `linuxAIO`.
- `release/latest` is an optional branch for the `$installer_branch`.
- Officially supports:
    - macOS Big Sur
    - macOS Mojave

### Changed

- Comment and programming style.

### Fixed

- Shellcheck warnings [SC2064](https://github.com/koalaman/shellcheck/wiki/SC2064) and [SC2053](https://github.com/koalaman/shellcheck/wiki/SC2053).
- Several other shellcheck warnings.
- Issue [#14](https://github.com/StrangeRanger/nadeko-manager-scripts/issues/14).

## [v2.1.0] - 2020-12-10

Version 2.1.0 of the Nadeko Bash Scripts is a complete rewrite of the previous Bash Scripts. Below is a list of the most significant changes to the installer.

### Added

- Support for:
    - Ubuntu 20.04
    - Mint Linux: 19, 20
    - Debian 10
- An option to watch NadekoBot's logs live (as they are created).
- Indicates what mode NadekoBot is set up to or is currently running in.
- Improved error catching.
- End-user can configure the installer's behavior.
    - `linuxAIO.sh` consists of a few configurable settings that the end-user can modify.
- Installs both Homebrew and prerequisites on macOS.
    - Previously required manual installation.
- Displays NadekoBot's startup logs, when starting or restarting the bot.

### Changed

- Some options are disabled until certain prerequisites are met.
- Uses `systemctl` (Linux) and `launchctl` (macOS) to run NadekoBot, instead of PM2.
- Uses `curl` instead of `wget`.

### Removed

- Support for:
    - Ubuntu: 14.04, 16.10, 17.04, 17.10
    - Linux Mint: 17
    - Debian: 8
    - CentOS: 7
- The option to run NadekoBot with auto-update.

[unreleased]: https://github.com/StrangeRanger/nadeko-manager-scripts/compare/v6.1.0...HEAD
[v6.1.0]: https://github.com/StrangeRanger/nadeko-manager-scripts/releases/tag/v6.1.0
[v6.0.0]: https://github.com/StrangeRanger/nadeko-manager-scripts/releases/tag/v6.0.0
[v5.0.0]: https://github.com/StrangeRanger/nadeko-manager-scripts/releases/tag/v5.0.0
[v4.0.1]: https://github.com/StrangeRanger/nadeko-manager-scripts/releases/tag/v4.0.1
[v4.0.0]: https://github.com/StrangeRanger/nadeko-manager-scripts/releases/tag/v4.0.0
[v3.2.5]: https://github.com/StrangeRanger/nadeko-manager-scripts/releases/tag/v3.2.5
[v3.2.4]: https://github.com/StrangeRanger/nadeko-manager-scripts/releases/tag/v3.2.4
[v3.2.3]: https://github.com/StrangeRanger/nadeko-manager-scripts/releases/tag/v3.2.3
[v3.2.2]: https://github.com/StrangeRanger/nadeko-manager-scripts/releases/tag/v3.2.2
[v3.2.0]: https://github.com/StrangeRanger/nadeko-manager-scripts/releases/tag/v3.2.0
[v3.1.1]: https://github.com/StrangeRanger/nadeko-manager-scripts/releases/tag/v3.1.1
[v3.1.0]: https://github.com/StrangeRanger/nadeko-manager-scripts/releases/tag/v3.1.0
[v3.0.4]: https://github.com/StrangeRanger/nadeko-manager-scripts/releases/tag/v3.0.4
[v3.0.3]: https://github.com/StrangeRanger/nadeko-manager-scripts/releases/tag/v3.0.3
[v3.0.0]: https://github.com/StrangeRanger/nadeko-manager-scripts/releases/tag/v3.0.0
[v2.1.1]: https://github.com/StrangeRanger/nadeko-manager-scripts/releases/tag/v2.1.1
[v2.1.0]: https://github.com/StrangeRanger/nadeko-manager-scripts/releases/tag/v2.1.0
