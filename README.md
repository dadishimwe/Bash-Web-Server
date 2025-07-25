# Enhanced Bash Web Server

This project is an enhanced version of the original `bash-web-server` by bahamas10, augmented with additional features and improved functionality for serving static websites.

## Features

*   **Static File Serving**: Serves HTML, CSS, JavaScript, images, and other static assets.
*   **Custom Error Pages**: Configurable 404 (Not Found) and 500 (Internal Server Error) pages.
*   **Access Logging**: Logs all incoming requests to a specified access log file.
*   **Error Logging**: Logs server-side errors to a dedicated error log file.
*   **Basic Authentication**: Supports HTTP Basic Authentication for protecting specific paths.
*   **Caching Headers**: Adds `Cache-Control` headers for better client-side caching.
*   **Gzip Compression**: Supports Gzip compression for served files if the client requests it.
*   **Directory Listing**: Provides a basic directory listing for folders without an index file.
*   **Index File Support**: Automatically serves `index.html` or `index.htm` within directories.

## Project Structure

```
enhanced-bash-web-server/
├── config/
│   ├── server.conf         # Main server configuration
│   └── users.conf          # User credentials for basic authentication
├── error-pages/
│   ├── 404.html            # Custom 404 Not Found page
│   └── 500.html            # Custom 500 Internal Server Error page
├── logs/
│   ├── access.log          # Access log file
│   └── error.log           # Error log file
├── scripts/
│   ├── auth.sh             # Authentication helper script
│   ├── process_request_handler.sh # Handles individual HTTP requests
│   ├── server.sh           # Main server startup script
│   └── server_functions.sh # Common functions used by the server
├── www/
│   ├── index.html          # Sample portfolio homepage
│   ├── styles.css          # Sample CSS for the portfolio
│   ├── script.js           # Sample JavaScript for the portfolio
│   └── project1.jpg        # Sample image for portfolio project
└── README.md             # This documentation file
```

## Setup and Installation

### Prerequisites

*   **Bash**: The server is written in Bash and requires a Bash-compatible shell.
*   **Socat**: Used for handling network connections. Install it using your system's package manager:
    ```bash
    sudo apt-get update
    sudo apt-get install -y socat
    ```
*   **Core Utilities**: Standard Unix utilities like `cat`, `echo`, `printf`, `read`, `cut`, `sed`, `awk`, `base64`, `gzip`, `date`, `chmod`, `mkdir`, `cp`, `cd`, `ls`, `find`, `shopt`.

### Getting Started

1.  **Clone the repository (or copy the files)**:

    If you are starting from scratch, you can clone the original repository and then apply the enhancements manually, or simply use the provided enhanced project structure.

    ```bash
    git clone https://github.com/your-repo/enhanced-bash-web-server.git # Replace with your repository URL
    cd enhanced-bash-web-server
    ```

    If you have received the project as a packaged archive, extract it and navigate into the directory:

    ```bash
    tar -xzf enhanced-bash-web-server.tar.gz
    cd enhanced-bash-web-server
    ```

