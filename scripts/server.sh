#!/usr/bin/env bash
#
# Enhanced Bash HTTP Server
#
# Author: Dadi Ishimwe
# Date: July 24, 2025
# License: MIT

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

fatal() {
	echo "[fatal] $@" >&2
	exit 1
}

main() {
	local OPTIND OPTARG opt
	while getopts 'b:p:d:' opt; do
		case "$opt" in
			b) ADDRESS=$OPTARG;;
			p) PORT=$OPTARG;;
			d) DOCUMENT_ROOT=$OPTARG;;
			*) fatal "bad option";;
		esac
	done

	cd "$DOCUMENT_ROOT" || fatal "failed to move to $DOCUMENT_ROOT"

	echo "listening on http://$ADDRESS:$PORT"
	echo "serving out of $DOCUMENT_ROOT"

	# Use socat to listen on the port and execute the request handler for each connection
	socat TCP-LISTEN:$PORT,fork,reuseaddr EXEC:"$SCRIPTS_DIR/process_request_handler.sh"
}

main "$@"

