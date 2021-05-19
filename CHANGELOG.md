# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Summary

The most notable change in this version is the refactoring of the code used to download NadekoBot. I've provided information and what and how exactly it was refactored down below in the changed portion of this changelog. The change was done in the hopes that it will allow for the installer to be just a bit easier to maintain and modify, and organized.

### Changed

- Option four will inform the end-user whether or not NadekoBot's service is running. While the option will be greyed out if the service is not running, it will not be disabled.
- Major refactoring
  - All of the code used to download NadekoBot, has been moved into two separate files. One specifically for Linux and the other for macOS.
  - This has resulted in the fact that the downloader code must be downloaded itself.
- The installer will no longer create Nadeko's service immediatley. Instead, the service will only be created when one of the run options have been chosen.

### Fixed

- Fixed typos in the menu output.

## [3.0.0] - 2021-05-15

### Breaking Changes

Due to some breaking changes inside of `linuxAIO.sh`, all users who are currently using `linuxAIO.sh` revision 8 and earlier will receive a message the next time they execute the script. The notice will inform users that they will need to download the newest version of `linuxAIO.sh` manually. The appropriate command to do this will be provided by the installer, based on the current configurations of `linuxAIO.sh`.

Additionally, you'll need to delete `/lib/systemd/system/nadeko.service`, as the service will now be stored in `/etc/systemd/system/nadeko.service`. To do this, run the following command: `sudo systemctl stop nadeko.service && sudo rm /lib/systemd/system/nadeko.service && sudo systemctl daemon-reload`. From here, execute `linuxAIO.sh` as you always do.

### Added

- End-user can now configure what branch/tag to download NadekoBot from (i.e. `1.9`, `2.39.1`, etc.).
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

Version 2 of the Nadeko Bash Scripts is a complete rewrite of the previous Bash Scripts. Below is a list of the most significant changes to the installer.

### Added

- Added support for:
  - Ubuntu 20.04
  - Mint Linux: 19, 20
  - Debian 10
- Indicates what run-mode NadekoBot is currently set up to or is running in
- Added an option to watch NadekoBot's logs live (as they are created)
- Better error catching
- End-user has more control over the installer
  - `linuxAIO.sh` consists of a few configurable settings the end-user can modify
- Installs both homebrew and prerequisite on macOS (previously required manual installation)
- After starting NadekoBot, a startup log is displayed to allow the end-user to identify possible errors better

### Changed

- Installer disables specific options until a prerequisite is met
- Uses systemctl (Linux) and launchctl (macOS) to run NadekoBot, instead of PM2
- Relies on curl more than wget

### Removed

- Removed support for:
  - Ubuntu: 14.04, 16.10, 17.04, 17.10
  - Linux Mint: 17
  - Debian: 8
  - CentOS: 7
- Removed option to run NadekoBot with auto-update

[unreleased]: https://github.com/StrangeRanger/NadekoBot-BashScript/compare/v3.0.0...HEAD
[3.0.0]: https://github.com/StrangeRanger/NadekoBot-BashScript/releases/tag/v3.0.0
[2.1.1]: https://github.com/StrangeRanger/NadekoBot-BashScript/releases/tag/v2.1.1
[2.1.0]: https://github.com/StrangeRanger/NadekoBot-BashScript/releases/tag/v2.1.0