2.  **Configure the Server**:

    Edit `config/server.conf` to customize server settings. Key variables include:

    *   `PORT`: The port the server will listen on (default: `8080`).
    *   `ADDRESS`: The IP address the server will bind to (default: `0.0.0.0`).
    *   `DOCUMENT_ROOT`: The directory from which files will be served (default: `www`).
    *   `ENABLE_LOGGING`: Set to `true` to enable access and error logging (default: `false`).
    *   `ACCESS_LOG`: Path to the access log file (default: `/dev/null`).
    *   `ERROR_LOG`: Path to the error log file (default: `/dev/null`).
    *   `ENABLE_CUSTOM_ERROR_PAGES`: Set to `true` to use custom 404/500 pages (default: `false`).
    *   `ERROR_PAGES_DIR`: Directory containing custom error pages (default: `error-pages`).
    *   `ENABLE_AUTH`: Set to `true` to enable basic authentication (default: `false`).
    *   `AUTH_FILE`: Path to the user credentials file for authentication (default: `config/users.conf`).
    *   `ENABLE_CACHING`: Set to `true` to enable caching headers (default: `false`).
    *   `DEFAULT_CACHE_MAX_AGE`: Max-age for caching in seconds (default: `3600`).
    *   `ENABLE_GZIP`: Set to `true` to enable gzip compression (default: `false`).
    *   `DEFAULT_INDEX_FILES`: Space-separated list of default index filenames (default: `"index.html" "index.htm"`).

    Example `config/server.conf`:

    ```bash
    PORT=80
    ADDRESS="127.0.0.1"
    DOCUMENT_ROOT="/home/ubuntu/enhanced-bash-web-server/www"
    ENABLE_LOGGING=true
    ACCESS_LOG="/home/ubuntu/enhanced-bash-web-server/logs/access.log"
    ERROR_LOG="/home/ubuntu/enhanced-bash-web-server/logs/error.log"
    ENABLE_CUSTOM_ERROR_PAGES=true
    ERROR_PAGES_DIR="/home/ubuntu/enhanced-bash-web-server/error-pages"
    ENABLE_AUTH=true
    AUTH_FILE="/home/ubuntu/enhanced-bash-web-server/config/users.conf"
    ENABLE_CACHING=true
    DEFAULT_CACHE_MAX_AGE=86400
    ENABLE_GZIP=true
    DEFAULT_INDEX_FILES=("index.html" "default.html")
    ```

3.  **Set up Authentication (Optional)**:

    If `ENABLE_AUTH` is set to `true`, edit `config/users.conf` to add authorized users. Each line should contain a username and password separated by a colon.

    Example `config/users.conf`:

    ```
    admin:password123
    user:securepass
    ```

4.  **Prepare your Website Content**:

    Place your static website files (HTML, CSS, JS, images, etc.) into the `www/` directory (or the directory specified by `DOCUMENT_ROOT` in `server.conf`).

5.  **Start the Server**:

    Navigate to the project root directory and run the `server.sh` script:

    ```bash
    ./scripts/server.sh
    ```

    The server will start listening on the configured address and port. You can then access your website through a web browser.

## Usage for Portfolio Website

This enhanced bash web server is ideal for hosting a simple, static portfolio website. Here's how to leverage its features:

*   **Organize your projects**: Create subdirectories within `www/` for each project (e.g., `www/project-x/`, `www/project-y/`).
*   **Custom 404 page**: Design an engaging `error-pages/404.html` to guide users back to your main site if they land on a broken link.
*   **Logging**: Monitor `logs/access.log` to see traffic to your portfolio and `logs/error.log` for any server-side issues.
*   **Authentication for private content**: If you have a section of your portfolio that you only want to share with specific individuals (e.g., client-specific work), you can place it under a protected path (e.g., `www/admin/`) and enable basic authentication.

## Troubleshooting

*   **"Address already in use"**: This means another process is already using the specified `PORT`. You can either change the `PORT` in `config/server.conf` or kill the process currently using the port:
    ```bash
    sudo fuser -k <PORT>/tcp
    ```
    (Replace `<PORT>` with your server's port, e.g., `8080`)
*   **"Permission denied"**: Ensure that the `server.sh`, `auth.sh`, and `process_request_handler.sh` scripts have execute permissions:
    ```bash
    chmod +x scripts/*.sh
    ```
*   **Server not starting**: Check `logs/error.log` for detailed error messages if logging is enabled. Otherwise, review the console output for any fatal errors.
*   **Pages not loading**: Verify that `DOCUMENT_ROOT` in `config/server.conf` is correctly set to the directory containing your website files.

## Contributing

Feel free to fork this repository, add more features, or improve existing ones. Pull requests are welcome!

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

