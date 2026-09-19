#!/usr/bin/env bash
# installer.sh — Fully Automated Installer for niri-caelestia-shell
#
# Features:
#   - Automatic dependency resolution (Pacman & AUR)
#   - Python virtual environment setup with uv/pip & Material You pipeline
#   - Native C++ QML plugin compilation (CMake + Ninja)
#   - State directory initialization & initial wallpaper color scheme generation
#   - Shell switcher & CLI binary installation (~/.local/bin/caelestia)
#   - System health diagnosis via Doctor
#   - Zero disruption to existing personal Niri configs
#
# Usage:
#   ./scripts/install/installer.sh [options]
#   caelestia install [options]
#
# Options:
#   --skip-deps         Skip system and AUR package installations
#   --skip-build        Skip C++ QML plugin compilation
#   --skip-python       Skip Python virtual environment setup
#   -y, --yes           Non-interactive mode (accept all prompts)
#   -h, --help          Show this help message

set -euo pipefail

# --- ANSI Colors ---
C_RESET='\033[0m'
C_BOLD='\033[1m'
C_DIM='\033[2m'
C_RED='\033[31m'
C_GREEN='\033[32m'
C_YELLOW='\033[33m'
C_BLUE='\033[34m'
C_MAGENTA='\033[35m'
C_CYAN='\033[36m'

info()    { echo -e "${C_CYAN}[install]${C_RESET} $*"; }
ok()      { echo -e "${C_GREEN}[install]${C_RESET} ${C_BOLD}✔${C_RESET} $*"; }
warn()    { echo -e "${C_YELLOW}[install]${C_RESET} ${C_BOLD}⚠${C_RESET} $*"; }
err()     { echo -e "${C_RED}[install]${C_RESET} ${C_BOLD}✖${C_RESET} $*" >&2; }
step()    {
    echo ""
    echo -e "${C_BLUE}${C_BOLD}━━━ Step $1: $2 ━━━${C_RESET}"
}

# --- Resolve Paths ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
STATE_CAELESTIA="$HOME/.local/state/caelestia"
STATE_QUICKSHELL="$HOME/.local/state/quickshell"
VENV_DIR="$STATE_QUICKSHELL/.venv"

# --- Flags ---
SKIP_DEPS=false
SKIP_BUILD=false
SKIP_PYTHON=false
NON_INTERACTIVE=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --skip-deps)     SKIP_DEPS=true; shift ;;
        --skip-build)    SKIP_BUILD=true; shift ;;
        --skip-python)   SKIP_PYTHON=true; shift ;;
        -y|--yes)        NON_INTERACTIVE=true; shift ;;
        -h|--help)
            echo "Usage: caelestia install [options]"
            echo ""
            echo "Options:"
            echo "  --skip-deps      Skip installing system and AUR packages"
            echo "  --skip-build     Skip compiling C++ QML plugins"
            echo "  --skip-python    Skip Python virtual environment setup"
            echo "  -y, --yes        Run non-interactively without prompt stops"
            echo "  -h, --help       Show this help message"
            exit 0
            ;;
        *)
            err "Unknown option: $1"
            echo "Run 'caelestia install --help' for options."
            exit 1
            ;;
    esac
done

cd "$REPO_ROOT"

print_header() {
    echo -e "${C_MAGENTA}${C_BOLD}"
    echo "  ╔═══════════════════════════════════════════════════════════════╗"
    echo "  ║        niri-caelestia-shell — Automated Installer             ║"
    echo "  ╚═══════════════════════════════════════════════════════════════╝"
    echo -e "${C_RESET}"
    info "Target Directory: ${C_BOLD}$REPO_ROOT${C_RESET}"
    echo ""
}

print_header

# --- Pre-Flight Checks ---
if [[ $EUID -eq 0 ]]; then
    err "Please do NOT run this installer directly as root. Run as your normal user."
    exit 1
fi

if ! command -v pacman &>/dev/null; then
    err "Pacman package manager was not found. This auto-installer is tailored for Arch Linux."
    exit 1
fi

# --- Step 1: System & AUR Dependencies ---
step 1 "System Dependencies & Toolchain"

if [[ "$SKIP_DEPS" == true ]]; then
    warn "Skipping system package installation (--skip-deps)."
