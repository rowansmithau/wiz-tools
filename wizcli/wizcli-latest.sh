#!/bin/bash

# rowan smith - 11/3/2025
# This script checks if the installed WizCLI version is up-to-date, and if not, downloads and installs the latest version.
# It will check the version installed and compare it with the latest version available based on the output of the WizCLI version command.
# Written for MacOS Apple Silicon (arm64) architecture.

# Local installation path
INSTALL_PATH=$(which wizcli)

install_latest_version() {
    # Fallback to using /usr/local/bin/wizcli if not already installed
    INSTALL_PATH="${INSTALL_PATH:-/usr/local/bin/wizcli}"

    echo "You will (likely) be prompted for your password due to sudo."
    if ! curl -sk https://wizcli.app.wiz.io/latest/wizcli-darwin-arm64 -o wizcli; then
        echo "Failed to download the latest version. Exiting."
        exit 1
    fi
    chmod +x wizcli
    if [ -f wizcli-ver.txt ]; then
      rm wizcli-ver.txt
    fi
    if ! sudo mv wizcli "$INSTALL_PATH"; then
        echo "Failed to move the wizcli binary to $INSTALL_PATH. Exiting."
        exit 1
    fi
    echo "WizCLI installed successfully at $INSTALL_PATH."
}

# Get local WizCLI version.
# This is output to a file because the output of WizCLI ignores filtering commands such as 'head'.
get_installed_version() {
    if ! wizcli version -T &> wizcli-ver.txt; then
        echo "Failed to get the installed version. Exiting."
        exit 1
    fi
    LOCAL_VERSION=$(awk 'NR==1 {gsub(",", "", $3); sub(/^v/, "", $3); print $3}' wizcli-ver.txt)
    LATEST_VERSION=$(grep 'A new version' wizcli-ver.txt | awk -F '[()]' '{print substr($2, 2)}')
    if grep -q "A new version of Wiz CLI is available" wizcli-ver.txt; then
        echo "A new version of Wiz CLI is available. Proceeding to install the latest version."
        install_latest_version
        exit 0
    fi
}

# If install path is null, may as well skip the version check and go straight to install
if [ -z "$INSTALL_PATH" ]; then
    echo "Did not find existing installation. Proceeding to install the latest version."
    install_latest_version
else 
    get_installed_version

    # Strip out the commit hash part for comparison
    LOCAL_VERSION_BASE=$(echo "$LOCAL_VERSION" | sed 's/-.*//')
    LATEST_VERSION_BASE=$(echo "$LATEST_VERSION" | sed 's/-.*//')

    if [ -n "$LOCAL_VERSION" ] && [ -n "$LATEST_VERSION" ]; then
        echo "Local version: $LOCAL_VERSION_BASE"
        echo "Latest version: $LATEST_VERSION_BASE"
    fi

    # Do the compare
    IFS='.' read -r LOCAL_MAJOR LOCAL_MINOR LOCAL_PATCH <<< "$LOCAL_VERSION_BASE"
    IFS='.' read -r LATEST_MAJOR LATEST_MINOR LATEST_PATCH <<< "$LATEST_VERSION_BASE"

    if (( LOCAL_MAJOR < LATEST_MAJOR )) || (( LOCAL_MAJOR == LATEST_MAJOR && LOCAL_MINOR < LATEST_MINOR )) || (( LOCAL_MAJOR == LATEST_MAJOR && LOCAL_MINOR == LATEST_MINOR && LOCAL_PATCH < LATEST_PATCH )); then
        echo "A newer version is available. Proceeding to install the latest version."
        install_latest_version
    else
        echo "You're on the latest version already, exiting."
    fi
    if [ -f wizcli-ver.txt ]; then
      rm wizcli-ver.txt
    fi
fi