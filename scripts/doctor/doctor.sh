#!/usr/bin/env bash
# doctor.sh — Health & Diagnostic Checker for niri-caelestia-shell
#
# Inspects every subsystem required for niri-caelestia-shell:
#   1. Compositor & Display Session (Niri, Wayland, Display)
#   2. Quickshell Core & Configuration
#   3. Native C++ QML Plugins & Build Artifacts
#   4. Color Generation & Dynamic Theming Pipeline
#   5. Audio & Visualizer Subsystem (Aubio, libcava, PipeWire)
#   6. Hardware Control (Brightness, Volume, Battery)
#   7. CLI Utilities & Screen Capture Tools
#   8. Typography & Required Fonts
#
# Usage: ./scripts/doctor/doctor.sh [--fix] [--verbose]

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Styling
C_RESET='\e[0m'
C_BOLD='\e[1m'
C_DIM='\e[2m'
C_RED='\e[31m'
C_GREEN='\e[32m'
C_YELLOW='\e[33m'
C_BLUE='\e[34m'
C_MAGENTA='\e[35m'
C_CYAN='\e[36m'
C_WHITE='\e[37m'

AUTO_FIX=false
VERBOSE=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --fix|-f)     AUTO_FIX=true; shift ;;
        --verbose|-v) VERBOSE=true; shift ;;
        -h|--help)
            echo -e "${C_BOLD}Usage:${C_RESET} caelestia doctor [options]"
            echo ""
            echo "Options:"
            echo "  --fix, -f       Attempt to automatically resolve detected issues"
            echo "  --verbose, -v   Show detailed diagnostic context and output"
            echo "  --help, -h      Show this help dialog"
            exit 0
            ;;
        *) shift ;;
    esac
done

TOTAL_CHECKS=0
PASSED_CHECKS=0
WARNING_CHECKS=0
FAILED_CHECKS=0
declare -a FIX_ACTIONS=()

print_header() {
    echo ""
    echo -e "${C_BOLD}${C_MAGENTA}🌌 Caelestia Shell Health Doctor${C_RESET}"
    echo -e "${C_DIM}Inspecting system health, dependencies, and configuration...${C_RESET}"
    echo -e "${C_DIM}─────────────────────────────────────────────────────────────────${C_RESET}"
}

print_section() {
    local title="$1"
    echo ""
    echo -e "${C_BOLD}${C_CYAN}── $title ──${C_RESET}"
}

report_ok() {
    local item="$1"
    local detail="${2:-}"
    ((TOTAL_CHECKS++)) || true
    ((PASSED_CHECKS++)) || true
    if [[ -n "$detail" ]]; then
        echo -e "  ${C_GREEN}✔${C_RESET} ${C_BOLD}$item${C_RESET} ${C_DIM}($detail)${C_RESET}"
    else
        echo -e "  ${C_GREEN}✔${C_RESET} ${C_BOLD}$item${C_RESET}"
    fi
}

report_warn() {
    local item="$1"
    local reason="$2"
    local fix_hint="${3:-}"
    ((TOTAL_CHECKS++)) || true
    ((WARNING_CHECKS++)) || true
    echo -e "  ${C_YELLOW}⚠${C_RESET} ${C_BOLD}$item${C_RESET} — ${C_YELLOW}$reason${C_RESET}"
    if [[ -n "$fix_hint" ]]; then
        echo -e "    ${C_DIM}Tip: $fix_hint${C_RESET}"
    fi
}

report_fail() {
    local item="$1"
    local reason="$2"
    local fix_hint="${3:-}"
    ((TOTAL_CHECKS++)) || true
    ((FAILED_CHECKS++)) || true
    echo -e "  ${C_RED}✖${C_RESET} ${C_BOLD}$item${C_RESET} — ${C_RED}$reason${C_RESET}"
    if [[ -n "$fix_hint" ]]; then
        echo -e "    ${C_DIM}Fix: $fix_hint${C_RESET}"
        FIX_ACTIONS+=("$fix_hint")
    fi
}