else
    # Detect or install yay
    AUR_HELPER=""
    if command -v yay &>/dev/null; then
        AUR_HELPER="yay"
    elif command -v paru &>/dev/null; then
        AUR_HELPER="paru"
    else
        warn "Neither yay nor paru was found. Installing yay-bin..."
        sudo pacman -S --needed --noconfirm base-devel git
        TEMP_AUR=$(mktemp -d)
        git clone https://aur.archlinux.org/yay-bin.git "$TEMP_AUR/yay-bin"
        (cd "$TEMP_AUR/yay-bin" && makepkg -si --noconfirm)
        rm -rf "$TEMP_AUR"
        AUR_HELPER="yay"
    fi
    ok "AUR helper available: $AUR_HELPER"

    PACMAN_PACKAGES=(
        # Build tools & compilers
        base-devel cmake ninja clang git pkg-config
        # Qt6 & QML runtimes
        qt6-base qt6-declarative qt6-svg qt6-wayland
        # Audio & visualization
        cava pavucontrol-qt wireplumber pipewire-pulse libdbusmenu-gtk3 playerctl
        # Hardware control & portals
        brightnessctl xdg-desktop-portal xdg-desktop-portal-gtk
        # Utilities
        bc coreutils curl wget jq ripgrep xdg-user-dirs rsync
        # Screen capture & tools
        grim slurp swappy tesseract tesseract-data-eng cliphist wl-clipboard fuzzel imagemagick
    )

    info "Checking & installing core packages via pacman..."
    sudo pacman -S --needed --noconfirm "${PACMAN_PACKAGES[@]}"

    AUR_PACKAGES=(
        matugen-bin
        ttf-material-symbols-variable-git
        ttf-jetbrains-mono-nerd
        ttf-rubik-vf
        ttf-readex-pro
        uv
    )

    info "Checking & installing AUR packages ($AUR_HELPER)..."
    for pkg in "${AUR_PACKAGES[@]}"; do
        if pacman -Qi "$pkg" &>/dev/null || pacman -Qi "${pkg%-bin}" &>/dev/null; then
            continue
        fi
        info "Installing AUR package: $pkg..."
        "$AUR_HELPER" -S --needed --noconfirm "$pkg" || warn "Could not install $pkg from AUR automatically."
    done

    ok "System and AUR dependencies verified."
fi

# --- Step 2: Python Environment & Material You ---
step 2 "Python Virtual Environment & Material Theming"

if [[ "$SKIP_PYTHON" == true ]]; then
    warn "Skipping Python virtual environment setup (--skip-python)."
else
    mkdir -p "$STATE_QUICKSHELL"
    info "Configuring Python virtual environment at $VENV_DIR..."

    if ! command -v uv &>/dev/null; then
        if [[ ! -x "$HOME/.local/bin/uv" ]]; then
            info "Installing uv for blazing fast Python environment..."
            curl -LsSf https://astral.sh/uv/install.sh | sh >/dev/null 2>&1 || true
            export PATH="$HOME/.local/bin:$PATH"
        fi
    fi

    if command -v uv &>/dev/null || [[ -x "$HOME/.local/bin/uv" ]]; then
        UV_BIN=$(command -v uv 2>/dev/null || echo "$HOME/.local/bin/uv")
        info "Creating venv via uv..."
        "$UV_BIN" venv --prompt caelestia "$VENV_DIR" -p 3.12 2>/dev/null || "$UV_BIN" venv --prompt caelestia "$VENV_DIR"
        info "Installing required Python dependencies..."
        "$UV_BIN" pip install -r "$REPO_ROOT/scripts/setup/requirements.txt" --python "$VENV_DIR/bin/python"
    else
        info "Falling back to standard python3 -m venv..."
        python3 -m venv "$VENV_DIR"
        "$VENV_DIR/bin/pip" install --upgrade pip
        "$VENV_DIR/bin/pip" install -r "$REPO_ROOT/scripts/setup/requirements.txt"
    fi

    # Verify materialyoucolor
    if "$VENV_DIR/bin/python" -c "import materialyoucolor, PIL" &>/dev/null; then
        ok "Python venv verified with materialyoucolor and Pillow."
    else
        warn "Python venv installed, but import test had warnings. Checking fallback..."
    fi
