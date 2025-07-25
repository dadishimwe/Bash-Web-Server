#!/usr/bin/env bash

# Common functions for the bash-web-server

fatal() {
	echo "[fatal] $@" >&2
	log_error "$@"
	exit 1
}

log_access() {
    if [[ "$ENABLE_LOGGING" == "true" ]]; then
        echo "$(date "+%Y-%m-%d %H:%M:%S") [access] $1" >> "$ACCESS_LOG"
    fi
}

log_error() {
    if [[ "$ENABLE_LOGGING" == "true" ]]; then
        echo "$(date "+%Y-%m-%d %H:%M:%S") [error] $1" >&2 >> "$ERROR_LOG"
    fi
}

mime-type() {
	local f=$1
	local bname=${f##*/}
	local ext=${bname##*.}
	[[ $bname == "$ext" ]] && ext=

	case "$ext" in
		html|htm) echo "text/html";;
		jpeg|jpg) echo "image/jpeg";;
		png) echo "image/png";;
		svg) echo "image/svg+xml";;
		webp) echo "image/webp";;
		pdf) echo "application/pdf";;
		txt) echo "text/plain";;
		css) echo "text/css";;
		js) echo "text/javascript";;
		json) echo "application/json";;
		*) echo "application/octet-stream";;
	esac
}

html-encode() {
	local s=$1

	s=${s//&/\&amp;}
	s=${s//</\&lt;}
	s=${s//>/\&gt;}
	s=${s//\"/\&quot;}
	s=${s//\'/\&apos;}

	echo "$s"
}

list-directory() {
	local d=$1

	shopt -s nullglob dotglob

	echo "<!DOCTYPE html>"
	echo "<html lang=\"en\">"
	echo "<head>"
	echo "  <meta charset=\"utf-8\">"
	printf "  <title>Index of %s</title>\n" "$(html-encode "$d")"
	echo "</head>"
	echo "<body>"
	echo "<h1>Directory Listing</h1>"
	echo "<h2>Directory: $(html-encode "$d")</h2>"
	echo "<hr>"
	echo "<ul>"
	local f
	for f in .. "$d"/*; do
		local bname=${f##*/}
		local display_name
		if [[ -d $f ]]; then
			display_name="📁 $bname/"
		else
			display_name="📄 $bname"
		fi
		printf "<li><a href=\"%s\">%s</a></li>\n" \
			"$(urlencode "$bname")" \
			"$(html-encode "$display_name")"
	done
	echo "</ul>"
	echo "<hr>"
	echo "</body>"
	echo "</html>"
}

urlencode() {
	# Usage: urlencode "string"
	local LC_ALL=C
	for (( i = 0; i < ${#1}; i++ )); do
		: "${1:i:1}"
		case "$_" in
			[a-zA-Z0-9.~_-])
				printf "%s" "$_"
				;;

			*)
				printf "%%%02X" "'$_"
				;;
		esac
	done
	printf "\n"
}

urldecode() {
	# Usage: urldecode "string"
	: "${1//+/ }"
	printf "%b\n" "${_//%/\\x}"
}

normalize-path() {
	local path=/$1

	local parts
	IFS='/' read -r -a parts <<< "$path"

	local -a out=()
	local part
	for part in "${parts[@]}"; do
		case "$part" in
			'') ;; # ignore empty directories (multiple /)
			'.') ;; # ignore current directory
			'..') unset 'out[-1]' 2>/dev/null;;
			*) out+=("$part");;
		esac
	done

	local s
	s=$(IFS=/; echo "${out[*]}")
	echo "/$s"
}

parse-request() {
	declare -gA REQ_INFO=()
	declare -gA REQ_HEADERS=()

	local state='status'
	local line
	while read -r line; do
		line=${line%$'\r'}

		case "$state" in
			'status')
				# parse the status line
				# "GET /foo.txt HTTP/1.1"
				local method path version
				read -r method path version <<< "$line"
				REQ_INFO[method]=$method
				REQ_INFO[path]=$path
				REQ_INFO[version]=$version
				state='headers'
				;;
			'headers')
				# parse the headers
				if [[ -z $line ]]; then
					# XXX this doesn't support body parsing
					break
				fi
				local key value
				IFS=':' read -r key value <<< "$line"
				key=${key,,}
				value=${value# *}
				REQ_HEADERS[$key]=$value
				;;
			'body')
				fatal 'body parsing not supported'
				;;
		esac
	done
}

serve_error_page() {
    local status_code=$1
    local status_text=$2
    local error_page="${ERROR_PAGES_DIR}/${status_code}.html"

    log_error "Serving error page: ${status_code} ${status_text} for ${REQ_INFO[path]}"

    if [[ "$ENABLE_CUSTOM_ERROR_PAGES" == "true" && -f "$error_page" ]]; then
        local mime=$(mime-type "$error_page")
        printf "HTTP/1.1 %s %s\r\n" "$status_code" "$status_text"
        printf "Content-Type: %s\r\n" "$mime"
        printf "\r\n"
        cat "$error_page"
    else
        printf "HTTP/1.1 %s %s\r\n" "$status_code" "$status_text"
        printf "Content-Type: text/plain\r\n"
        printf "\r\n"
        printf "%s %s\n" "$status_code" "$status_text"
    fi
}