# 1. Compositor & Session
check_compositor() {
    print_section "Compositor & Wayland Session"

    # Wayland display
    if [[ -n "${WAYLAND_DISPLAY:-}" ]]; then
        report_ok "Wayland Display" "$WAYLAND_DISPLAY"
    elif [[ -e "${XDG_RUNTIME_DIR:-/run/user/$UID}/wayland-1" ]]; then
        export WAYLAND_DISPLAY="wayland-1"
        report_ok "Wayland Display" "Detected wayland-1 socket"
    elif [[ -e "${XDG_RUNTIME_DIR:-/run/user/$UID}/wayland-0" ]]; then
        export WAYLAND_DISPLAY="wayland-0"
        report_ok "Wayland Display" "Detected wayland-0 socket"
    else
        report_warn "Wayland Display" "No WAYLAND_DISPLAY variable found in current shell" "Make sure you are running inside a Wayland compositor"
    fi

    # Niri Compositor
    if command -v niri &>/dev/null; then
        local niri_ver
        niri_ver=$(niri --version 2>/dev/null || echo "installed")
        report_ok "Niri Binary" "$niri_ver"
    else
        report_fail "Niri Binary" "niri executable not found in PATH" "sudo pacman -S --needed niri"
    fi

    # Niri IPC Socket
    local niri_sock="${NIRI_SOCKET:-}"
    if [[ -z "$niri_sock" ]] && command -v systemctl &>/dev/null; then
        niri_sock=$(systemctl --user show-environment 2>/dev/null | grep -E "^NIRI_SOCKET=" | cut -d= -f2- || true)
    fi
    if [[ -z "$niri_sock" ]]; then
        niri_sock=$(ls /run/user/"$UID"/niri.*.sock 2>/dev/null | head -n1 || true)
    fi

    if [[ -n "$niri_sock" && -S "$niri_sock" ]]; then
        report_ok "Niri IPC Socket" "$niri_sock"
    else
        report_warn "Niri IPC Socket" "No active Niri IPC socket discovered" "Niri may not be running right now"
    fi

    # Display Outputs
    if command -v niri &>/dev/null && niri msg outputs &>/dev/null; then
        local outputs
        outputs=$(niri msg outputs 2>/dev/null | grep -E "Output" | wc -l || echo "1")
        report_ok "Display Outputs" "$outputs output(s) detected via Niri IPC"
    fi
}

# 2. Quickshell Core
check_quickshell() {
    print_section "Quickshell Core"

    if command -v qs &>/dev/null || command -v quickshell &>/dev/null; then
        local qs_cmd="qs"
        command -v qs &>/dev/null || qs_cmd="quickshell"
        local qs_ver
        qs_ver=$($qs_cmd --version 2>/dev/null || echo "installed")
        report_ok "Quickshell Binary" "$qs_cmd ($qs_ver)"
    else
        report_fail "Quickshell Binary" "Neither 'qs' nor 'quickshell' was found in PATH" "yay -S --needed quickshell-git"
    fi

    # Check shell configuration entrypoint
    local shell_qml="$REPO_ROOT/shell.qml"
    if [[ -f "$shell_qml" ]]; then
        report_ok "Shell Entrypoint" "$shell_qml"
    else
        report_fail "Shell Entrypoint" "shell.qml missing at $shell_qml" "Check repository integrity"
    fi

    # Check active running instance
    local running_pid
    running_pid=$(pgrep -f "qs.*$REPO_ROOT" | head -n1 || true)
    if [[ -n "$running_pid" ]]; then
        local mem
        mem=$(ps -o rss= -p "$running_pid" 2>/dev/null | awk '{printf "%.1f MB", $1/1024}' || echo "")
        report_ok "Running Instance" "Active PID $running_pid${mem:+, memory: $mem}"
    else
        report_warn "Running Instance" "Caelestia Shell is not currently active" "Run 'caelestia start' to start"
    fi
}

