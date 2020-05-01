#!/usr/bin/env bash
# Backup a list of apps in /Applications to a Dropbox-synced text file

apps=$(cd /Applications && ls -d1 */ | cut -f1 -d'/')

echo "$apps" > ~/Dropbox/Backup/apps.txt
