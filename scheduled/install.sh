#!/usr/bin/env bash
# Install scheduled tasks
#
# A job can run as an agent or a daemon. An agent runs on behalf of the
# logged-in user so the script is restricted to that user. A daemon runs
# under the root user and so will run no matter who is logged in.
#
# The difference between agents and daemons is drawn from where they’re saved:
# `~/Library/LaunchAgents` for agents.
# `/Library/LaunchDaemons` for daemons.

DOTFILES_DIR="$(dirname "$(greadlink -f "${BASH_SOURCE[0]}")")"

cp "$DOTFILES_DIR"/scheduled/local.dotfiles.daily.plist ~/Library/LaunchAgents/local.dotfiles.daily.plist

launchctl load ~/Library/LaunchAgents/local.dotfiles.daily.plist
