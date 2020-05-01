# Dotfiles

Lots of stuff grabbed from [mathiasbynens/dotfiles](https://github.com/mathiasbynens/dotfiles).

Assumes a bash shell unless otherwise noted.

## Mac

1. Install [Homebrew](https://brew.sh/).
2. Install Git via Homebrew and clone this repo.
3. Run `./init.sh` for core configuration.
4. Run [`brew bundle`](https://github.com/Homebrew/homebrew-bundle) to install packages specified in Brewfile.

## Windows

Run these steps in an elevated PowerShell prompt.

1. Install [Scoop](https://scoop.sh/).
2. Install Git via Scoop and clone this repo.
3. Run `./init.ps1` for core configuration.
4. Run `./Scoopfile.ps1` to install packages specified there.

## Mac and Windows

* Run `./Nodefile` to install global [Node](https://nodejs.org/) packages.

## Manual configuration

Some things should be set manually.

### SSH

Add an include to `~/.ssh/config`.

    Include /dotfiles-path/ssh_config