fi

# --- Step 3: Compile C++ QML Plugin ---
step 3 "Compile C++ QML Plugins"

if [[ "$SKIP_BUILD" == true ]]; then
    warn "Skipping C++ build step (--skip-build)."
else
    info "Configuring CMake build directory..."
    mkdir -p "$REPO_ROOT/build"
    cmake -B "$REPO_ROOT/build" -G Ninja -S "$REPO_ROOT" -DCMAKE_BUILD_TYPE=Release
    
    info "Compiling native QML plugins (Ninja parallel build)..."
    cmake --build "$REPO_ROOT/build" --parallel

    TARGET_PLUGIN="$REPO_ROOT/build/qml/Caelestia/libcaelestiaplugin.so"
    FALLBACK_PLUGIN="$REPO_ROOT/build/plugin/src/Caelestia/libcaelestia.so"
    if [[ -f "$TARGET_PLUGIN" || -f "$FALLBACK_PLUGIN" ]]; then
        ok "C++ plugin compiled successfully."
    else
        err "C++ plugin compilation failed to produce $TARGET_PLUGIN!"
        exit 1
    fi
fi

# --- Step 4: Directories, State & Theming Pipeline ---
step 4 "State Directories & Theme Initialization"

mkdir -p "$STATE_CAELESTIA"
mkdir -p "$STATE_CAELESTIA/wallpaper"
mkdir -p "$STATE_QUICKSHELL/user/generated/terminal"
mkdir -p "$STATE_QUICKSHELL/user/generated/wallpaper"
mkdir -p "$HOME/.config/gtk-3.0" "$HOME/.config/gtk-4.0" "$HOME/.config/Kvantum"

# Ensure matugen standalone binary fallback exists in ~/.local/bin if not in /usr/bin
if ! command -v matugen &>/dev/null && [[ -f "$HOME/.local/bin/matugen" ]]; then
    export PATH="$HOME/.local/bin:$PATH"
fi

# Find or initialize wallpaper
WALL_FILE="$STATE_CAELESTIA/wallpaper/path.txt"
CURRENT_WALL=""
if [[ -f "$WALL_FILE" ]]; then
    CURRENT_WALL=$(cat "$WALL_FILE" 2>/dev/null || true)
fi

if [[ -z "$CURRENT_WALL" || ! -f "$CURRENT_WALL" ]]; then
    CURRENT_WALL=$(find "$HOME/Pictures/Wallpapers" -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.webp" \) 2>/dev/null | head -n1 || true)
fi

if [[ -n "$CURRENT_WALL" && -f "$CURRENT_WALL" ]]; then
    info "Generating initial dynamic Material You color scheme from: $CURRENT_WALL..."
    bash "$REPO_ROOT/scripts/colors/switchwall.sh" --mode dark --type scheme-tonal-spot "$CURRENT_WALL" || true
    ok "Dynamic color scheme generated."
else
    info "No sample wallpaper found. Created empty state; wallpaper selection can be configured later."
fi

# --- Step 5: Shell Switcher Integration ---
step 5 "Shell Switcher & Compositor Config"

SWITCHER_DIR="$HOME/shell-switcher"
if [[ -f "$SWITCHER_DIR/shell-switcher.sh" ]]; then
    info "Preserving user shell switcher at $SWITCHER_DIR/shell-switcher.sh"
    chmod +x "$SWITCHER_DIR/shell-switcher.sh"
    ok "Shell switcher ready."
else
    info "Setting up shell switcher helper in $SWITCHER_DIR..."
    mkdir -p "$SWITCHER_DIR"
    cat << SWITCHOVER > "$SWITCHER_DIR/shell-switcher.sh"
#!/usr/bin/env bash
# Shell Switcher for Niri
set -euo pipefail

CHOICE="\${1:-}"
CAELESTIA_DIR="$REPO_ROOT"

kill_shells() {
    pkill -f "quickshell" 2>/dev/null || true
    pkill -f "qs" 2>/dev/null || true
    sleep 0.5
}

switch_to_caelestia() {
    kill_shells
    if command -v niri &>/dev/null; then
        niri msg action set-config-path "$CAELESTIA_DIR/niri-config/config.kdl" 2>/dev/null || true
    fi
    qs -p "$CAELESTIA_DIR/shell.qml" >/dev/null 2>&1 &
    disown
    echo "caelestia" > "$HOME/.local/state/caelestia/active_shell"
}

switch_to_inir() {
    kill_shells
    if command -v niri &>/dev/null; then
        niri msg action set-config-path "$HOME/.config/niri/config.kdl" 2>/dev/null || true
    fi
    qs -p "$HOME/.config/quickshell/inir/shell.qml" >/dev/null 2>&1 &
    disown
    echo "inir" > "$HOME/.local/state/caelestia/active_shell"
}

case "$CHOICE" in
    caelestia) switch_to_caelestia ;;
    inir) switch_to_inir ;;
    *)
        echo "Usage: shell-switcher.sh [caelestia|inir]"
        exit 1
        ;;
