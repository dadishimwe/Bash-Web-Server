#!/usr/bin/env bash

# This script handles individual HTTP requests.
# It is executed by socat for each incoming connection.

# Load configuration
CONFIG_FILE="/home/pi/Bash-Web-Server/config/server.conf"
if [[ -f "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE"
else
    echo "[fatal] Configuration file not found: $CONFIG_FILE" >&2
    exit 1
fi

# Default values if not set in config
PORT=${PORT:-8080}
ADDRESS=${ADDRESS:-"0.0.0.0"}
DOCUMENT_ROOT=${DOCUMENT_ROOT:-"/home/pi/Bash-Web-Server/www"}
ENABLE_LOGGING=${ENABLE_LOGGING:-false}
ACCESS_LOG=${ACCESS_LOG:-"/dev/null"}
ERROR_LOG=${ERROR_LOG:-"/dev/null"}
ENABLE_CUSTOM_ERROR_PAGES=${ENABLE_CUSTOM_ERROR_PAGES:-false}
ERROR_PAGES_DIR=${ERROR_PAGES_DIR:-"/home/pi/Bash-Web-Server/error-pages"}
ENABLE_AUTH=${ENABLE_AUTH:-false}
AUTH_FILE=${AUTH_FILE:-"."}
ENABLE_CACHING=${ENABLE_CACHING:-false}
DEFAULT_CACHE_MAX_AGE=${DEFAULT_CACHE_MAX_AGE:-3600}
ENABLE_GZIP=${ENABLE_GZIP:-false}
DEFAULT_INDEX_FILES=( ${DEFAULT_INDEX_FILES[@]:-"index.html" "index.htm"} )

SCRIPTS_DIR="/home/pi/Bash-Web-Server/scripts"

# Load necessary functions from the main server script
source /home/pi/Bash-Web-Server/scripts/server_functions.sh

# Process the request
process-request

