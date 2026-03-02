#!/usr/bin/env bash
set -euo pipefail

# Install evremap: download pre-built binary from brentdurksen/evremap releases,
# install config and systemd service from this repo (brentdurksen/my-evremap).
# Must be run as root (or via sudo).
#
# Usage:
#   sudo bash install.sh            # download binary from latest GitHub release
#   sudo bash install.sh --build    # build from source instead

BINARY_REPO="brentdurksen/evremap"
CONFIG_REPO="brentdurksen/my-evremap"
BINARY_DEST="/usr/bin/evremap"
CONFIG_DEST="/etc/evremap.toml"
SERVICE_DEST="/etc/systemd/system/evremap.service"

# ---------------------------------------------------------------------------

if [[ $EUID -ne 0 ]]; then
    echo "Please run as root: sudo bash install.sh" >&2
    exit 1
fi

BUILD=0
for arg in "$@"; do
    case "$arg" in
        --build) BUILD=1 ;;
        *) echo "Unknown argument: $arg" >&2; exit 1 ;;
    esac
done

# Detect architecture
ARCH="$(uname -m)"
case "$ARCH" in
    x86_64)  ASSET="evremap-x86_64" ;;
    aarch64) ASSET="evremap-aarch64" ;;
    *)
        if [[ $BUILD -eq 0 ]]; then
            echo "Unsupported architecture: $ARCH. Use --build to compile from source." >&2
            exit 1
        fi
        ;;
esac

# ---------------------------------------------------------------------------
# Determine the directory this script lives in (works for both local and
# curl-to-bash invocations where BASH_SOURCE may be empty)
if [[ -n "${BASH_SOURCE[0]:-}" && "${BASH_SOURCE[0]}" != "bash" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
else
    SCRIPT_DIR=""
fi

# ---------------------------------------------------------------------------

install_binary_from_release() {
    echo "==> Fetching latest release info from GitHub..."
    local api_url="https://api.github.com/repos/${BINARY_REPO}/releases/latest"
    local release_json
    release_json="$(curl -sSfL "$api_url")"

    local tag
    tag="$(echo "$release_json" | grep '"tag_name"' | head -1 | sed 's/.*"tag_name": *"\([^"]*\)".*/\1/')"
    echo "    Latest release: $tag"

    local download_url="https://github.com/${BINARY_REPO}/releases/download/${tag}/${ASSET}"
    echo "==> Downloading $ASSET..."

    local temp_bin
    temp_bin="$(mktemp)"
    curl -sSfL "$download_url" -o "$temp_bin"
    install -Dm755 "$temp_bin" "$BINARY_DEST"
    rm -f "$temp_bin"

    echo "    Installed to $BINARY_DEST"
}

install_binary_from_source() {
    echo "==> Building from source..."
    local src_dir=""

    # If we're running from a local my-evremap checkout, look for evremap alongside it
    if [[ -n "$SCRIPT_DIR" ]]; then
        local candidate
        candidate="$(dirname "$SCRIPT_DIR")/evremap"
        if [[ -f "$candidate/Cargo.toml" ]]; then
            src_dir="$candidate"
        fi
    fi

    if [[ -z "$src_dir" ]]; then
        echo "Cannot find evremap source. Clone brentdurksen/evremap alongside this repo:" >&2
        echo "  git clone https://github.com/${BINARY_REPO}.git" >&2
        exit 1
    fi

    if [[ -n "${SUDO_USER:-}" ]]; then
        sudo -u "$SUDO_USER" cargo build --release --manifest-path "$src_dir/Cargo.toml"
    else
        cargo build --release --manifest-path "$src_dir/Cargo.toml"
    fi
    install -Dm755 "$src_dir/target/release/evremap" "$BINARY_DEST"
    echo "    Installed to $BINARY_DEST"
}

install_config() {
    echo "==> Installing config to $CONFIG_DEST..."

    # Try local copy first, then download from GitHub main branch
    if [[ -n "$SCRIPT_DIR" && -f "$SCRIPT_DIR/evremap.toml" ]]; then
        install -Dm644 "$SCRIPT_DIR/evremap.toml" "$CONFIG_DEST"
    else
        curl -sSfL "https://raw.githubusercontent.com/${CONFIG_REPO}/main/evremap.toml" \
            -o "$CONFIG_DEST"
        chmod 644 "$CONFIG_DEST"
    fi
    echo "    Installed to $CONFIG_DEST"
}

install_service() {
    echo "==> Installing systemd service to $SERVICE_DEST..."

    if [[ -n "$SCRIPT_DIR" && -f "$SCRIPT_DIR/evremap.service" ]]; then
        install -Dm644 "$SCRIPT_DIR/evremap.service" "$SERVICE_DEST"
    else
        curl -sSfL "https://raw.githubusercontent.com/${CONFIG_REPO}/main/evremap.service" \
            -o "$SERVICE_DEST"
        chmod 644 "$SERVICE_DEST"
    fi
    echo "    Installed to $SERVICE_DEST"
}

# ---------------------------------------------------------------------------

if [[ $BUILD -eq 1 ]]; then
    install_binary_from_source
else
    install_binary_from_release
fi

install_config
install_service

echo "==> Enabling and starting evremap service..."
systemctl daemon-reload
systemctl enable --now evremap.service

echo ""
echo "Done."
echo "  Status : systemctl status evremap"
echo "  Logs   : journalctl -u evremap -f"
echo "  Config : $CONFIG_DEST"