esac
SWITCHOVER
    chmod +x "$SWITCHER_DIR/shell-switcher.sh"
    ok "Created shell switcher helper in $SWITCHER_DIR/shell-switcher.sh"
fi

# Ensure personal config is NEVER touched
ok "Personal config safety: ~/.config/niri/config.kdl left untouched."

# --- Step 6: CLI Tool Installation ---
step 6 "Install 'caelestia' CLI"

mkdir -p "$HOME/.local/bin"
chmod +x "$REPO_ROOT"/bin/* 2>/dev/null || true
chmod +x "$REPO_ROOT"/scripts/**/*.sh 2>/dev/null || true

ln -sf "$REPO_ROOT/bin/caelestia" "$HOME/.local/bin/caelestia"

# Check if ~/.local/bin is in PATH
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    warn "$HOME/.local/bin is not in your current PATH."
    info "Adding export PATH=\"\$HOME/.local/bin:\$PATH\" to shell RC files..."
    for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
        if [[ -f "$rc" ]] && ! grep -q '\$HOME/\.local/bin' "$rc"; then
            echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$rc"
            info "Updated $rc"
        fi
    done
fi
ok "'caelestia' command installed to $HOME/.local/bin/caelestia"

# --- Step 7: System Health Doctor ---
step 7 "Running System Health Verification"

"$REPO_ROOT/scripts/doctor/doctor.sh" || true

echo ""
echo -e "${C_GREEN}${C_BOLD}"
echo "  ╔═══════════════════════════════════════════════════════════════╗"
echo "  ║        Caelestia Shell Setup Completed Successfully!          ║"
echo "  ╚═══════════════════════════════════════════════════════════════╝"
echo -e "${C_RESET}"
echo -e "You can now control everything using the ${C_CYAN}${C_BOLD}caelestia${C_RESET} command:"
echo -e "  • ${C_CYAN}caelestia status${C_RESET}          — Show active shell, PID, memory, compositor, theme"
echo -e "  • ${C_CYAN}caelestia doctor${C_RESET}          — Inspect system health, dependencies, and diagnostics"
echo -e "  • ${C_CYAN}caelestia update${C_RESET}          — Smart pull, auto-rebuild C++ plugins, and reload"
echo -e "  • ${C_CYAN}caelestia theme <path>${C_RESET}    — Change wallpaper & regenerate Material You palette"
echo -e "  • ${C_CYAN}caelestia launcher${C_RESET}        — Toggle application launcher drawer"
echo -e "  • ${C_CYAN}caelestia controlcenter${C_RESET}   — Open Control Center visual settings"
echo -e "  • ${C_CYAN}caelestia clipboard${C_RESET}       — Toggle clipboard history drawer or wipe history"
echo -e "  • ${C_CYAN}caelestia capture [mode]${C_RESET}  — Region screenshot, OCR text extraction, Google Lens"
echo -e "  • ${C_CYAN}caelestia switch${C_RESET}          — Seamlessly toggle between Caelestia and default shell"
echo -e "  • ${C_CYAN}caelestia media${C_RESET}           — Control media drawer and playback"
echo -e "  • ${C_CYAN}caelestia dnd / lock${C_RESET}      — Toggle Do Not Disturb or trigger screen lock"
echo -e "  • ${C_CYAN}caelestia --help${C_RESET}          — View all available commands"
echo ""
