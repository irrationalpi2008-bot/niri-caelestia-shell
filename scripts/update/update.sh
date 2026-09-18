#!/usr/bin/env bash
# update.sh — Smart updater for niri-caelestia-shell
#
# Features:
#   - Verifies git status and checks remote updates
#   - Shows commit log of incoming changes
#   - Safely updates working tree (with stash/pop support)
#   - Detects code changes and selectively re-compiles C++ plugins
#   - Syncs Python virtual environment dependencies when updated
#   - Validates Niri configuration
#   - Gracefully reloads/restarts active Caelestia shell
#
# Usage:
#   ./scripts/update/update.sh [options]
#   caelestia update [options]
#
# Options:
#   --rebuild          Force rebuild C++ QML plugins
#   --reinstall-deps   Force re-install Python virtual environment dependencies
#   --no-restart       Do not reload/restart the running shell after update
#   --stash            Automatically stash uncommitted local changes before update
#   --check            Check for updates without applying them
#   -y, --yes          Non-interactive mode; answer yes to all prompts
#   -h, --help         Show this help message

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

info()    { echo -e "${C_CYAN}[update]${C_RESET} $*"; }
ok()      { echo -e "${C_GREEN}[update]${C_RESET} ${C_BOLD}✔${C_RESET} $*"; }
warn()    { echo -e "${C_YELLOW}[update]${C_RESET} ${C_BOLD}⚠${C_RESET} $*"; }
err()     { echo -e "${C_RED}[update]${C_RESET} ${C_BOLD}✖${C_RESET} $*" >&2; }
section() {
    echo ""
    echo -e "${C_BLUE}${C_BOLD}── $* ──${C_RESET}"
}

# --- Resolve Paths ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# --- CLI Options ---
FORCE_REBUILD=false
FORCE_REINSTALL_DEPS=false
NO_RESTART=false
AUTO_STASH=false
CHECK_ONLY=false
NON_INTERACTIVE=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --rebuild)
            FORCE_REBUILD=true
            shift ;;
        --reinstall-deps)
            FORCE_REINSTALL_DEPS=true
            shift ;;
        --no-restart)
            NO_RESTART=true
            shift ;;
        --stash)
            AUTO_STASH=true
            shift ;;
        --check)
            CHECK_ONLY=true
            shift ;;
        -y|--yes)
            NON_INTERACTIVE=true
            shift ;;
        -h|--help)
            echo "Usage: caelestia update [options]"
            echo ""
            echo "Options:"
            echo "  --check            Check for upstream updates without applying"
            echo "  --rebuild          Force rebuild C++ QML plugins"
            echo "  --reinstall-deps   Force re-install Python dependencies"
            echo "  --no-restart       Do not restart/reload the shell after update"
            echo "  --stash            Automatically git-stash dirty tree before pull"
            echo "  -y, --yes          Non-interactive / automatic confirmation"
            echo "  -h, --help         Show this help message"
            exit 0
            ;;
        *)
            err "Unknown option: $1"
            echo "Run 'caelestia update --help' for usage."
            exit 1
            ;;
    esac
done

cd "$REPO_ROOT"

print_banner() {
    echo -e "${C_MAGENTA}${C_BOLD}"
    echo "  ╔═══════════════════════════════════════════════════════════════╗"
    echo "  ║              Caelestia Shell — Smart Updater                 ║"
    echo "  ╚═══════════════════════════════════════════════════════════════╝"
    echo -e "${C_RESET}"
}

print_banner

# --- 1. Git Repository Check ---
section "Git Repository Status"

if ! git rev-parse --is-inside-work-tree &>/dev/null; then
    err "Directory is not a git repository: $REPO_ROOT"
    exit 1
fi

CURRENT_BRANCH=$(git branch --show-current || echo "HEAD")
info "Current branch: ${C_BOLD}${CURRENT_BRANCH}${C_RESET}"

UPSTREAM=$(git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null || true)
if [[ -z "$UPSTREAM" ]]; then
    warn "No tracking upstream branch configured for '$CURRENT_BRANCH'."
    if git rev-parse "origin/$CURRENT_BRANCH" &>/dev/null; then
        git branch --set-upstream-to="origin/$CURRENT_BRANCH" "$CURRENT_BRANCH" 2>/dev/null || true
        UPSTREAM="origin/$CURRENT_BRANCH"
    else
        UPSTREAM="origin/main"
    fi
fi

info "Checking remote connection and fetching latest changes..."
git fetch --quiet origin 2>/dev/null || {
    warn "Could not fetch from 'origin'. (Offline or no remote configured)."
}

