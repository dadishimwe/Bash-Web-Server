#!/usr/bin/env bash

# Simple authentication script
# This is a very basic implementation and should not be used for production systems without significant enhancements.

AUTH_FILE="/home/ubuntu/Bash-Web-Server/config/users.conf"

# Function to check credentials
check_credentials() {
    local username=$1
    local password=$2

    if [[ ! -f "$AUTH_FILE" ]]; then
        echo "[auth] Auth file not found: $AUTH_FILE" >&2
        return 1
    fi

    while IFS=":" read -r stored_user stored_pass;
    do
        if [[ "$username" == "$stored_user" && "$password" == "$stored_pass" ]]; then
            return 0 # Success
        fi
    done < "$AUTH_FILE"

    return 1 # Failure
}

# Example Usage (for testing)
# if check_credentials "testuser" "testpass"; then
#     echo "Authentication successful!"
# else
#     echo "Authentication failed."
# fi


