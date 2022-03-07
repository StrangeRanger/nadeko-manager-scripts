# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed

- No longer says "Script forcefully stopped" when the end-user uses 'Ctrl' + 'C' or 'Ctrl' + 'Z'.
- Ensures that dotnet is installed, before attempting to retrieve it's version number.
-
### Fixed

- Fixed `python-is-python3` not being installed in place of `python`.

## [3.2.2] 2022-03-04+
 
### Added

- Checks the version number of the installed dotnet, to ensure the correct dotnet version is installed.

### Changed

- Update the content of `nadeko.service` to restart on failure, etc.
- Update the content of `NadekoRun.sh` when running NadekoBot in the background with auto-restart. It now does a better job at handling errors, etc.
- Installs dotnet v6 instead of v5.
- Uses NadekoBot branch v4 by default instead of v3.
- Modified `$_FILES_TO_BACK_UP`.

### Fixed

- Fixed `nadeko_latest_installer.sh` not saving/backing up files to `nadekobot/output/data`, which somehow didn't break anything.
- Fixed `nadeko_latest_installer.sh` copy the entire `nadekobot/output/data` when attempting to copy the database.

## [3.2.0] - 2021-10-04

### Added

- Using disabled options will now provide reason(s) for why it and other options are disabled.
- New option (option 7) that can be used to back up important Nadeko files. These files can be configured within `linuxAIO.sh`. Do note that the installer doesn't move the current configuration of this option to the new version of `linuxAIO.sh`, unlike the other configurable options.

### Changed

- No longer prevents the execution of the installer as root.
- No longer compatible with `linuxAIO.sh` revision 8 and earlier.
- Removed option to create and edit credentials to coincide with the official linux installer documentation.
- Removed support for macOS, since this installer will not be adopted by Kwoth.
- Option 4 is always enabled.
- `jq` is no longer installed.

### Fixed

- Small fixes.

## [3.1.1] - 2021-xx-xx

### Fixed

- The installer tried to use `jq` when it shouldn't have (including times when it wasn't installed).

## [3.1.0] - 2021-07-05

### Changed

- Instead of waiting 60 seconds to display NadekoBot's startup logs, the logs are immediately displayed in real time, and can be stopped by using '`CTRL` + `C`'.
- When displaying the service logs, they are now output in colored text using `ccze` (which has become a new dependency installed via the `prereqs_installer` script) (only applicable when run on Linux).
- `NadekoRunner.sh` will now exit if an error occurs, instead of being stuck in an infinite while loop.
- Used parameter substitution were possible.
- Performed some refactoring and style changes to allow for better readability.
- Removed unnecessary-redundant code.
- Replaced all instances of `wget` with `curl`.
- Improved error catching/trapping.
- Improved system exiting by using exit codes instead of just executing `_CLEAN_EXIT` (which is no longer exported and was renamed to `clean_up`):
  - 1: Some error occurred that required the installer to be exited.
  - 2: Produced when the end-user uses `CTRL + C` or `CTRL + Z`.
  - 3: Unexpected internal error.
  - 4: Some error occurred that required the installer to return the its main menu.
  - 5: The installer was executed with root perms when `linuxAIO.sh` was configured to prevent such action.
- `python-is-python3` is installed as a prerequisite instead of `python`, when running on Ubuntu 20.04 and Linux Mint 20.

## [3.0.4] - 2021-05-24

### Changed