LOCAL_HASH=$(git rev-parse HEAD)
REMOTE_HASH=$(git rev-parse "$UPSTREAM" 2>/dev/null || echo "$LOCAL_HASH")

BEHIND_COUNT=$(git rev-list --count "HEAD..$REMOTE_HASH" 2>/dev/null || echo "0")
AHEAD_COUNT=$(git rev-list --count "$REMOTE_HASH..HEAD" 2>/dev/null || echo "0")

info "Status relative to $UPSTREAM: Behind: $BEHIND_COUNT, Ahead: $AHEAD_COUNT"

if [[ "$CHECK_ONLY" == true ]]; then
    if [[ "$BEHIND_COUNT" -gt 0 ]]; then
        ok "Update available: $BEHIND_COUNT new commit(s) on $UPSTREAM."
        echo ""
        git log --oneline "HEAD..$REMOTE_HASH" -n 10
        exit 0
    else
        ok "Your local installation is completely up-to-date with $UPSTREAM."
        exit 0
    fi
fi

if [[ "$BEHIND_COUNT" -eq 0 && "$FORCE_REBUILD" == false && "$FORCE_REINSTALL_DEPS" == false ]]; then
    ok "Already up to date! (HEAD at ${LOCAL_HASH:0:8})"
    echo ""
    info "Tip: To force recompiling C++ plugins, run: ${C_BOLD}caelestia update --rebuild${C_RESET}"
    info "Tip: To run a full system health check, run: ${C_BOLD}caelestia doctor${C_RESET}"
    exit 0
fi

# --- 2. Handle Dirty Working Directory ---
STASHED=false
if ! git diff-index --quiet HEAD -- 2>/dev/null; then
    warn "You have uncommitted modifications in $REPO_ROOT."
    if [[ "$AUTO_STASH" == true || "$NON_INTERACTIVE" == true ]]; then
        info "Stashing local changes..."
        git stash push -u -m "caelestia-update-auto-stash-$(date +%s)"
        STASHED=true
    else
        echo -n -e "${C_BOLD}Do you want to stash local changes to proceed with update? (Y/n): ${C_RESET}"
        read -r reply
        if [[ "$reply" =~ ^[Nn]$ ]]; then
            err "Update aborted to protect your uncommitted changes."
            exit 1
        fi
        git stash push -u -m "caelestia-update-auto-stash-$(date +%s)"
        STASHED=true
    fi
fi

# --- 3. Inspect Incoming Changes ---
NEEDS_REBUILD=false
NEEDS_PY_UPDATE=false
NEEDS_NIRI_CHECK=false

if [[ "$BEHIND_COUNT" -gt 0 ]]; then
    section "Incoming Updates ($BEHIND_COUNT commits)"
    git log --graph --oneline --decorate "HEAD..$REMOTE_HASH" -n 10
    echo ""

    # Check which files will be modified
    CHANGED_FILES=$(git diff --name-only "HEAD" "$REMOTE_HASH" 2>/dev/null || true)
    if echo "$CHANGED_FILES" | grep -qE "(CMakeLists\.txt|plugin/|subprojects/)"; then
        NEEDS_REBUILD=true
        info "C++ plugin source changes detected: will recompile plugin after pull."
    fi
    if echo "$CHANGED_FILES" | grep -qE "(requirements\.txt|scripts/setup/|scripts/colors/)"; then
        NEEDS_PY_UPDATE=true
        info "Python requirements changes detected: will re-sync virtual environment."
    fi
    if echo "$CHANGED_FILES" | grep -qE "(niri-config/)"; then
        NEEDS_NIRI_CHECK=true
        info "Niri compositor configuration changes detected."
    fi

    # Pull changes
    section "Pulling Updates"
    info "Applying updates via git pull --rebase..."
    git pull --rebase origin "$CURRENT_BRANCH" || {
        err "Git pull rebase failed. Resolving..."
        git rebase --abort 2>/dev/null || true
        if [[ "$STASHED" == true ]]; then
            git stash pop 2>/dev/null || true
        fi
        exit 1
    }
    ok "Git repository updated to $(git rev-parse --short HEAD)."
fi

# Restore stash if we created one
if [[ "$STASHED" == true ]]; then
    info "Restoring stashed changes..."
    git stash pop --quiet || warn "Stash pop had minor conflicts or notes. Check git status."
fi

