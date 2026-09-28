#!/usr/bin/env bash
# Install Neovim and the tools this repo's config needs on Raspberry Pi OS.
#
# Usage:
#   sudo ./setup-linux.sh [--version TAG] [--user USER] [--no-config]
#
# 64-bit Pi OS uses the official arm64 release; 32-bit Pi OS builds from source.
# --no-config skips linking this repo's nvim config into ~/.config/nvim.

set -Eeuo pipefail

NVIM_VERSION="v0.12.5"
TARGET_USER="${SUDO_USER:-${USER}}"
LINK_CONFIG=yes
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
    sed -n '2,8p' "$0"
}

while (($#)); do
    case "$1" in
        --version)
            NVIM_VERSION="${2:?--version requires a tag such as v0.12.5}"
            shift 2
            ;;
        --user)
            TARGET_USER="${2:?--user requires a username}"
            shift 2
            ;;
        --no-config)
            LINK_CONFIG=no
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            printf 'Unknown option: %s\n' "$1" >&2
            usage >&2
            exit 2
            ;;
    esac
done

if ((EUID != 0)); then
    args=(--version "$NVIM_VERSION" --user "$TARGET_USER")
    [[ "$LINK_CONFIG" == yes ]] || args+=(--no-config)
    exec sudo -- "$0" "${args[@]}"
fi

if [[ ! "$NVIM_VERSION" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    printf 'Invalid version: %s (expected vMAJOR.MINOR.PATCH)\n' "$NVIM_VERSION" >&2
    exit 2
fi

TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"
if [[ -z "$TARGET_HOME" || ! -d "$TARGET_HOME" ]]; then
    printf 'Cannot determine a home directory for user: %s\n' "$TARGET_USER" >&2
    exit 2
fi

if ! command -v apt-get >/dev/null; then
    printf 'This script currently supports apt-based Debian/Raspberry Pi OS systems.\n' >&2
    exit 1
fi

# Runtime tools used by the config: git/make/gcc for lazy.nvim, telescope-fzf-native
# and treesitter parsers; ripgrep/fd for Telescope; curl/unzip for Mason.
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y --no-install-recommends \
    build-essential ca-certificates curl fd-find git python3 ripgrep stow unzip

arch="$(dpkg --print-architecture)"
prefix="/opt/nvim-$NVIM_VERSION"

build_dir="$(mktemp -d)"
trap 'rm -rf "$build_dir"' EXIT

install_prebuilt() {
    local asset="nvim-linux-arm64.tar.gz"
    local release_json="$build_dir/release.json"

    curl -fsSL -o "$release_json" \
        "https://api.github.com/repos/neovim/neovim/releases/tags/$NVIM_VERSION"

    # Print "<sha256>  <url>" for the asset, using the digest GitHub records on upload.
    local asset_info sha url
    asset_info="$(python3 - "$release_json" "$asset" <<'PY'
import json
import sys

release = json.load(open(sys.argv[1]))
for asset in release["assets"]:
    if asset["name"] == sys.argv[2]:
        digest = asset.get("digest") or ""
        if not digest.startswith("sha256:"):
            raise SystemExit(f"{sys.argv[2]}: release has no sha256 digest")
        print(digest.removeprefix("sha256:"), asset["browser_download_url"])
        break
else:
    raise SystemExit(f"{sys.argv[2]}: not found in release")
PY
    )"
    read -r sha url <<<"$asset_info"

    curl -fL -o "$build_dir/$asset" "$url"
    printf '%s  %s\n' "$sha" "$build_dir/$asset" | sha256sum -c -

    rm -rf "$prefix"
    install -d -m 0755 "$prefix"
    tar -xzf "$build_dir/$asset" --strip-components=1 -C "$prefix"
}

install_from_source() {
    apt-get install -y --no-install-recommends cmake gettext ninja-build

    git clone --depth 1 --branch "$NVIM_VERSION" \
        https://github.com/neovim/neovim.git "$build_dir/neovim"

    # Keep the build to a couple of jobs so smaller Pis don't run out of memory.
    rm -rf "$prefix"
    make -C "$build_dir/neovim" -j2 \
        CMAKE_BUILD_TYPE=Release \
        CMAKE_INSTALL_PREFIX="$prefix"
    make -C "$build_dir/neovim" install
}

case "$arch" in
    arm64)
        install_prebuilt
        # The prebuilt binary targets a specific glibc; fall back if this OS is too old.
        if ! "$prefix/bin/nvim" --version >/dev/null 2>&1; then
            printf 'Prebuilt Neovim does not run on this system; building from source.\n' >&2
            install_from_source
        fi
        ;;
    armhf)
        printf 'No prebuilt Neovim for 32-bit ARM; building from source (this takes a while).\n'
        install_from_source
        ;;
    *)
        printf 'Unsupported architecture: %s\n' "$arch" >&2
        exit 1
        ;;
esac

ln -sfn "$prefix/bin/nvim" /usr/local/bin/nvim

# Debian installs fd as fdfind; expose it under the name tools look for.
if ! command -v fd >/dev/null && command -v fdfind >/dev/null; then
    ln -sfn "$(command -v fdfind)" /usr/local/bin/fd
fi

config_dir="$TARGET_HOME/.config/nvim"
config_status="skipped (--no-config)"
if [[ "$LINK_CONFIG" == yes ]]; then
    # Create ~/.config first so stow links only nvim, not the whole directory.
    install -d -o "$TARGET_USER" -g "$TARGET_USER" -m 0755 "$TARGET_HOME/.config"
    if [[ -L "$config_dir" && "$(readlink -f "$config_dir")" == "$REPO_DIR/nvim/.config/nvim" ]]; then
        config_status="already linked"
    elif [[ -e "$config_dir" || -L "$config_dir" ]]; then
        config_status="skipped ($config_dir already exists)"
    else
        runuser -u "$TARGET_USER" -- stow -d "$REPO_DIR" -t "$TARGET_HOME" nvim
        config_status="linked from $REPO_DIR/nvim"
    fi
fi

printf 'Installed %s to %s (/usr/local/bin/nvim).\n' \
    "$("$prefix/bin/nvim" --version | head -n 1)" "$prefix"
printf 'Neovim config for %s: %s.\n' "$TARGET_USER" "$config_status"
printf 'Run nvim once to let lazy.nvim install plugins.\n'