# 3. Native C++ QML Plugins
check_cpp_plugins() {
    print_section "Native C++ Plugins & Qt6 Libraries"

    local build_dir="$REPO_ROOT/build"
    local qml_out="$build_dir/qml/Caelestia"
    local lib_caelestia="$build_dir/plugin/src/Caelestia/libcaelestia.so"
    local lib_services="$build_dir/plugin/src/Caelestia/Services/libcaelestia-services.so"
    local lib_models="$build_dir/plugin/src/Caelestia/Models/libcaelestia-models.so"

    if [[ -d "$qml_out" && -f "$lib_caelestia" && -f "$lib_services" && -f "$lib_models" ]]; then
        report_ok "C++ QML Plugin Bundle" "Compiled at $qml_out"
    else
        report_fail "C++ QML Plugin Bundle" "C++ plugin libraries missing or uncompiled" "caelestia repair  (or: cmake -B build -G Ninja && cmake --build build)"
    fi

    # Build tools
    if command -v cmake &>/dev/null && command -v ninja &>/dev/null; then
        report_ok "Build Toolchain" "cmake $(cmake --version | head -n1 | cut -d' ' -f3), ninja"
    else
        report_fail "Build Toolchain" "cmake or ninja missing" "sudo pacman -S --needed cmake ninja"
    fi
}

# 4. Audio & Visualizer
check_audio() {
    print_section "Audio & Cava Visualizer"

    # Aubio
    if pkg-config --exists aubio 2>/dev/null || ldconfig -p 2>/dev/null | grep -q "libaubio"; then
        report_ok "Aubio Library" "libaubio found"
    else
        report_fail "Aubio Library" "aubio development headers not found" "sudo pacman -S --needed aubio"
    fi

    # Cava / libcava
    if pkg-config --exists libcava 2>/dev/null || pkg-config --exists cava 2>/dev/null || ldconfig -p 2>/dev/null | grep -q "libcava"; then
        report_ok "Cava Library" "libcava found"
    else
        report_fail "Cava Library" "libcava development library not found" "yay -S --needed libcava-git"
    fi

    # Pipewire / Wireplumber
    if command -v wpctl &>/dev/null; then
        report_ok "WirePlumber (wpctl)" "installed"
    else
        report_fail "WirePlumber" "wpctl not found" "sudo pacman -S --needed wireplumber"
    fi
}

# 5. Color Pipeline & Theming
check_theming() {
    print_section "Color Pipeline & Dynamic Theming"

    # Matugen CLI
    if command -v matugen &>/dev/null; then
        local mat_ver
        mat_ver=$(matugen --version 2>/dev/null || echo "installed")
        report_ok "Matugen Tool" "$mat_ver"
    else
        report_fail "Matugen Tool" "matugen not found in PATH" "caelestia repair  (or: yay -S matugen)"
    fi

    # Matugen config override
    local mat_cfg="$REPO_ROOT/matugen.toml"
    if [[ -f "$mat_cfg" ]]; then
        report_ok "Matugen Config Override" "$mat_cfg"
    else
        report_warn "Matugen Config Override" "matugen.toml missing in repo root" "Will be generated automatically"
    fi

    # Python Venv
    local venv_path="${CAELESTIA_VIRTUAL_ENV:-$HOME/.local/state/quickshell/.venv}"
    if [[ -d "$venv_path" && -f "$venv_path/bin/python3" ]]; then
        # Check materialyoucolor
        if "$venv_path/bin/python3" -c "import materialyoucolor, PIL" 2>/dev/null; then
            report_ok "Python Venv & MaterialYouColor" "$venv_path"
        else
            report_fail "Python Dependencies" "materialyoucolor or PIL missing in venv" "$venv_path/bin/pip install materialyoucolor pillow"
        fi
    else
        report_fail "Python Virtual Environment" "Virtual environment not found at $venv_path" "caelestia repair"
    fi

    # Scheme state file
    local scheme_file="$HOME/.local/state/caelestia/scheme.json"
    if [[ -f "$scheme_file" && -s "$scheme_file" ]]; then
        local colors_cnt
        colors_cnt=$(jq '.colours | length' "$scheme_file" 2>/dev/null || echo "0")
        report_ok "Active Scheme State" "$scheme_file ($colors_cnt colors)"
    else
        report_warn "Active Scheme State" "scheme.json is missing or empty" "Will be generated automatically on wallpaper change"
    fi
}

