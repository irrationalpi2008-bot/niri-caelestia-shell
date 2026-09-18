#!/usr/bin/env bash
# install.sh — Root automated installer entrypoint for niri-caelestia-shell
#
# Usage:
#   ./install.sh [options]
#
# Options:
#   --skip-deps      Skip installing system and AUR packages
#   --skip-build     Skip compiling C++ QML plugins
#   --skip-python    Skip Python virtual environment setup
#   -y, --yes        Run non-interactively without prompt stops
#   -h, --help       Show help message

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
chmod +x "$SCRIPT_DIR/scripts/install/installer.sh" "$SCRIPT_DIR/bin/caelestia" 2>/dev/null || true

exec "$SCRIPT_DIR/scripts/install/installer.sh" "$@"