check_auth() {
    if [[ "$ENABLE_AUTH" == "true" ]]; then
        local auth_header="${REQ_HEADERS[authorization]}"
        if [[ -z "$auth_header" ]]; then
            printf "HTTP/1.1 401 Unauthorized\r\n"
            printf "WWW-Authenticate: Basic realm=\"Restricted Area\"\r\n"
            printf "\r\n"
            log_access "- ${REQ_INFO[method]} ${REQ_INFO[path]} ${REQ_INFO[version]} 401"
            return 1
        fi

        local credentials_base64=$(echo "$auth_header" | sed -n 's/Basic \(.*\)/\1/p')
        local credentials=$(echo "$credentials_base64" | base64 --decode 2>/dev/null)
        local username=$(echo "$credentials" | cut -d: -f1)
        local password=$(echo "$credentials" | cut -d: -f2)

        if ! "${SCRIPTS_DIR}/auth.sh" check_credentials "$username" "$password"; then
            printf "HTTP/1.1 401 Unauthorized\r\n"
            printf "WWW-Authenticate: Basic realm=\"Restricted Area\"\r\n"
            printf "\r\n"
            log_access "- ${REQ_INFO[method]} ${REQ_INFO[path]} ${REQ_INFO[version]} 401"
            return 1
        fi
    fi
    return 0
}

process-request() {
	parse-request

	# Validate the request
	if [[ ${REQ_INFO[version]} != 'HTTP/1.1' ]]; then
	    log_access "- ${REQ_INFO[method]} ${REQ_INFO[path]} ${REQ_INFO[version]} 505"
	    serve_error_page "505" "HTTP Version Not Supported"
	    return
	fi

	local method="${REQ_INFO[method]}"
	if [[ "$method" != 'GET' && "$method" != 'HEAD' ]]; then
	    log_access "- ${REQ_INFO[method]} ${REQ_INFO[path]} ${REQ_INFO[version]} 405"
	    serve_error_page "405" "Method Not Allowed"
	    return
	fi

	if [[ ${REQ_INFO[path]} != /* ]]; then
	    log_access "- ${REQ_INFO[method]} ${REQ_INFO[path]} ${REQ_INFO[version]} 400"
	    serve_error_page "400" "Bad Request"
	    return
	fi

    # Check authentication for protected paths (e.g., /admin)
    if [[ "$ENABLE_AUTH" == "true" && "${REQ_INFO[path]}" == "/admin"* ]]; then
        if ! check_auth; then
            return # check_auth already sent response
        fi
    fi

	log_access "- ${REQ_INFO[method]} ${REQ_INFO[path]} ${REQ_INFO[version]}"

	# if we are here, we should reply to the caller
	local path="${REQ_INFO[path]}"

	# "././foo%20bar.txt?query=whatever"
	path=${path:1}

	# "././foo%20bar.txt"
	local query
	IFS='?' read -r path query <<< "$path"

	# "././foo bar.txt"
	path=$(urldecode "$path")

	# "/foo bar.txt"
	path=$(normalize-path "$path")

	# "foo bar.txt"
	path=${path:1}

	# handle empty path (root path)
	path=${path:-.}

	# try to serve an index page
	local totry=(
		"$path"
	)
	for index_file in "${DEFAULT_INDEX_FILES[@]}"; do
	    totry+=("$path/$index_file")
	done

	local try file
	for try in "${totry[@]}"; do
		if [[ -f "${DOCUMENT_ROOT}/$try" ]]; then
			file="${DOCUMENT_ROOT}/$try"
			break
		fi
	done

	if [[ -n $file ]]; then
		# a static file was found!
		local mime
		mime=$(mime-type "$file")

		printf "HTTP/1.1 200 OK\r\n"
		printf "Content-Type: %s\r\n" "$mime"

		if [[ "$ENABLE_CACHING" == "true" ]]; then
		    printf "Cache-Control: max-age=%s, public\r\n" "$DEFAULT_CACHE_MAX_AGE"
		fi

		if [[ "$ENABLE_GZIP" == "true" && "${REQ_HEADERS[accept-encoding]}" == *gzip* ]]; then
		    printf "Content-Encoding: gzip\r\n"
		    printf "\r\n"
		    gzip < "$file"
		elif [[ "$method" == 'GET' ]]; then
		    printf "\r\n"
		    cat "$file"
		else # HEAD request
		    printf "\r\n"
		fi

	elif [[ -d "${DOCUMENT_ROOT}/$path" ]]; then
		# redirect to /path/ if directory requested without trailing slash
		if [[ ${REQ_INFO[path]} != */ ]]; then
			printf "HTTP/1.1 301 Moved Permanently\r\n"
			printf "Location: %s/\r\n" "${REQ_INFO[path]}"
			printf "\r\n"
			log_access "- ${REQ_INFO[method]} ${REQ_INFO[path]} ${REQ_INFO[version]} 301"
			return
		fi

		# try a directory listing
		printf "HTTP/1.1 200 OK\r\n"
		printf "Content-Type: text/html; charset=utf-8\r\n"
		printf "\r\n"
		list-directory "${DOCUMENT_ROOT}/$path"
		log_access "- ${REQ_INFO[method]} ${REQ_INFO[path]} ${REQ_INFO[version]} 200"
	else
		# nothing was found
		log_access "- ${REQ_INFO[method]} ${REQ_INFO[path]} ${REQ_INFO[version]} 404"
		serve_error_page "404" "Not Found"
	fi
}