# 6. Hardware & Integration Tools
check_hardware_and_tools() {
    print_section "Hardware & System Utilities"

    # Brightness control
    if command -v brightnessctl &>/dev/null; then
        report_ok "Brightnessctl" "installed"
    else
        report_warn "Brightnessctl" "brightnessctl not found (hardware brightness keys may not respond)" "sudo pacman -S --needed brightnessctl"
    fi

    # Clipboard manager
    if command -v cliphist &>/dev/null && command -v wl-paste &>/dev/null; then
        report_ok "Clipboard History (cliphist + wl-clipboard)" "installed"
    else
        report_fail "Clipboard Utilities" "cliphist or wl-clipboard missing" "sudo pacman -S --needed cliphist wl-clipboard"
    fi

    # Screenshot & Region tools
    local screen_tools=(grim slurp swappy tesseract)
    local missing_tools=()
    for tool in "${screen_tools[@]}"; do
        if ! command -v "$tool" &>/dev/null; then
            missing_tools+=("$tool")
        fi
    done

    if [[ ${#missing_tools[@]} -eq 0 ]]; then
        report_ok "Capture & OCR Tools" "grim, slurp, swappy, tesseract installed"
    else
        report_warn "Capture Tools" "Missing: ${missing_tools[*]}" "sudo pacman -S --needed ${missing_tools[*]}"
    fi

    # Media player control
    if command -v playerctl &>/dev/null; then
        report_ok "Playerctl (Media keys)" "installed"
    else
        report_warn "Playerctl" "playerctl not found" "sudo pacman -S --needed playerctl"
    fi
}

# 7. Fonts & Typography
check_fonts() {
    print_section "Fonts & Icons"

    if command -v fc-list &>/dev/null; then
        # Material Symbols / Icons
        if fc-list : family | grep -iqE "material (symbols|icons)"; then
            report_ok "Material Icons Font" "installed"
        else
            report_warn "Material Icons Font" "Material Symbols / Icons not found" "yay -S --needed ttf-material-symbols-variable-git"
        fi

        # Monospace font (JetBrains Mono)
        if fc-list : family | grep -iq "jetbrains mono"; then
            report_ok "JetBrains Mono Font" "installed"
        else
            report_warn "JetBrains Mono Font" "JetBrains Mono font not found" "sudo pacman -S --needed ttf-jetbrains-mono-nerd"
        fi

        # Rubik font
        if fc-list : family | grep -iq "rubik"; then
            report_ok "Rubik Font" "installed"
        else
            report_warn "Rubik Font" "Rubik font not found (used in clocks/UI)" "yay -S --needed ttf-rubik-vf"
        fi
    else
        report_warn "Font Config" "fc-list command not found" "sudo pacman -S --needed fontconfig"
    fi
}

# 8. Auto-repair
execute_auto_repair() {
    echo ""
    echo -e "${C_BOLD}${C_YELLOW}🔧 Executing Auto-Repair Mode...${C_RESET}"
    echo -e "${C_DIM}─────────────────────────────────────────────────────────────────${C_RESET}"

    # 1. Ensure matugen.toml exists
    if [[ ! -f "$REPO_ROOT/matugen.toml" ]]; then
        echo -e "  • Generating default matugen.toml..."
        printf "[config]\n[templates]\n" > "$REPO_ROOT/matugen.toml"
    fi

    # 2. Ensure state directory exists
    mkdir -p "$HOME/.local/state/caelestia/wallpaper"
    mkdir -p "$HOME/.local/state/quickshell/user/generated"

    # 3. Check / repair Python venv
    local venv_path="${CAELESTIA_VIRTUAL_ENV:-$HOME/.local/state/quickshell/.venv}"
    if [[ ! -d "$venv_path" || ! -f "$venv_path/bin/python3" ]]; then
        echo -e "  • Creating Python virtual environment at $venv_path..."
        mkdir -p "$(dirname "$venv_path")"
        if command -v uv &>/dev/null; then
            uv venv "$venv_path" -p 3.12 2>/dev/null || uv venv "$venv_path"
            "$venv_path/bin/pip" install --upgrade pip
            "$venv_path/bin/pip" install -r "$REPO_ROOT/scripts/setup/requirements.txt"
        else
            python3 -m venv "$venv_path"
            "$venv_path/bin/pip" install --upgrade pip
            "$venv_path/bin/pip" install -r "$REPO_ROOT/scripts/setup/requirements.txt"
        fi
    fi

    # 4. Check / compile C++ plugin
    local qml_out="$REPO_ROOT/build/qml/Caelestia"
    if [[ ! -d "$qml_out" ]]; then
        echo -e "  • Building C++ QML plugin..."
        cmake -B "$REPO_ROOT/build" -G Ninja -S "$REPO_ROOT" -DCMAKE_BUILD_TYPE=Release
        cmake --build "$REPO_ROOT/build"
    fi

    # 5. Check / generate scheme.json
    local scheme_file="$HOME/.local/state/caelestia/scheme.json"
    local wall_path=""
    if [[ -f "$HOME/.local/state/caelestia/wallpaper/path.txt" ]]; then
        wall_path=$(cat "$HOME/.local/state/caelestia/wallpaper/path.txt")
    fi
    if [[ -z "$wall_path" || ! -f "$wall_path" ]]; then
        wall_path=$(find "$HOME/Pictures/Wallpapers" -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.webp" \) 2>/dev/null | head -n1 || true)
    fi

    if [[ -n "$wall_path" && -f "$wall_path" ]]; then
        echo -e "  • Generating color scheme from wallpaper: $wall_path..."
        bash "$REPO_ROOT/scripts/colors/switchwall.sh" --mode dark --type scheme-tonal-spot "$wall_path" || true
    fi

    echo ""
    echo -e "${C_GREEN}${C_BOLD}✔ Auto-repair tasks completed.${C_RESET} Re-running doctor..."
    AUTO_FIX=false
    main
}

# Main Summary
print_summary() {
    echo ""
    echo -e "${C_DIM}─────────────────────────────────────────────────────────────────${C_RESET}"
    echo -e "${C_BOLD}Diagnostic Summary:${C_RESET}"
    echo -e "  Checks Passed:  ${C_GREEN}${PASSED_CHECKS}${C_RESET} / ${TOTAL_CHECKS}"
    if (( WARNING_CHECKS > 0 )); then
        echo -e "  Warnings:       ${C_YELLOW}${WARNING_CHECKS}${C_RESET}"
    fi
    if (( FAILED_CHECKS > 0 )); then
        echo -e "  Failures:       ${C_RED}${FAILED_CHECKS}${C_RESET}"
    fi

    if (( FAILED_CHECKS == 0 && WARNING_CHECKS == 0 )); then
        echo ""
        echo -e "  ${C_GREEN}${C_BOLD}🎉 System is fully healthy! Caelestia Shell is ready to roll.${C_RESET}"
    elif (( FAILED_CHECKS > 0 )); then
        echo ""
        if [[ "$AUTO_FIX" == false ]]; then
            echo -e "  ${C_YELLOW}${C_BOLD}To automatically fix common issues, run:${C_RESET}"
            echo -e "    ${C_CYAN}caelestia doctor --fix${C_RESET}  or  ${C_CYAN}caelestia repair${C_RESET}"
        fi
    fi
    echo ""
}

main() {
    TOTAL_CHECKS=0
    PASSED_CHECKS=0
    WARNING_CHECKS=0
    FAILED_CHECKS=0
    FIX_ACTIONS=()

    print_header
    check_compositor
    check_quickshell
    check_cpp_plugins
    check_audio
    check_theming
    check_hardware_and_tools
    check_fonts

    print_summary

    if [[ "$AUTO_FIX" == true && ( FAILED_CHECKS -gt 0 || WARNING_CHECKS -gt 0 ) ]]; then
        execute_auto_repair
    fi
}

main