- Modified code to allow more flexibility for the [following fix](https://github.com/StrangeRanger/NadekoBot-BashScript/commit/4092d925677ade7a8f1ce18dc9d1b94baa80d531).
- Slightly changed the way that the new version of NadekoBot is downloaded and built

## [3.0.3] - 2021-05-23

### Summary

The most notable change in this version is the refactoring of the code used to download NadekoBot. I've provided information and what and how exactly it was refactored down below in the changed portion of this changelog. The change was done in the hopes that it will allow for the installer to be just a bit easier to maintain and modify, and organized.

### Changed

- Option four will become disabled if NadekoBot is not currently running.
- Major refactoring:
  - Code used to download NadekoBot has been moved to two files. One file specific to Linux and the other macOS.
  - Moving duplicate code into new functions.
  - etc.
- No longer creates NadekoBot's service at the time of execution. The service is created after a run mode is chosen and during the bot's startup.
- Current `linuxAIO.sh` revision number: 17
  - This means that the script has been modified in some way.
- Curl related error catching has been removed.
  - Will be re-implemented in the future.
- Installs `dotnet-sdk-5.0` instead of `dotnet-sdk-3.1`.
- Update and add more comments.

### Fixed

- Fixed typos in the menu output.
- Fixed `cp` flags that weren't compatible with macOS's version of `cp`.
- Fixed a strange problem where if NadekoBot wasn't downloaded a specific way, errors could occur when trying to start NadekoBot.

## [3.0.0] - 2021-05-15

### Breaking Changes

Due to some breaking changes inside of `linuxAIO.sh`, all users who are currently using `linuxAIO.sh` revision 8 and earlier will receive a message the next time they execute the script. The notice will inform users that they will need to download the newest version of `linuxAIO.sh` manually. The appropriate command to do this will be provided by the installer, based on the current configurations of `linuxAIO.sh`.

Additionally, you'll need to delete `/lib/systemd/system/nadeko.service`, as the service will now be stored in `/etc/systemd/system/nadeko.service`. To do this, run the following command: `sudo systemctl stop nadeko.service && sudo rm /lib/systemd/system/nadeko.service && sudo systemctl daemon-reload`. From here, execute `linuxAIO.sh` as you always do.

### Added

- End-user can now configure what branch/tag to download NadekoBot from (i.e., `1.9`, `2.39.1`, etc.).
- `$allow_run_as_root` and `$_NADEKO_INSTALL_VERSION` are now set the same way that `$installer_branch` is set, whenever a new version of 'linuxAIO.sh' is retrieved.

### Changed

- ⚠️ The majority of exported variables are now styled as `_UPPER_CASE`.
- Updated and added A LOT of comments.
- Minor refactoring.
- ⚠️ `nadeko.service` will now be created and placed in `/etc/systemd/system/`, instead of `/lib/systemd/system/`.

### Fixed

- Fixed macOS version scheme, so installer works on all minor revisions of macOS 11.
- Fixed several shellcheck errors and warnings.
- Fixed a bug where the `NadekoBot` directory could be deleted when trying to restore NadekoBot after canceling a download, even if `NadekoBot.bak`/`NadekoBot.old` doesn't exist.

## [2.1.1] - 2021-03-26

### Added

- Whenever downloading the latest `linuxAIO.sh`, the current `installer_branch` will be applied to the new `linuxAIO.sh`.
- Added `release/latest` as an optional branch for the `installer_branch`.
- Officially supports macOS Big Sur.
- Officially supports macOS Mojave.

### Changed

- Modified comment and programming style.

### Fixed

- Fixed shellcheck warnings SC2064 SC2053.
- Fixed several other shellcheck warnings.
- Fixed issue #14.

## [2.1.0] - 2020-12-10

Version 2.1.0 of the Nadeko Bash Scripts is a complete rewrite of the previous Bash Scripts. Below is a list of the most significant changes to the installer.

### Added

- Added support for:
  - Ubuntu 20.04
  - Mint Linux: 19, 20
  - Debian 10
- Indicates what run-mode NadekoBot is currently set up to or is running in.
- Added an option to watch NadekoBot's logs live (as they are created).
- Better error catching.
- End-user has more control over the installer.
  - `linuxAIO.sh` consists of a few configurable settings the end-user can modify.
- Installs both Homebrew and prerequisite on macOS (previously required manual installation).
- After starting NadekoBot, a startup log is displayed to allow the end-user to identify possible errors better.

### Changed

- Installer disables specific options until a prerequisite is met.
- Uses systemctl (Linux) and launchctl (macOS) to run NadekoBot, instead of PM2.
- Relies on curl more than wget.

### Removed

- Removed support for:
  - Ubuntu: 14.04, 16.10, 17.04, 17.10
  - Linux Mint: 17
  - Debian: 8
  - CentOS: 7
- Removed option to run NadekoBot with auto-update

[unreleased]: https://github.com/StrangeRanger/NadekoBot-BashScript/compare/v3.2.2...HEAD
[3.2.2]: https://github.com/StrangeRanger/NadekoBot-BashScript/releases/tag/v3.2.2
[3.2.0]: https://github.com/StrangeRanger/NadekoBot-BashScript/releases/tag/v3.2.0
[3.1.1]: https://github.com/StrangeRanger/NadekoBot-BashScript/releases/tag/v3.1.1
[3.1.0]: https://github.com/StrangeRanger/NadekoBot-BashScript/releases/tag/v3.1.0
[3.0.4]: https://github.com/StrangeRanger/NadekoBot-BashScript/releases/tag/v3.0.4
[3.0.3]: https://github.com/StrangeRanger/NadekoBot-BashScript/releases/tag/v3.0.3
[3.0.0]: https://github.com/StrangeRanger/NadekoBot-BashScript/releases/tag/v3.0.0
[2.1.1]: https://github.com/StrangeRanger/NadekoBot-BashScript/releases/tag/v2.1.1
[2.1.0]: https://github.com/StrangeRanger/NadekoBot-BashScript/releases/tag/v2.1.0