# --- 4. Rebuild C++ QML Plugins if Needed ---
if [[ "$NEEDS_REBUILD" == true || "$FORCE_REBUILD" == true ]]; then
    section "Building C++ QML Plugins"
    info "Configuring and compiling native Caelestia plugin bundle via CMake & Ninja..."

    if ! command -v cmake &>/dev/null || ! command -v ninja &>/dev/null; then
        err "cmake or ninja missing! Cannot build C++ plugin."
        exit 1
    fi

    mkdir -p "$REPO_ROOT/build"
    cmake -B "$REPO_ROOT/build" -G Ninja -S "$REPO_ROOT" -DCMAKE_BUILD_TYPE=Release
    cmake --build "$REPO_ROOT/build" --parallel

    if [[ -d "$REPO_ROOT/build/qml/Caelestia" ]] && [[ -f "$REPO_ROOT/build/qml/Caelestia/libcaelestiaplugin.so" || -f "$REPO_ROOT/build/plugin/src/Caelestia/libcaelestia.so" ]]; then
        ok "C++ QML plugins built successfully."
    else
        err "C++ plugin compilation did not produce expected libraries!"
        exit 1
    fi
fi

# --- 5. Sync Python Virtual Environment if Needed ---
VENV_DIR="$HOME/.local/state/quickshell/.venv"
if [[ "$NEEDS_PY_UPDATE" == true || "$FORCE_REINSTALL_DEPS" == true ]]; then
    section "Syncing Python Dependencies"
    info "Updating Python virtual environment at $VENV_DIR..."

    if [[ ! -d "$VENV_DIR" ]]; then
        mkdir -p "$VENV_DIR"
        if command -v uv &>/dev/null; then
            uv venv --prompt caelestia "$VENV_DIR" -p 3.12 2>/dev/null || uv venv "$VENV_DIR"
        else
            python3 -m venv "$VENV_DIR"
        fi
    fi

    if command -v uv &>/dev/null; then
        uv pip install -r "$REPO_ROOT/scripts/setup/requirements.txt" --python "$VENV_DIR/bin/python"
    else
        "$VENV_DIR/bin/pip" install --upgrade pip
        "$VENV_DIR/bin/pip" install -r "$REPO_ROOT/scripts/setup/requirements.txt"
    fi
    ok "Python dependencies synced."
fi

# --- 6. Validate Niri Config ---
if [[ "$NEEDS_NIRI_CHECK" == true ]] && command -v niri &>/dev/null; then
    section "Validating Niri Configuration"
    if niri validate -c "$REPO_ROOT/niri-config/config.kdl" &>/dev/null; then
        ok "niri-config/config.kdl validation passed."
    else
        warn "niri-config/config.kdl reported validation warnings or errors:"
        niri validate -c "$REPO_ROOT/niri-config/config.kdl" || true
    fi
fi

# --- 7. Permissions & Scripts ---
chmod +x "$REPO_ROOT"/scripts/**/*.sh 2>/dev/null || true
chmod +x "$REPO_ROOT"/bin/* 2>/dev/null || true
mkdir -p "$HOME/.local/bin"
ln -sf "$REPO_ROOT/bin/caelestia" "$HOME/.local/bin/caelestia"

# --- 8. Reload / Restart Active Shell ---
if [[ "$NO_RESTART" == false ]]; then
    section "Shell Instance Management"
    
    CAELESTIA_PID=$(pgrep -f "quickshell.*shell\.qml" 2>/dev/null | head -n1 || true)
    if [[ -n "$CAELESTIA_PID" ]]; then
        info "Active Caelestia Shell instance detected (PID $CAELESTIA_PID)."
        
        # Check if shell-switcher exists
        SWITCHER_SCRIPT="$HOME/shell-switcher/shell-switcher.sh"
        if [[ -x "$SWITCHER_SCRIPT" ]]; then
            info "Restarting Caelestia Shell via shell-switcher..."
            "$SWITCHER_SCRIPT" caelestia >/dev/null 2>&1 &
            sleep 1
            ok "Caelestia Shell refreshed with new code."
        else
            info "Sending reload signal to Quickshell process..."
            kill -TERM "$CAELESTIA_PID" 2>/dev/null || true
            sleep 1
            if command -v qs &>/dev/null; then
                qs -p "$REPO_ROOT/shell.qml" >/dev/null 2>&1 &
                disown
                ok "Caelestia Shell restarted."
            fi
        fi
    else
        info "Caelestia Shell is not currently active. No restart needed."
    fi
fi

section "Update Summary"
echo -e "${C_GREEN}${C_BOLD}✔ Caelestia Shell successfully updated!${C_RESET}"
echo -e "  Current Commit: ${C_CYAN}$(git rev-parse --short HEAD)${C_RESET} - $(git log -1 --pretty=%s)"
echo ""
info "To inspect full shell diagnostics, run: ${C_BOLD}caelestia doctor${C_RESET}"
echo ""
