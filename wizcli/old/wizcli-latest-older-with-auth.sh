#!/bin/bash

# rowan smith - 14/2/2025
# This script checks if the installed WizCLI version is up-to-date, and if not, downloads and installs the latest version.
# It will query the Wiz API to get the latest version and compare it with the installed version.
# It uses the token from your existing WizCLI install, and if expired, triggers a new authentication flow.
# Written for MacOS Apple Silicon (arm64) architecture.

## 11/3/2025
## - not using this version anymore as the auth to wiz requirement is not actually required.

# Local installation path
INSTALL_PATH=$(which wizcli)

# Wiz DC
WIZ_DC="us20"

# Get the expiration timestamp from the auth.json file
EXPIRES_AT=$(jq -r '.expires_at' < ~/.wiz/auth.json)

# Convert expiration time to seconds since epoch
EXPIRES_AT_EPOCH=$(date -j -u -f "%Y-%m-%dT%H:%M:%SZ" "$EXPIRES_AT" +%s)

# Get the current time in seconds since epoch
CURRENT_EPOCH=$(date -u +%s)

# Check if the expiration time is in the past
if [[ "$CURRENT_EPOCH" -ge "$EXPIRES_AT_EPOCH" ]]; then
    echo "Token expired. Running 'wizcli auth'..."
    if ! wizcli auth --use-device-code; then
        echo "Failed to authenticate. Exiting."
        exit 1
    fi
else
    echo "Token is still valid. Proceeding."
fi

# Function to get latest remote version
get_latest_version() {
    JSON_PAYLOAD=$(jq -n --arg version "$LOCAL_VERSION" '{
      query: "query cliReleases($filterBy: CLIReleaseFilters, $first: Int) { cliReleases(first: $first, filterBy: $filterBy) { edges { node { platform architecture version url sha256 } cursor } nodes { platform architecture version url sha256 } pageInfo { endCursor hasNextPage } totalCount } }",
      variables: {
        filterBy: {
          platform: ["DARWIN"],
          architecture: ["ARM64"]
        }
      }
    }')

    LATEST_VERSION=$(curl -sk -X POST -H "Authorization: Bearer $(jq -r '.access_token' < ~/.wiz/auth.json)" -H "Content-Type: application/json" -d "$JSON_PAYLOAD" https://api.${WIZ_DC}.app.wiz.io/graphql | jq -r '.data.cliReleases.nodes[0].version')
    }

# Function to install the latest version
install_latest_version() {
    # Fallback value for INSTALL_PATH if not set
    INSTALL_PATH="${INSTALL_PATH:-/usr/local/bin/wizcli}"

    echo "Downloading version: $LATEST_VERSION"
    echo "You will (likely) be prompted for your password"
    if ! curl -sk https://wizcli.app.wiz.io/latest/wizcli-darwin-arm64 -o wizcli; then
        echo "Failed to download the latest version. Exiting."
        exit 1
    fi
    chmod +x wizcli
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
    rm wizcli-ver.txt
}

# If install path is null, may as well skip the version check and go straight to install
if [ -z "$INSTALL_PATH" ]; then
    install_latest_version
else 
    get_installed_version
    get_latest_version

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
fi