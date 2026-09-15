#!/usr/bin/env bash
# ==============================================================================
# Brownfield Template Installer for AI Coding Agents
# Supports local and remote execution (via curl | bash)
# ==============================================================================
set -euo pipefail

FORCE_YES=false
TARGET_DIR=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -y|--yes|-f|--force)
            FORCE_YES=true
            shift
            ;;
        -h|--help)
            echo "Usage: install.sh [-y|--yes] [TARGET_DIR]"
            echo ""
            echo "Options:"
            echo "  -y, --yes, -f, --force    Overwrite files without interactive confirmation"
            echo "  -h, --help                Show this help message"
            exit 0
            ;;
        *)
            if [ -z "$TARGET_DIR" ]; then
                TARGET_DIR="$1"
            else
                echo "⚠️  Extra argument ignored: $1"
            fi
            shift
            ;;
    esac
done

TARGET_DIR="${TARGET_DIR:-.}"
mkdir -p "$TARGET_DIR/.agent"
RESOLVED_TARGET="$(cd "$TARGET_DIR" && pwd)"

# Remote repository URL for piped execution
TEMPLATE_REPO_URL="${TEMPLATE_REPO_URL:-https://raw.githubusercontent.com/ye-sandbox/template-agent/brownfield}"

# Detect execution mode (local vs remote)
SCRIPT_SOURCE="${BASH_SOURCE[0]:-}"
SCRIPT_DIR=""
if [ -n "$SCRIPT_SOURCE" ] && [ -f "$SCRIPT_SOURCE" ]; then
    SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_SOURCE")" && pwd)"
fi

if [ -n "$SCRIPT_DIR" ] && [ -f "$SCRIPT_DIR/AGENTS.md" ] && [ -d "$SCRIPT_DIR/.agent" ]; then
    INSTALL_MODE="local"
else
    INSTALL_MODE="remote"
fi

echo "======================================================="
echo " Brownfield Template Installer (ADD for Legacies)"
echo " Destination: $RESOLVED_TARGET"
echo " Mode:        $([ "$INSTALL_MODE" = "local" ] && echo "Local ($SCRIPT_DIR)" || echo "Remote ($TEMPLATE_REPO_URL)")"
echo "======================================================="

# Helper to copy (local) or download (remote) files
fetch_file() {
    local rel_path="$1"
    local dest_path="$2"

    if [ "$INSTALL_MODE" = "local" ]; then
        cp "$SCRIPT_DIR/$rel_path" "$dest_path"
    else
        local url="${TEMPLATE_REPO_URL}/${rel_path}"
        if command -v curl >/dev/null 2>&1; then
            curl -fsSL "$url" -o "$dest_path"
        elif command -v wget >/dev/null 2>&1; then
            wget -qO "$dest_path" "$url"
        else
            echo "❌ Error: 'curl' or 'wget' is required to download template files." >&2
            exit 1
        fi
    fi
}

# Helper for interactive confirmations (safe with piped execution)
ask_confirm() {
    local prompt="$1"
    local reply=""

    if [ "$FORCE_YES" = true ]; then
        return 0
    fi

    if [ -c /dev/tty ]; then
        read -p "$prompt (y/N): " -r reply </dev/tty || reply=""
    elif [ -t 0 ]; then
        read -p "$prompt (y/N): " -r reply || reply=""
    else
        echo "⚠️  Non-interactive terminal detected. Retaining existing file."
        return 1
    fi

    if [[ "$reply" =~ ^[yYsS]$ ]]; then
        return 0
    else
        return 1
    fi
}

# 1. Install AGENTS.md
if [ -f "$RESOLVED_TARGET/AGENTS.md" ]; then
    echo "⚠️  Warning: 'AGENTS.md' already exists in $RESOLVED_TARGET."
    if ask_confirm "Overwrite existing AGENTS.md?"; then
        fetch_file "AGENTS.md" "$RESOLVED_TARGET/AGENTS.md"
        echo "✅ AGENTS.md successfully updated."
    else
        echo "ℹ️  Retaining existing AGENTS.md."
    fi
else
    fetch_file "AGENTS.md" "$RESOLVED_TARGET/AGENTS.md"
    echo "✅ AGENTS.md installed."
fi

# 2. Install files into .agent directory
AGENT_FILES=("INVARIANTS.md" "TASK.md" "NOTES.md" "ARCHIVE.md")

for file in "${AGENT_FILES[@]}"; do
    dest="$RESOLVED_TARGET/.agent/$file"
    if [ -f "$dest" ]; then
        if [ "$FORCE_YES" = true ]; then
            fetch_file ".agent/$file" "$dest"
            echo "✅ .agent/$file updated (--force)."
        else
            echo "ℹ️  $file already exists in .agent/. Retaining existing file."
        fi
    else
        fetch_file ".agent/$file" "$dest"
        echo "✅ .agent/$file installed."
    fi
done

echo ""
echo "======================================================="
echo "🎉 Installation completed successfully!"
echo ""
echo "👉 Next steps with your AI agent:"
echo "1. Open your project in your AI coding environment."
echo "2. Send the following kickoff prompt:"
echo ""
echo "   \"Read AGENTS.md and Task [00.1] in .agent/TASK.md. Present your implementation plan"
echo "    for Project Discovery and Audit before modifying any code.\""
echo "======================================================="
